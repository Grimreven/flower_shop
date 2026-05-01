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

function toNumber(value, fallback = 0) {
  const result = Number(value);
  return Number.isFinite(result) ? result : fallback;
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
    const exists = await pool.query("SELECT id FROM customers WHERE email = $1", [
      email,
    ]);

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
      `INSERT INTO customers (name, email, password_hash, role_id)
       VALUES ($1, $2, $3, $4)
       RETURNING id, name, email, phone`,
      [name, email, hashedPassword, roleId]
    );

    const user = result.rows[0];

    await pool.query(
      `INSERT INTO loyalty_accounts (user_id, points, total_spent, level_id)
       VALUES ($1, $2, $3, $4)`,
      [user.id, 0, 0, levelId]
    );

    const token = jwt.sign(
      { id: user.id, email: user.email },
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
      "SELECT id, name, email, password_hash, phone FROM customers WHERE email = $1",
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
      { id: user.id, email: user.email },
      process.env.JWT_SECRET || "mysecret",
      { expiresIn: "7d" }
    );

    res.json({
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
      },
      token,
    });
  } catch (err) {
    console.error("Ошибка POST /login:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/profile", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const result = await pool.query(
      `SELECT c.id,
              c.name,
              c.email,
              c.phone,
              COALESCE(l.points, 0) AS loyalty_points,
              COALESCE(l.total_spent, 0) AS total_spent,
              COALESCE(levels.name, 'Bronze') AS loyalty_level,
              COALESCE(levels.color_hex, '#CD7F32') AS loyalty_color
       FROM customers c
       LEFT JOIN loyalty_accounts l ON l.user_id = c.id
       LEFT JOIN loyalty_levels levels ON levels.id = l.level_id
       WHERE c.id = $1`,
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
      `UPDATE customers
       SET name = $1, email = $2, phone = $3
       WHERE id = $4
       RETURNING id, name, email, phone`,
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

app.post("/logout", authenticateToken, async (req, res) => {
  res.json({ message: "Выход выполнен успешно" });
});

app.get("/products", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.*, c.name AS category_name
       FROM products p
       LEFT JOIN categories c ON c.id = p.category_id
       ORDER BY p.id DESC`
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /products:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/products/popular", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.*, c.name AS category_name
       FROM products p
       LEFT JOIN categories c ON c.id = p.category_id
       ORDER BY p.rating DESC NULLS LAST, p.id DESC
       LIMIT 6`
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
      `SELECT r.*, c.name AS user_name
       FROM reviews r
       LEFT JOIN customers c ON c.id = r.user_id
       WHERE r.product_id = $1
       ORDER BY r.created_at DESC`,
      [req.params.id]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /products/:id/reviews:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/products/:id/price-history", async (req, res) => {
  const productId = req.params.id;

  try {
    const result = await pool.query(
      `SELECT price, changed_at
       FROM product_price_history
       WHERE product_id = $1
       ORDER BY changed_at ASC`,
      [productId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("Ошибка GET /products/:id/price-history:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.get("/cart", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const cartResult = await pool.query("SELECT id FROM carts WHERE user_id = $1", [
      userId,
    ]);

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
      `SELECT ci.id,
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
       ORDER BY ci.id DESC`,
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
      cart = await pool.query("INSERT INTO carts (user_id) VALUES ($1) RETURNING id", [
        userId,
      ]);
    }

    const cartId = cart.rows[0].id;

    const existing = await pool.query(
      "SELECT id, quantity FROM cart_items WHERE cart_id = $1 AND product_id = $2",
      [cartId, product_id]
    );

    if (existing.rows.length > 0) {
      const newQuantity = existing.rows[0].quantity + quantity;

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
    console.error("Ошибка DELETE /cart:", err);
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
      `INSERT INTO favorites (user_id, product_id)
       VALUES ($1, $2)
       ON CONFLICT (user_id, product_id) DO NOTHING`,
      [userId, productId]
    );

    res.json({ message: "Товар добавлен в избранное" });
  } catch (err) {
    console.error("Ошибка POST /favorites:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
  }
});

app.delete("/favorites/:product_id", authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const productId = Number(req.params.product_id);

  try {
    await pool.query("DELETE FROM favorites WHERE user_id = $1 AND product_id = $2", [
      userId,
      productId,
    ]);

    res.json({ message: "Товар удалён из избранного" });
  } catch (err) {
    console.error("Ошибка DELETE /favorites:", err);
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
      `SELECT id,
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
       ORDER BY is_default DESC, id DESC`,
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
      `INSERT INTO customer_addresses
       (user_id, title, recipient_name, phone, city, street, house, apartment, entrance, floor, comment, is_default)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
       RETURNING id, user_id, title, recipient_name, phone, city, street, house, apartment, entrance, floor, comment, is_default, created_at, updated_at`,
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
      `UPDATE customer_addresses
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
       RETURNING id, user_id, title, recipient_name, phone, city, street, house, apartment, entrance, floor, comment, is_default, created_at, updated_at`,
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

  if (!checkout) {
    return res.status(400).json({ message: "Нет данных оформления заказа" });
  }

  try {
    await pool.query("BEGIN");

    let itemsTotal = 0;

    for (const item of items) {
      const productId = Number(item.product_id || item.productId);
      const quantity = Number(item.quantity);

      if (!productId || !quantity || quantity <= 0) {
        throw new Error("Некорректный товар в заказе");
      }

      const productRes = await pool.query(
        "SELECT id, price FROM products WHERE id = $1",
        [productId]
      );

      if (productRes.rows.length === 0) {
        throw new Error(`Товар ${productId} не найден`);
      }

      itemsTotal += Number(productRes.rows[0].price) * quantity;
    }

    const deliveryPrice = Number(
      checkout.delivery_price ??
        checkout.deliveryPrice ??
        checkout.delivery_cost ??
        checkout.deliveryCost ??
        0
    );

    const bonusApplied = Number(
      checkout.applied_bonuses ??
        checkout.appliedBonuses ??
        checkout.bonus_applied ??
        0
    );

    const total = Math.max(itemsTotal + deliveryPrice - bonusApplied, 0);

    const orderStatus = "Заказ оформлен";

    const orderRes = await pool.query(
      `INSERT INTO orders (user_id, total, status)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [userId, total, orderStatus]
    );

    const orderId = orderRes.rows[0].id;

    for (const item of items) {
      const productId = Number(item.product_id || item.productId);
      const quantity = Number(item.quantity);

      await pool.query(
        `INSERT INTO order_items (order_id, product_id, quantity, price)
         VALUES ($1, $2, $3, (SELECT price FROM products WHERE id = $2))`,
        [orderId, productId, quantity]
      );
    }

    const addressId =
      checkout.address_id || checkout.addressId
        ? Number(checkout.address_id || checkout.addressId)
        : null;

    const recipientName =
      checkout.recipient_name || checkout.recipientName || null;

    const phone = checkout.phone || null;

    const fullAddress =
      checkout.full_address ||
      checkout.fullAddress ||
      checkout.delivery_address ||
      checkout.deliveryAddress ||
      "Адрес не указан";

    const deliveryMethod =
      checkout.delivery_method || checkout.deliveryMethod || "delivery";

    const deliveryDate = checkout.delivery_date || checkout.deliveryDate || null;

    const deliveryTimeFrom =
      checkout.delivery_time_from || checkout.deliveryTimeFrom || null;

    const deliveryTimeTo =
      checkout.delivery_time_to || checkout.deliveryTimeTo || null;

    const comment =
      checkout.comment ||
      checkout.recipient_comment ||
      checkout.recipientComment ||
      null;

    const paymentMethod =
      checkout.payment_method || checkout.paymentMethod || "cash";

    const paymentStatus =
      checkout.payment_status || checkout.paymentStatus || "pending";

    const isPaid =
      paymentStatus === "paid" ||
      paymentStatus === "Оплачено картой" ||
      paymentStatus === "Оплачено через СБП";

    await pool.query(
      `INSERT INTO order_delivery_details
       (order_id, address_id, recipient_name, phone, full_address, delivery_method, delivery_date, delivery_time_from, delivery_time_to, comment, delivery_price)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
      [
        orderId,
        addressId,
        recipientName,
        phone,
        fullAddress,
        deliveryMethod,
        deliveryDate,
        deliveryTimeFrom,
        deliveryTimeTo,
        comment,
        deliveryPrice,
      ]
    );

    await pool.query(
      `INSERT INTO order_payment_details
       (order_id, payment_method, payment_status, payment_amount)
       VALUES ($1,$2,$3,$4)`,
      [orderId, paymentMethod, paymentStatus, total]
    );

    await pool.query(
      `INSERT INTO payment_transactions
       (order_id, user_id, payment_method_id, payment_type, amount, status, provider, provider_transaction_id, paid_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
      [
        orderId,
        userId,
        checkout.payment_method_id || checkout.paymentMethodId
          ? Number(checkout.payment_method_id || checkout.paymentMethodId)
          : null,
        paymentMethod,
        total,
        paymentStatus,
        checkout.provider || "demo",
        checkout.provider_transaction_id ||
          checkout.providerTransactionId ||
          null,
        isPaid ? new Date() : null,
      ]
    );

    await pool.query(
      "INSERT INTO order_history (order_id, status) VALUES ($1, $2)",
      [orderId, orderStatus]
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

    const order = await pool.query(
      `SELECT o.*,
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
       WHERE o.id = $1 AND o.user_id = $2`,
      [orderId, userId]
    );

    res.json(order.rows[0]);
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
    const result = await pool.query(
      `SELECT o.*,
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
       WHERE o.user_id = $1
       ORDER BY o.created_at DESC`,
      [userId]
    );

    res.json(result.rows);
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
      `SELECT o.*,
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
       WHERE o.id = $1 AND o.user_id = $2`,
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

    await pool.query("INSERT INTO order_history (order_id, status) VALUES ($1, $2)", [
      orderId,
      status,
    ]);

    res.json({ message: "Статус заказа обновлён" });
  } catch (err) {
    console.error("Ошибка PUT /orders/:id/status:", err);
    res.status(500).json({ message: "Ошибка сервера", error: err.message });
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