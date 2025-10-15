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



// ------------------- Запуск сервера -------------------
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Сервер запущен на http://localhost:${PORT}`));
