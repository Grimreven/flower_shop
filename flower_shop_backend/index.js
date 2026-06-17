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
  connectionString:
    process.env.DATABASE_URL || "postgres://postgres:111@127.0.0.1:5432/flower_shop",
});

pool
  .connect()
  .then(() => console.log("Подключено к PostgreSQL"))
  .catch((err) => console.error("Ошибка подключения к PostgreSQL:", err));

function authenticateToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Нет токена" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "mysecret");
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ message: "Недействительный токен" });
  }
}

async function requireAdmin(req, res, next) {
  try {
    const result = await pool.query(
      `
      SELECT r.name AS role_name
      FROM customers c
      LEFT JOIN roles r ON r.id = c.role_id
      WHERE c.id = $1
      LIMIT 1
      `,
      [req.user.id]
    );

    if (result.rows[0]?.role_name !== "admin") {
      return res.status(403).json({ message: "Только для администратора" });
    }

    next();
  } catch (err) {
    console.error("Ошибка проверки админа:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
}

function toNumber(value, fallback = 0) {
  const result = Number(value);
  return Number.isFinite(result) ? result : fallback;
}

function normalizeCare(care) {
  if (care === undefined) return undefined;
  if (care === null) return null;

  if (typeof care === "string") {
    try {
      return JSON.stringify(JSON.parse(care));
    } catch (_) {
      return JSON.stringify([care]);
    }
  }

  return JSON.stringify(care);
}

app.get("/", (req, res) => {
  res.json({
    status: "ok",
    message: "Flower Shop API is running",
  });
});

app.get("/health", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");
    res.json({
      status: "ok",
      database: "connected",
      time: result.rows[0].now,
    });
  } catch (err) {
    res.status(500).json({
      status: "error",
      database: "not connected",
      message: err.message,
    });
  }
});

