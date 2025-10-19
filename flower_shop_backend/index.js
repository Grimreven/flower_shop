import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import jwt from "jsonwebtoken";
import pkg from "pg";
import dotenv from "dotenv";
import bcrypt from "bcryptjs";

dotenv.config();
const { Pool } = pkg;

const app = express();
app.use(cors());
app.use(bodyParser.json());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgres://postgres:111@localhost:5432/flower_shop",
});

pool.connect()
  .then(() => console.log("✅ Подключено к PostgreSQL"))
  .catch((err) => console.error("❌ Ошибка подключения:", err));

// Middleware для проверки токена
function authenticateToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer "))
    return res.status(401).json({ message: "Нет токена" });

  const token = authHeader.split(" ")[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "mysecret");
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ message: "Недействительный токен" });
  }
}

// ------------------- Регистрация -------------------
app.post("/register", async (req, res) => {
  const { name, email, password } = req.body;

  try {
    // Хэшируем пароль
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Создаём пользователя
    const result = await pool.query(
      `INSERT INTO customers (name, email, password_hash)
       VALUES ($1, $2, $3) RETURNING id, name, email`,
      [name, email, hashedPassword]
    );

    const user = result.rows[0];

    // Создаём базовую карту лояльности (Bronze)
    await pool.query(
      `INSERT INTO loyalty_accounts (user_id, points, level, total_spent)
       VALUES ($1, $2, $3, $4)`,
      [user.id, 0, 'Bronze', 0]
    );

    // Генерируем JWT
    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET || "mysecret",
      { expiresIn: "7d" }
    );

    res.json({ user, token });

  } catch (err) {
    console.error("Ошибка POST /register:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

// ------------------- Логин -------------------
app.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ message: "Не все поля заполнены" });

    const result = await pool.query(
      "SELECT id, name, email, password_hash FROM customers WHERE email=$1",
      [email]
    );

    if (result.rows.length === 0) return res.status(400).json({ message: "Пользователь не найден" });

    const user = result.rows[0];

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) return res.status(400).json({ message: "Неверный пароль" });

    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET || "mysecret",
      { expiresIn: "7d" }
    );

    res.json({ user: { id: user.id, name: user.name, email: user.email }, token });
  } catch (err) {
    console.error("Ошибка POST /login:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

// ------------------- Получение профиля -------------------
app.get("/profile", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT
         c.id,
         c.name,
         c.email,
         c.phone,
         c.address,
         COALESCE(l.points, 0) AS loyalty_points,
         COALESCE(l.total_spent, 0) AS total_spent,
         COALESCE(l.level, 'Bronze') AS loyalty_level,
         COALESCE(levels.color_hex, '#CD7F32') AS loyalty_color
       FROM customers c
       LEFT JOIN loyalty_accounts l ON l.user_id = c.id
       LEFT JOIN loyalty_levels levels ON levels.name = l.level
       WHERE c.id = $1`,
      [userId]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ message: "Пользователь не найден" });

    res.json(result.rows[0]);
  } catch (err) {
    console.error("Ошибка GET /profile:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});



// ------------------- Обновление профиля -------------------
app.put("/profile", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, email, phone, address } = req.body;

    const result = await pool.query(
      `UPDATE customers
       SET name=$1, email=$2, phone=$3, address=$4
       WHERE id=$5
       RETURNING id, name, email, phone, address`,
      [name, email, phone, address, userId]
    );

    if (result.rows.length === 0) return res.status(404).json({ message: "Пользователь не найден" });

    res.json(result.rows[0]);
  } catch (err) {
    console.error("Ошибка PUT /profile:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

// ------------------- Logout -------------------
app.post("/logout", authenticateToken, async (req, res) => {
  res.json({ message: "Выход выполнен успешно" });
});

// 🔹 Получить все товары
app.get("/products", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT p.*, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON c.id = p.category_id
      ORDER BY p.id DESC;
    `);
    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /products:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

// 🔹 Получить популярные товары
app.get("/products/popular", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT p.*, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON c.id = p.category_id
      ORDER BY p.rating DESC NULLS LAST, p.id DESC
      LIMIT 6;
    `);
    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /products/popular:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

app.get("/products/:id/reviews", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT r.*, c.name AS user_name
      FROM reviews r
      LEFT JOIN customers c ON c.id = r.user_id
      WHERE r.product_id = $1
      ORDER BY r.created_at DESC
    `, [req.params.id]);
    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /products/:id/reviews:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

// ------------------- Корзина -------------------

// 🔹 Получить корзину пользователя
app.get("/cart", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    // Находим корзину пользователя (или создаём, если нет)
    const cartResult = await pool.query(
      "SELECT id FROM carts WHERE user_id = $1",
      [userId]
    );
    let cartId;
    if (cartResult.rows.length === 0) {
      const newCart = await pool.query(
        "INSERT INTO carts (user_id) VALUES ($1) RETURNING id",
        [userId]
      );
      cartId = newCart.rows[0].id;
    } else {
      cartId = cartResult.rows[0].id;
    }

    // Получаем содержимое корзины
   const items = await pool.query(
     `SELECT ci.id, ci.product_id, ci.quantity,
             p.name, p.price, p.image_url, p.description, p.category_id,
             c.name AS category_name, p.rating, p.in_stock
      FROM cart_items ci
      JOIN products p ON p.id = ci.product_id
      LEFT JOIN categories c ON c.id = p.category_id
      WHERE ci.cart_id = $1
      ORDER BY ci.id DESC`,
     [cartId]
   );


    res.json(items.rows);
  } catch (err) {
    console.error("Ошибка GET /cart:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});


// 🔹 Добавить товар в корзину
app.post("/cart", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { product_id, quantity } = req.body;

    // Проверяем / создаём корзину
    let cart = await pool.query("SELECT id FROM carts WHERE user_id=$1", [userId]);
    if (cart.rows.length === 0) {
      const newCart = await pool.query(
        "INSERT INTO carts (user_id) VALUES ($1) RETURNING id",
        [userId]
      );
      cart = newCart;
    }
    const cartId = cart.rows[0].id;

    // Проверяем, есть ли уже этот товар
    const existing = await pool.query(
      "SELECT id, quantity FROM cart_items WHERE cart_id=$1 AND product_id=$2",
      [cartId, product_id]
    );

    if (existing.rows.length > 0) {
      // обновляем количество
      const newQuantity = existing.rows[0].quantity + quantity;
      await pool.query(
        "UPDATE cart_items SET quantity=$1 WHERE id=$2",
        [newQuantity, existing.rows[0].id]
      );
    } else {
      await pool.query(
        "INSERT INTO cart_items (cart_id, product_id, quantity) VALUES ($1, $2, $3)",
        [cartId, product_id, quantity]
      );
    }

    res.json({ message: "Товар добавлен в корзину" });
  } catch (err) {
    console.error("Ошибка POST /cart:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});


// 🔹 Изменить количество товара
app.put("/cart/:product_id", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { quantity } = req.body;
    const { product_id } = req.params;

    const cart = await pool.query("SELECT id FROM carts WHERE user_id=$1", [userId]);
    if (cart.rows.length === 0) return res.status(404).json({ message: "Корзина не найдена" });

    const cartId = cart.rows[0].id;

    await pool.query(
      "UPDATE cart_items SET quantity=$1 WHERE cart_id=$2 AND product_id=$3",
      [quantity, cartId, product_id]
    );

    res.json({ message: "Количество обновлено" });
  } catch (err) {
    console.error("Ошибка PUT /cart:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});


// 🔹 Удалить товар из корзины
app.delete("/cart/:product_id", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { product_id } = req.params;

    const cart = await pool.query("SELECT id FROM carts WHERE user_id=$1", [userId]);
    if (cart.rows.length === 0) return res.status(404).json({ message: "Корзина не найдена" });

    const cartId = cart.rows[0].id;

    await pool.query("DELETE FROM cart_items WHERE cart_id=$1 AND product_id=$2", [cartId, product_id]);

    res.json({ message: "Товар удалён из корзины" });
  } catch (err) {
    console.error("Ошибка DELETE /cart:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});


// 🔹 Очистить корзину
app.delete("/cart", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const cart = await pool.query("SELECT id FROM carts WHERE user_id=$1", [userId]);
    if (cart.rows.length === 0) return res.status(404).json({ message: "Корзина не найдена" });

    const cartId = cart.rows[0].id;

    await pool.query("DELETE FROM cart_items WHERE cart_id=$1", [cartId]);
    res.json({ message: "Корзина очищена" });
  } catch (err) {
    console.error("Ошибка очистки корзины:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

/// ------------------- Создание заказа -------------------
 app.post('/orders', authenticateToken, async (req, res) => {
   const userId = req.user.id;
   const { items } = req.body;

   if (!items || !Array.isArray(items) || items.length === 0) {
     return res.status(400).json({ message: 'Нет товаров для заказа' });
   }

   try {
     await pool.query('BEGIN');

     // Вычисляем total заказа
     let total = 0;
     for (const item of items) {
       const productRes = await pool.query(
         'SELECT price FROM products WHERE id=$1',
         [item.product_id]
       );
       if (productRes.rows.length === 0) throw new Error(`Продукт ${item.product_id} не найден`);
       total += productRes.rows[0].price * item.quantity;
     }

     // Создаем заказ
     const orderRes = await pool.query(
       'INSERT INTO orders (user_id, total, status) VALUES ($1, $2, $3) RETURNING *',
       [userId, total, 'Заказ собирается']
     );
     const orderId = orderRes.rows[0].id;

     // Добавляем позиции заказа
     for (const item of items) {
       await pool.query(
         'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES ($1, $2, $3, (SELECT price FROM products WHERE id=$2))',
         [orderId, item.product_id, item.quantity]
       );
     }

    await pool.query('COMMIT');

    const newOrder = await pool.query(
      `SELECT o.*, (
         SELECT json_agg(json_build_object(
           'product_id', oi.product_id,
           'quantity', oi.quantity,
           'price', oi.price
         )) FROM order_items oi WHERE oi.order_id = o.id
       ) AS items
       FROM orders o
       WHERE o.id = $1`,
      [orderId]
    );

    res.json(newOrder.rows[0]);
   } catch (err) {
     await pool.query('ROLLBACK');
     console.error("❌ Ошибка при создании заказа:", err.message);
     console.error("📜 Полная ошибка:", err.stack);
     res.status(500).json({
       message: 'Ошибка при создании заказа',
       error: err.message,
       stack: err.stack
     });
   }
 });

 // ------------------- Получение заказов пользователя -------------------
 app.get('/orders', authenticateToken, async (req, res) => {
   const userId = req.user.id;
   try {
     const ordersRes = await pool.query(
       'SELECT * FROM orders WHERE user_id=$1 ORDER BY created_at DESC',
       [userId]
     );

     const orders = [];
     for (const order of ordersRes.rows) {
       const itemsRes = await pool.query(
         `SELECT oi.*, p.name, p.image_url
          FROM order_items oi
          JOIN products p ON p.id = oi.product_id
          WHERE oi.order_id=$1`,
         [order.id]
       );
       orders.push({
         ...order,
         items: itemsRes.rows
       });
     }

     res.json(orders);
   } catch (err) {
     console.error(err);
     res.status(500).json({ message: 'Ошибка при получении заказов' });
   }
 });



// ------------------- Запуск сервера -------------------
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Сервер запущен на http://localhost:${PORT}`));
