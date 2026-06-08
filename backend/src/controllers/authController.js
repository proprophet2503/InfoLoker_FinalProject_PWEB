const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const { pool } = require('../config/db');

async function register(req, res) {
  const { nama, email, password, role, no_hp } = req.body;
  const [rows] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
  if (rows.length) return res.status(409).json({ success: false, error: 'Email sudah terdaftar' });

  const hash = await bcrypt.hash(password, 12);
  const [result] = await pool.query(
    'INSERT INTO users (nama, email, password, role, no_hp) VALUES (?, ?, ?, ?, ?)',
    [nama, email, hash, role || 'pelamar', no_hp || null]
  );

  if (['pelamar','perusahaan'].includes(role)) {
    if (role === 'pelamar') {
      await pool.query('INSERT INTO pelamar_profiles (user_id) VALUES (?)', [result.insertId]);
    } else {
      const nama_perusahaan = req.body.nama_perusahaan || nama;
      await pool.query('INSERT INTO perusahaan_profiles (user_id, nama_perusahaan) VALUES (?, ?)',
        [result.insertId, nama_perusahaan]);
    }
  }

  return res.status(201).json({ success: true, data: { id: result.insertId, email, role } });
}

async function login(req, res) {
  const { email, password, remember } = req.body;
  const [rows] = await pool.query(
    'SELECT id, nama, email, password, role, is_active FROM users WHERE email = ?',
    [email]
  );
  if (!rows.length) return res.status(401).json({ success: false, error: 'Email atau password salah' });

  const user = rows[0];
  if (!user.is_active) return res.status(403).json({ success: false, error: 'Akun dinonaktifkan' });

  const match = await bcrypt.compare(password, user.password);
  if (!match) return res.status(401).json({ success: false, error: 'Email atau password salah' });

  const expiresIn = remember ? process.env.JWT_REMEMBER_EXPIRES_IN || '7d' : process.env.JWT_EXPIRES_IN || '24h';
  const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn });

  return res.json({ success: true, data: { token, user: { id: user.id, nama: user.nama, email: user.email, role: user.role } } });
}

module.exports = { register, login };