app.post("/register", async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ message: "Не все поля заполнены" });
  }

  try {
    const exists = await pool.query(
      "SELECT id FROM customers WHERE email = $1",
      [email]
    );

    if (exists.rows.length > 0) {
      return res.status(400).json({ message: "Пользователь уже существует" });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const roleResult = await pool.query(
      "SELECT id FROM roles WHERE name = $1 LIMIT 1",
      ["customer"]
    );

    const roleId = roleResult.rows.length > 0 ? roleResult.rows[0].id : null;

    const levelResult = await pool.query(
      "SELECT id FROM loyalty_levels WHERE name = $1 LIMIT 1",
      ["Bronze"]
    );

    const levelId = levelResult.rows.length > 0 ? levelResult.rows[0].id : null;

    const result = await pool.query(
      `
      INSERT INTO customers (name, email, password_hash, role_id)
      VALUES ($1, $2, $3, $4)
      RETURNING id, name, email, phone
      `,
      [name, email, hashedPassword, roleId]
    );

    const user = result.rows[0];

    await pool.query(
      `
      INSERT INTO loyalty_accounts (user_id, points, total_spent, level_id)
      VALUES ($1, $2, $3, $4)
      `,
      [user.id, 0, 0, levelId]
    );

    const token = jwt.sign(
      { id: user.id, email: user.email, role: "customer" },
      process.env.JWT_SECRET || "mysecret",
      { expiresIn: "7d" }
    );

    res.json({ user, token });
  } catch (err) {
    console.error("Ошибка POST /register:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: "Не все поля заполнены" });
  }

  try {
    const result = await pool.query(
      `
      SELECT c.*, r.name AS role_name
      FROM customers c
      LEFT JOIN roles r ON r.id = c.role_id
      WHERE c.email = $1
      `,
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ message: "Пользователь не найден" });
    }

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
      return res.status(400).json({ message: "Неверный пароль" });
    }

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role_name,
      },
      process.env.JWT_SECRET || "mysecret",
      { expiresIn: "7d" }
    );

    res.json({
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role_name,
      },
      token,
    });
  } catch (err) {
    console.error("Ошибка POST /login:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

app.post("/logout", authenticateToken, async (req, res) => {
  res.json({ message: "Выход выполнен успешно" });
});

app.get("/profile", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const result = await pool.query(
      `
      SELECT c.id,
             c.name,
             c.email,
             c.phone,
             r.name AS role,
             COALESCE(l.points, 0) AS loyalty_points,
             COALESCE(l.total_spent, 0) AS total_spent,
             COALESCE(levels.name, 'Bronze') AS loyalty_level,
             COALESCE(levels.color_hex, '#CD7F32') AS loyalty_color
      FROM customers c
      LEFT JOIN roles r ON r.id = c.role_id
      LEFT JOIN loyalty_accounts l ON l.user_id = c.id
      LEFT JOIN loyalty_levels levels ON levels.id = l.level_id
      WHERE c.id = $1
      `,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Пользователь не найден" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error("Ошибка GET /profile:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.put("/profile", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { name, email, phone } = req.body;

  try {
    const result = await pool.query(
      `
      UPDATE customers
      SET name = $1, email = $2, phone = $3
      WHERE id = $4
      RETURNING id, name, email, phone
      `,
      [name, email, phone, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Пользователь не найден" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error("Ошибка PUT /profile:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/products", async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT p.*, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON c.id = p.category_id
      ORDER BY p.id DESC
      `
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /products:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/categories", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name FROM categories ORDER BY id"
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /categories:", err);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

app.get("/products/popular", async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT p.*, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON c.id = p.category_id
      ORDER BY p.rating DESC NULLS LAST, p.id DESC
      LIMIT 6
      `
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /products/popular:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/products/:id/reviews", async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT r.*, c.name AS user_name
      FROM reviews r
      LEFT JOIN customers c ON c.id = r.user_id
      WHERE r.product_id = $1
      ORDER BY r.created_at DESC
      `,
      [req.params.id]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /products/:id/reviews:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/products/:id/price-history", async (req, res) => {
  const productId = Number(req.params.id);

  try {
    const result = await pool.query(
      `
      SELECT
        old_price,
        new_price,
        new_price AS price,
        changed_at
      FROM product_price_history
      WHERE product_id = $1
      ORDER BY changed_at ASC
      `,
      [productId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /products/:id/price-history:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.post("/products", authenticateToken, requireAdmin, async (req, res) => {
  const {
    name,
    description,
    price,
    image_url,
    category_id,
    in_stock,
    care,
  } = req.body;

  if (!name || price === undefined || price === null) {
    return res.status(400).json({ message: "Заполните название и цену" });
  }

  const newPrice = Number(price);

  if (!Number.isFinite(newPrice) || newPrice <= 0) {
    return res.status(400).json({ message: "Цена должна быть положительным числом" });
  }

  try {
    const normalizedCare = normalizeCare(care);

    const result = await pool.query(
      `
      INSERT INTO products
      (
        name,
        description,
        price,
        image_url,
        category_id,
        in_stock,
        rating,
        review_count,
        care
      )
      VALUES ($1, $2, $3, $4, $5, $6, 0, 0, $7)
      RETURNING *
      `,
      [
        name,
        description || "",
        newPrice,
        image_url || "",
        category_id || null,
        in_stock ?? true,
        normalizedCare === undefined ? null : normalizedCare,
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error("Ошибка POST /products:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.put("/products/:id", authenticateToken, requireAdmin, async (req, res) => {
  const productId = Number(req.params.id);
  const {
    name,
    description,
    price,
    image_url,
    category_id,
    in_stock,
    care,
  } = req.body;

  try {
    await pool.query("BEGIN");

    const productResult = await pool.query(
      "SELECT * FROM products WHERE id = $1",
      [productId]
    );

    if (productResult.rows.length === 0) {
      await pool.query("ROLLBACK");
      return res.status(404).json({ message: "Товар не найден" });
    }

    const product = productResult.rows[0];

    const oldPrice = Number(product.price);
    const newPrice =
      price === undefined || price === null ? oldPrice : Number(price);

    if (!Number.isFinite(newPrice) || newPrice <= 0) {
      await pool.query("ROLLBACK");
      return res.status(400).json({ message: "Цена должна быть положительным числом" });
    }

    if (newPrice !== oldPrice) {
      await pool.query(
        `
        INSERT INTO product_price_history
        (
          product_id,
          old_price,
          new_price,
          changed_at,
          changed_by
        )
        VALUES ($1, $2, $3, NOW(), $4)
        `,
        [productId, oldPrice, newPrice, req.user.id]
      );
    }

    const normalizedCare = normalizeCare(care);

    const updated = await pool.query(
      `
      UPDATE products
      SET name = $1,
          description = $2,
          price = $3,
          image_url = $4,
          category_id = $5,
          in_stock = $6,
          care = $7
      WHERE id = $8
      RETURNING *
      `,
      [
        name ?? product.name,
        description ?? product.description,
        newPrice,
        image_url ?? product.image_url,
        category_id ?? product.category_id,
        in_stock ?? product.in_stock,
        normalizedCare === undefined ? product.care : normalizedCare,
        productId,
      ]
    );

    await pool.query("COMMIT");

    res.json(updated.rows[0]);
  } catch (err) {
    await pool.query("ROLLBACK");
    console.error("Ошибка PUT /products/:id:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.delete("/products/:id", authenticateToken, requireAdmin, async (req, res) => {
  const productId = Number(req.params.id);

  try {
    const result = await pool.query(
      `
      UPDATE products
      SET in_stock = false
      WHERE id = $1
      RETURNING *
      `,
      [productId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Товар не найден" });
    }

    res.json({ message: "Товар скрыт из каталога", product: result.rows[0] });
  } catch (err) {
    console.error("Ошибка DELETE /products/:id:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/cart", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
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

    const items = await pool.query(
      `
      SELECT ci.id,
             ci.product_id,
             ci.quantity,
             p.name,
             p.price,
             p.image_url,
             p.description,
             p.category_id,
             c.name AS category_name,
             p.rating,
             p.in_stock,
             p.review_count,
             p.care
      FROM cart_items ci
      JOIN products p ON p.id = ci.product_id
      LEFT JOIN categories c ON c.id = p.category_id
      WHERE ci.cart_id = $1
      ORDER BY ci.id DESC
      `,
      [cartId]
    );

    res.json(items.rows);
  } catch (err) {
    console.error("Ошибка GET /cart:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.post("/cart", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { product_id, quantity } = req.body;

  if (!product_id || !quantity) {
    return res.status(400).json({ message: "Не указан товар или количество" });
  }

  try {
    let cart = await pool.query("SELECT id FROM carts WHERE user_id = $1", [
      userId,
    ]);

    if (cart.rows.length === 0) {
      cart = await pool.query(
        "INSERT INTO carts (user_id) VALUES ($1) RETURNING id",
        [userId]
      );
    }

    const cartId = cart.rows[0].id;

    const existing = await pool.query(
      "SELECT id, quantity FROM cart_items WHERE cart_id = $1 AND product_id = $2",
      [cartId, product_id]
    );

    if (existing.rows.length > 0) {
      const newQuantity = Number(existing.rows[0].quantity) + Number(quantity);

      await pool.query("UPDATE cart_items SET quantity = $1 WHERE id = $2", [
        newQuantity,
        existing.rows[0].id,
      ]);
    } else {
      await pool.query(
        "INSERT INTO cart_items (cart_id, product_id, quantity) VALUES ($1, $2, $3)",
        [cartId, product_id, quantity]
      );
    }

    res.json({ message: "Товар добавлен в корзину" });
  } catch (err) {
    console.error("Ошибка POST /cart:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.put("/cart/:product_id", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { quantity } = req.body;
  const { product_id } = req.params;

  try {
    const cart = await pool.query("SELECT id FROM carts WHERE user_id = $1", [
      userId,
    ]);

    if (cart.rows.length === 0) {
      return res.status(404).json({ message: "Корзина не найдена" });
    }

    await pool.query(
      "UPDATE cart_items SET quantity = $1 WHERE cart_id = $2 AND product_id = $3",
      [quantity, cart.rows[0].id, product_id]
    );

    res.json({ message: "Количество обновлено" });
  } catch (err) {
    console.error("Ошибка PUT /cart:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.delete("/cart/:product_id", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { product_id } = req.params;

  try {
    const cart = await pool.query("SELECT id FROM carts WHERE user_id = $1", [
      userId,
    ]);

    if (cart.rows.length === 0) {
      return res.status(404).json({ message: "Корзина не найдена" });
    }

    await pool.query(
      "DELETE FROM cart_items WHERE cart_id = $1 AND product_id = $2",
      [cart.rows[0].id, product_id]
    );

    res.json({ message: "Товар удалён из корзины" });
  } catch (err) {
    console.error("Ошибка DELETE /cart/:product_id:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.delete("/cart", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const cart = await pool.query("SELECT id FROM carts WHERE user_id = $1", [
      userId,
    ]);

    if (cart.rows.length === 0) {
      return res.status(404).json({ message: "Корзина не найдена" });
    }

    await pool.query("DELETE FROM cart_items WHERE cart_id = $1", [
      cart.rows[0].id,
    ]);

    res.json({ message: "Корзина очищена" });
  } catch (err) {
    console.error("Ошибка DELETE /cart:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/favorites", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const result = await pool.query(
      "SELECT product_id FROM favorites WHERE user_id = $1 ORDER BY created_at DESC",
      [userId]
    );

    res.json(result.rows.map((row) => row.product_id));
  } catch (err) {
    console.error("Ошибка GET /favorites:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.post("/favorites/:product_id", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const productId = Number(req.params.product_id);

  try {
    await pool.query(
      `
      INSERT INTO favorites (user_id, product_id)
      VALUES ($1, $2)
      ON CONFLICT (user_id, product_id) DO NOTHING
      `,
      [userId, productId]
    );

    res.json({ message: "Товар добавлен в избранное" });
  } catch (err) {
    console.error("Ошибка POST /favorites/:product_id:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.delete("/favorites/:product_id", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const productId = Number(req.params.product_id);

  try {
    await pool.query(
      "DELETE FROM favorites WHERE user_id = $1 AND product_id = $2",
      [userId, productId]
    );

    res.json({ message: "Товар удалён из избранного" });
  } catch (err) {
    console.error("Ошибка DELETE /favorites/:product_id:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.delete("/favorites", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    await pool.query("DELETE FROM favorites WHERE user_id = $1", [userId]);

    res.json({ message: "Избранное очищено" });
  } catch (err) {
    console.error("Ошибка DELETE /favorites:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/addresses", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const result = await pool.query(
      `
      SELECT id,
             user_id,
             title,
             recipient_name,
             phone,
             city,
             street,
             house,
             apartment,
             entrance,
             floor,
             comment,
             is_default,
             created_at,
             updated_at
      FROM customer_addresses
      WHERE user_id = $1
      ORDER BY is_default DESC, id DESC
      `,
      [userId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /addresses:", err);
    res.status(500).json({ message: "Ошибка загрузки адресов", error: err.message });
  }
});

app.post("/addresses", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const {
    title,
    recipient_name,
    phone,
    city,
    street,
    house,
    apartment,
    entrance,
    floor,
    comment,
    is_default,
  } = req.body;

  if (!city || !street || !house) {
    return res.status(400).json({ message: "Укажите город, улицу и дом" });
  }

  try {
    await pool.query("BEGIN");

    const countResult = await pool.query(
      "SELECT COUNT(*)::int AS count FROM customer_addresses WHERE user_id = $1",
      [userId]
    );

    const shouldBeDefault = Boolean(is_default) || countResult.rows[0].count === 0;

    if (shouldBeDefault) {
      await pool.query(
        "UPDATE customer_addresses SET is_default = false, updated_at = now() WHERE user_id = $1",
        [userId]
      );
    }

    const result = await pool.query(
      `
      INSERT INTO customer_addresses
      (
        user_id,
        title,
        recipient_name,
        phone,
        city,
        street,
        house,
        apartment,
        entrance,
        floor,
        comment,
        is_default
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
      RETURNING id, user_id, title, recipient_name, phone, city, street, house,
                apartment, entrance, floor, comment, is_default, created_at, updated_at
      `,
      [
        userId,
        title || "Адрес",
        recipient_name || null,
        phone || null,
        city,
        street,
        house,
        apartment || null,
        entrance || null,
        floor || null,
        comment || null,
        shouldBeDefault,
      ]
    );

    await pool.query("COMMIT");
    res.json(result.rows[0]);
  } catch (err) {
    await pool.query("ROLLBACK");
    console.error("Ошибка POST /addresses:", err);
    res.status(500).json({ message: "Ошибка создания адреса", error: err.message });
  }
});

app.put("/addresses/:id", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const addressId = Number(req.params.id);
  const {
    title,
    recipient_name,
    phone,
    city,
    street,
    house,
    apartment,
    entrance,
    floor,
    comment,
    is_default,
  } = req.body;

  if (!city || !street || !house) {
    return res.status(400).json({ message: "Укажите город, улицу и дом" });
  }

  try {
    await pool.query("BEGIN");

    if (Boolean(is_default)) {
      await pool.query(
        "UPDATE customer_addresses SET is_default = false, updated_at = now() WHERE user_id = $1",
        [userId]
      );
    }

    const result = await pool.query(
      `
      UPDATE customer_addresses
      SET title = $1,
          recipient_name = $2,
          phone = $3,
          city = $4,
          street = $5,
          house = $6,
          apartment = $7,
          entrance = $8,
          floor = $9,
          comment = $10,
          is_default = $11,
          updated_at = now()
      WHERE id = $12 AND user_id = $13
      RETURNING id, user_id, title, recipient_name, phone, city, street, house,
                apartment, entrance, floor, comment, is_default, created_at, updated_at
      `,
      [
        title || "Адрес",
        recipient_name || null,
        phone || null,
        city,
        street,
        house,
        apartment || null,
        entrance || null,
        floor || null,
        comment || null,
        Boolean(is_default),
        addressId,
        userId,
      ]
    );

    if (result.rows.length === 0) {
      await pool.query("ROLLBACK");
      return res.status(404).json({ message: "Адрес не найден" });
    }

    await pool.query("COMMIT");
    res.json(result.rows[0]);
  } catch (err) {
    await pool.query("ROLLBACK");
    console.error("Ошибка PUT /addresses/:id:", err);
    res.status(500).json({ message: "Ошибка обновления адреса", error: err.message });
  }
});

app.delete("/addresses/:id", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const addressId = Number(req.params.id);

  try {
    await pool.query("BEGIN");

    const deleted = await pool.query(
      "DELETE FROM customer_addresses WHERE id = $1 AND user_id = $2 RETURNING is_default",
      [addressId, userId]
    );

    if (deleted.rows.length === 0) {
      await pool.query("ROLLBACK");
      return res.status(404).json({ message: "Адрес не найден" });
    }

    if (deleted.rows[0].is_default) {
      const next = await pool.query(
        "SELECT id FROM customer_addresses WHERE user_id = $1 ORDER BY id DESC LIMIT 1",
        [userId]
      );

      if (next.rows.length > 0) {
        await pool.query(
          "UPDATE customer_addresses SET is_default = true, updated_at = now() WHERE id = $1",
          [next.rows[0].id]
        );
      }
    }

    await pool.query("COMMIT");
    res.json({ message: "Адрес удалён" });
  } catch (err) {
    await pool.query("ROLLBACK");
    console.error("Ошибка DELETE /addresses/:id:", err);
    res.status(500).json({ message: "Ошибка удаления адреса", error: err.message });
  }
});

app.post("/orders", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const { items, checkout } = req.body;

  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ message: "Нет товаров для заказа" });
  }

  function resolveLevelName(totalSpent) {
    if (totalSpent >= 15000) return "Gold";
    if (totalSpent >= 5000) return "Silver";
    return "Bronze";
  }

  try {
    await pool.query("BEGIN");

    let itemsTotal = 0;

    for (const item of items) {
      const productRes = await pool.query(
        "SELECT price FROM products WHERE id = $1",
        [item.product_id]
      );

      if (productRes.rows.length === 0) {
        throw new Error(`Продукт ${item.product_id} не найден`);
      }

      itemsTotal += Number(productRes.rows[0].price) * Number(item.quantity);
    }

    const checkoutData = checkout || {};

    const deliveryPrice = Number(
      checkoutData.delivery_price || checkoutData.deliveryPrice || 0
    );

    const requestedBonuses = Number(
      checkoutData.applied_bonuses ||
        checkoutData.appliedBonuses ||
        checkoutData.bonus_applied ||
        checkoutData.bonusApplied ||
        0
    );

    let loyaltyAccountResult = await pool.query(
      `
      SELECT id, points, total_spent, level_id
      FROM loyalty_accounts
      WHERE user_id = $1
      FOR UPDATE
      `,
      [userId]
    );

    let loyaltyAccount = loyaltyAccountResult.rows[0];

    if (!loyaltyAccount) {
      const bronzeLevelResult = await pool.query(
        "SELECT id FROM loyalty_levels WHERE name = $1 LIMIT 1",
        ["Bronze"]
      );

      if (bronzeLevelResult.rows.length === 0) {
        throw new Error("Уровень Bronze не найден в loyalty_levels");
      }

      const createdAccountResult = await pool.query(
        `
        INSERT INTO loyalty_accounts (user_id, points, total_spent, level_id)
        VALUES ($1, 0, 0, $2)
        RETURNING id, points, total_spent, level_id
        `,
        [userId, bronzeLevelResult.rows[0].id]
      );

      loyaltyAccount = createdAccountResult.rows[0];
    }

    const levelResult = await pool.query(
      `
      SELECT name, multiplier
      FROM loyalty_levels
      WHERE id = $1
      LIMIT 1
      `,
      [loyaltyAccount.level_id]
    );

    const currentLevel = levelResult.rows[0] || {
      name: "Bronze",
      multiplier: 0.05,
    };

    const currentPoints = Number(loyaltyAccount.points || 0);
    const maxBonusByPercent = Math.floor(itemsTotal * 0.3);

    const bonusApplied = Math.max(
      0,
      Math.min(
        requestedBonuses,
        currentPoints,
        maxBonusByPercent,
        Math.floor(itemsTotal)
      )
    );

    const paidForProducts = Math.max(0, itemsTotal - bonusApplied);
    const currentMultiplier = Number(currentLevel.multiplier || 0.05);
    const bonusEarned = Math.floor(paidForProducts * currentMultiplier);
    const total = paidForProducts + deliveryPrice;

    const newTotalSpent = Number(loyaltyAccount.total_spent || 0) + paidForProducts;
    const newLevelName = resolveLevelName(newTotalSpent);

    const newLevelResult = await pool.query(
      "SELECT id FROM loyalty_levels WHERE name = $1 LIMIT 1",
      [newLevelName]
    );

    const newLevelId =
      newLevelResult.rows.length > 0
        ? newLevelResult.rows[0].id
        : loyaltyAccount.level_id;

    const orderRes = await pool.query(
      `
      INSERT INTO orders (
        user_id,
        total,
        status,
        items_total,
        delivery_cost,
        bonus_applied,
        bonus_earned
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
      `,
      [
        userId,
        total,
        "Новый",
        itemsTotal,
        deliveryPrice,
        bonusApplied,
        bonusEarned,
      ]
    );

    const orderId = orderRes.rows[0].id;

    for (const item of items) {
      await pool.query(
        `
        INSERT INTO order_items (order_id, product_id, quantity, price)
        VALUES ($1, $2, $3, (SELECT price FROM products WHERE id = $2))
        `,
        [orderId, item.product_id, item.quantity]
      );
    }

    if (bonusApplied > 0) {
      await pool.query(
        `
        INSERT INTO loyalty_transactions (
          loyalty_account_id,
          type,
          points,
          description
        )
        VALUES ($1, $2, $3, $4)
        `,
        [
          loyaltyAccount.id,
          "spend",
          -bonusApplied,
          `Списание бонусов за заказ №${orderId}`,
        ]
      );
    }

    if (bonusEarned > 0) {
      await pool.query(
        `
        INSERT INTO loyalty_transactions (
          loyalty_account_id,
          type,
          points,
          description
        )
        VALUES ($1, $2, $3, $4)
        `,
        [
          loyaltyAccount.id,
          "earn",
          bonusEarned,
          `Начисление бонусов за заказ №${orderId}`,
        ]
      );
    }

    await pool.query(
      `
      UPDATE loyalty_accounts
      SET points = points - $1 + $2,
          total_spent = $3,
          level_id = $4,
          updated_at = NOW()
      WHERE id = $5
      `,
      [bonusApplied, bonusEarned, newTotalSpent, newLevelId, loyaltyAccount.id]
    );

    const fullAddress =
      checkoutData.full_address ||
      checkoutData.fullAddress ||
      checkoutData.address ||
      "Адрес не указан";

    const recipientName =
      checkoutData.recipient_name ||
      checkoutData.recipientName ||
      checkoutData.name ||
      null;

    const phone = checkoutData.phone || null;

    const deliveryMethod =
      checkoutData.delivery_method ||
      checkoutData.deliveryMethod ||
      checkoutData.delivery ||
      null;

    const paymentMethod =
      checkoutData.payment_method ||
      checkoutData.paymentMethod ||
      checkoutData.payment ||
      "cash";

    const paymentStatus = paymentMethod === "cash" ? "pending" : "paid";
    const transactionStatus = paymentMethod === "cash" ? "pending" : "paid";

    await pool.query(
      `
      INSERT INTO order_delivery_details (
        order_id,
        address_id,
        recipient_name,
        phone,
        full_address,
        delivery_method,
        delivery_date,
        delivery_time_from,
        delivery_time_to,
        comment,
        delivery_price
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      `,
      [
        orderId,
        checkoutData.address_id || checkoutData.addressId || null,
        recipientName,
        phone,
        fullAddress,
        deliveryMethod,
        checkoutData.delivery_date || checkoutData.deliveryDate || null,
        checkoutData.delivery_time_from || checkoutData.deliveryTimeFrom || null,
        checkoutData.delivery_time_to || checkoutData.deliveryTimeTo || null,
        checkoutData.comment ||
          checkoutData.recipient_comment ||
          checkoutData.recipientComment ||
          null,
        deliveryPrice,
      ]
    );

    await pool.query(
      `
      INSERT INTO order_payment_details (
        order_id,
        payment_method,
        payment_status,
        payment_amount
      )
      VALUES ($1, $2, $3, $4)
      `,
      [orderId, paymentMethod, paymentStatus, total]
    );

    await pool.query(
      `
      INSERT INTO payment_transactions (
        order_id,
        user_id,
        payment_type,
        amount,
        status,
        provider,
        paid_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      `,
      [
        orderId,
        userId,
        paymentMethod,
        total,
        transactionStatus,
        "demo",
        transactionStatus === "paid" ? new Date() : null,
      ]
    );

    await pool.query(
      "INSERT INTO order_history (order_id, status) VALUES ($1, $2)",
      [orderId, "Новый"]
    );

    const cartResult = await pool.query(
      "SELECT id FROM carts WHERE user_id = $1",
      [userId]
    );

    if (cartResult.rows.length > 0) {
      await pool.query("DELETE FROM cart_items WHERE cart_id = $1", [
        cartResult.rows[0].id,
      ]);
    }

    await pool.query("COMMIT");

    const newOrder = await pool.query(
      `
      SELECT o.*,
             odd.delivery_price AS delivery_cost,
             opd.payment_method,
             opd.payment_status,
             odd.full_address AS delivery_address,
             (
               SELECT json_agg(
                 json_build_object(
                   'product_id', oi.product_id,
                   'quantity', oi.quantity,
                   'price', oi.price,
                   'name', p.name,
                   'image_url', p.image_url
                 )
               )
               FROM order_items oi
               LEFT JOIN products p ON p.id = oi.product_id
               WHERE oi.order_id = o.id
             ) AS items,
             (
               SELECT row_to_json(d)
               FROM order_delivery_details d
               WHERE d.order_id = o.id
               LIMIT 1
             ) AS delivery,
             (
               SELECT row_to_json(p)
               FROM order_payment_details p
               WHERE p.order_id = o.id
               LIMIT 1
             ) AS payment
      FROM orders o
      LEFT JOIN order_delivery_details odd ON odd.order_id = o.id
      LEFT JOIN order_payment_details opd ON opd.order_id = o.id
      WHERE o.id = $1
      `,
      [orderId]
    );

    res.json(newOrder.rows[0]);
  } catch (err) {
    await pool.query("ROLLBACK");

    console.error("Ошибка POST /orders:", err);

    res.status(500).json({
      message: "Ошибка при создании заказа",
      error: err.message,
    });
  }
});

app.get("/orders", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const ordersRes = await pool.query(
      `
      SELECT o.*,
             odd.delivery_price AS delivery_cost,
             odd.full_address AS delivery_address,
             opd.payment_method,
             opd.payment_status,
             (
               SELECT row_to_json(d)
               FROM order_delivery_details d
               WHERE d.order_id = o.id
               LIMIT 1
             ) AS delivery,
             (
               SELECT row_to_json(p)
               FROM order_payment_details p
               WHERE p.order_id = o.id
               LIMIT 1
             ) AS payment
      FROM orders o
      LEFT JOIN order_delivery_details odd ON odd.order_id = o.id
      LEFT JOIN order_payment_details opd ON opd.order_id = o.id
      WHERE o.user_id = $1
      ORDER BY o.created_at DESC
      `,
      [userId]
    );

    const orders = [];

    for (const order of ordersRes.rows) {
      const itemsRes = await pool.query(
        `
        SELECT oi.*,
               p.name,
               p.image_url
        FROM order_items oi
        JOIN products p ON p.id = oi.product_id
        WHERE oi.order_id = $1
        `,
        [order.id]
      );

      orders.push({
        ...order,
        items: itemsRes.rows,
      });
    }

    res.json(orders);
  } catch (err) {
    console.error("Ошибка GET /orders:", err);
    res.status(500).json({ message: "Ошибка при получении заказов" });
  }
});

app.get("/orders/:id", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const orderId = Number(req.params.id);

  try {
    const result = await pool.query(
      `
      SELECT o.*,
             COALESCE(
               (
                 SELECT json_agg(
                   json_build_object(
                     'id', oi.id,
                     'order_id', oi.order_id,
                     'product_id', oi.product_id,
                     'quantity', oi.quantity,
                     'price', oi.price,
                     'name', p.name,
                     'image_url', p.image_url
                   )
                   ORDER BY oi.id
                 )
                 FROM order_items oi
                 LEFT JOIN products p ON p.id = oi.product_id
                 WHERE oi.order_id = o.id
               ),
               '[]'::json
             ) AS items,
             row_to_json(odd.*) AS delivery,
             row_to_json(opd.*) AS payment,
             odd.full_address AS delivery_address,
             odd.delivery_price AS delivery_cost,
             opd.payment_method AS payment_method,
             opd.payment_status AS payment_status
      FROM orders o
      LEFT JOIN order_delivery_details odd ON odd.order_id = o.id
      LEFT JOIN order_payment_details opd ON opd.order_id = o.id
      WHERE o.id = $1 AND o.user_id = $2
      `,
      [orderId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Заказ не найден" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error("Ошибка GET /orders/:id:", err);
    res.status(500).json({ message: "Ошибка при получении заказа" });
  }
});

app.put("/orders/:id/status", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const orderId = Number(req.params.id);
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ message: "Не указан статус" });
  }

  try {
    const orderResult = await pool.query(
      "SELECT id FROM orders WHERE id = $1 AND user_id = $2",
      [orderId, userId]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ message: "Заказ не найден" });
    }

    await pool.query("UPDATE orders SET status = $1 WHERE id = $2", [
      status,
      orderId,
    ]);

    await pool.query(
      "INSERT INTO order_history (order_id, status) VALUES ($1, $2)",
      [orderId, status]
    );

    res.json({ message: "Статус заказа обновлён" });
  } catch (err) {
    console.error("Ошибка PUT /orders/:id/status:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/admin/orders", authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        o.id,
        o.user_id,
        c.name AS customer_name,
        c.email AS customer_email,
        c.phone AS customer_phone,
        o.status,
        o.total,
        o.items_total,
        o.delivery_cost,
        o.bonus_applied,
        o.bonus_earned,
        o.created_at,
        odd.full_address AS delivery_address,
        odd.delivery_method,
        opd.payment_method,
        opd.payment_status,
        COALESCE(
          (
            SELECT json_agg(
              json_build_object(
                'product_id', oi.product_id,
                'name', p.name,
                'quantity', oi.quantity,
                'price', oi.price,
                'image_url', p.image_url
              )
            )
            FROM order_items oi
            LEFT JOIN products p ON p.id = oi.product_id
            WHERE oi.order_id = o.id
          ),
          '[]'::json
        ) AS items
      FROM orders o
      LEFT JOIN customers c ON c.id = o.user_id
      LEFT JOIN order_delivery_details odd ON odd.order_id = o.id
      LEFT JOIN order_payment_details opd ON opd.order_id = o.id
      ORDER BY o.created_at DESC
      `
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /admin/orders:", err);
    res.status(500).json({ message: "Ошибка загрузки заказов", error: err.message });
  }
});

app.put("/admin/orders/:id/status", authenticateToken, requireAdmin, async (req, res) => {
  const orderId = Number(req.params.id);
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ message: "Не указан статус заказа" });
  }

  try {
    await pool.query("BEGIN");

    const result = await pool.query(
      "UPDATE orders SET status = $1 WHERE id = $2 RETURNING *",
      [status, orderId]
    );

    if (result.rows.length === 0) {
      await pool.query("ROLLBACK");
      return res.status(404).json({ message: "Заказ не найден" });
    }

    await pool.query(
      "INSERT INTO order_history (order_id, status) VALUES ($1, $2)",
      [orderId, status]
    );

    await pool.query("COMMIT");

    res.json(result.rows[0]);
  } catch (err) {
    await pool.query("ROLLBACK");
    console.error("Ошибка PUT /admin/orders/:id/status:", err);
    res.status(500).json({ message: "Ошибка обновления статуса", error: err.message });
  }
});

app.use((req, res) => {
  res.status(404).json({
    message: "Маршрут не найден",
    path: req.originalUrl,
  });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Сервер запущен на http://0.0.0.0:${PORT}`);
});