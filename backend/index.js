const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('/app/public'));

// Configuración de la base de datos desde variables de entorno
const dbConfig = {
  host: process.env.DB_HOST || 'db',
  user: process.env.DB_USER || 'todouser',
  password: process.env.DB_PASSWORD || 'todopassword',
  database: process.env.DB_NAME || 'tododb',
  waitForConnections: true,
  connectionLimit: 10,
};

let pool;

// Esperar a que MySQL esté listo antes de arrancar
async function waitForDB() {
  const maxRetries = 30;
  for (let i = 0; i < maxRetries; i++) {
    try {
      pool = mysql.createPool(dbConfig);
      await pool.query('SELECT 1');
      console.log('✅ Conectado a MySQL correctamente');
      return;
    } catch (err) {
      console.log(`⏳ Esperando a MySQL... intento ${i + 1}/${maxRetries}`);
      if (pool) { await pool.end().catch(() => {}); }
      await new Promise(res => setTimeout(res, 3000));
    }
  }
  throw new Error('No se pudo conectar a MySQL tras varios intentos');
}

// ── RUTAS CRUD ──────────────────────────────────────────────

// GET /api/tasks - Obtener todas las tareas
app.get('/api/tasks', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM tasks ORDER BY created_at DESC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/tasks/:id - Obtener una tarea por ID
app.get('/api/tasks/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM tasks WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Tarea no encontrada' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/tasks - Crear una nueva tarea
app.post('/api/tasks', async (req, res) => {
  const { title, description } = req.body;
  if (!title) return res.status(400).json({ error: 'El título es obligatorio' });
  try {
    const [result] = await pool.query(
      'INSERT INTO tasks (title, description) VALUES (?, ?)',
      [title, description || '']
    );
    const [rows] = await pool.query('SELECT * FROM tasks WHERE id = ?', [result.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/tasks/:id - Actualizar una tarea
app.put('/api/tasks/:id', async (req, res) => {
  const { title, description, completed } = req.body;
  try {
    const [result] = await pool.query(
      'UPDATE tasks SET title = ?, description = ?, completed = ? WHERE id = ?',
      [title, description, completed, req.params.id]
    );
    if (result.affectedRows === 0) return res.status(404).json({ error: 'Tarea no encontrada' });
    const [rows] = await pool.query('SELECT * FROM tasks WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/tasks/:id - Eliminar una tarea
app.delete('/api/tasks/:id', async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM tasks WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) return res.status(404).json({ error: 'Tarea no encontrada' });
    res.json({ message: 'Tarea eliminada correctamente' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Arrancar servidor
const PORT = process.env.PORT || 3000;
waitForDB().then(() => {
  app.listen(PORT, () => console.log(`🚀 Servidor corriendo en puerto ${PORT}`));
}).catch(err => {
  console.error('❌ Error fatal:', err.message);
  process.exit(1);
});
