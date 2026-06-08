const { pool } = require('../config/db');

async function getUsers(req, res) {
  const { role, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  const where  = role ? 'WHERE role = ?' : '';
  const params = role ? [role] : [];
  const [rows] = await pool.query(
    `SELECT id, nama, email, role, is_active, created_at FROM users ${where} ORDER BY created_at DESC LIMIT ? OFFSET ?`,
    [...params, parseInt(limit), offset]
  );
  res.json({ success: true, data: rows });
}

async function toggleUser(req, res) {
  const { is_active } = req.body;
  await pool.query('UPDATE users SET is_active = ?, updated_at = NOW() WHERE id = ?', [is_active ? 1 : 0, req.params.id]);
  res.json({ success: true });
}

async function getStats(req, res) {
  const [[stats]] = await pool.query(`
    SELECT
      (SELECT COUNT(*) FROM users WHERE role='pelamar'    AND is_active=1) AS total_pelamar,
      (SELECT COUNT(*) FROM users WHERE role='perusahaan' AND is_active=1) AS total_perusahaan,
      (SELECT COUNT(*) FROM lowongan WHERE status='aktif')                 AS lowongan_aktif,
      (SELECT COUNT(*) FROM lowongan WHERE status='pending')               AS lowongan_pending,
      (SELECT COUNT(*) FROM lamaran)                                       AS total_lamaran,
      (SELECT COUNT(*) FROM lamaran WHERE status='diterima')               AS lamaran_diterima,
      (SELECT COUNT(DISTINCT lokasi) FROM lowongan WHERE status='aktif')   AS total_kota
  `);
  res.json({ success: true, data: stats });
}

module.exports = { getUsers, toggleUser, getStats };
