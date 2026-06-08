const { pool } = require('../config/db');
const { v4: uuidv4 } = require('uuid');

async function submit(req, res) {
  const { lowongan_id, cover_letter, skills, pengalaman, sumber_info } = req.body;
  const cv_path   = req.files?.cv?.[0]?.filename   || null;
  const foto_path = req.files?.foto?.[0]?.filename || null;

  if (!cv_path) return res.status(400).json({ success: false, error: 'CV wajib diupload' });

  const [[{cnt}]] = await pool.query(
    'SELECT COUNT(*) AS cnt FROM lamaran WHERE lowongan_id = ? AND pelamar_id = ?',
    [lowongan_id, req.user.id]
  );
  if (cnt > 0) return res.status(409).json({ success: false, error: 'Anda sudah melamar ke lowongan ini' });

  const no_referensi = `IL-${Date.now()}-${uuidv4().slice(0,8).toUpperCase()}`;
  const [result] = await pool.query(
    `INSERT INTO lamaran (lowongan_id, pelamar_id, cover_letter, cv_path, foto_path, skills, pengalaman, sumber_info, no_referensi)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [lowongan_id, req.user.id, cover_letter, cv_path, foto_path,
     JSON.stringify(skills || []), pengalaman || null, sumber_info || null, no_referensi]
  );
  res.status(201).json({ success: true, data: { id: result.insertId, no_referensi } });
}

async function milikSaya(req, res) {
  const [rows] = await pool.query(
    `SELECT lm.id, lm.status, lm.no_referensi, lm.submitted_at, lo.judul, p.nama_perusahaan
     FROM lamaran lm
     JOIN lowongan lo ON lm.lowongan_id = lo.id
     JOIN perusahaan_profiles p ON lo.perusahaan_id = p.id
     WHERE lm.pelamar_id = ?
     ORDER BY lm.submitted_at DESC`,
    [req.user.id]
  );
  res.json({ success: true, data: rows });
}

async function updateStatus(req, res) {
  const { status, catatan_hr } = req.body;
  if (!['pending','review','diterima','ditolak'].includes(status))
    return res.status(400).json({ success: false, error: 'Status tidak valid' });
  await pool.query(
    'UPDATE lamaran SET status = ?, catatan_hr = ?, updated_at = NOW() WHERE id = ?',
    [status, catatan_hr || null, req.params.id]
  );
  res.json({ success: true });
}

async function listByLowongan(req, res) {
  const [rows] = await pool.query(
    `SELECT lm.*, u.nama, u.email, u.no_hp
     FROM lamaran lm JOIN users u ON lm.pelamar_id = u.id
     WHERE lm.lowongan_id = ?
     ORDER BY lm.submitted_at DESC`,
    [req.params.lowonganId]
  );
  res.json({ success: true, data: rows });
}

module.exports = { submit, milikSaya, updateStatus, listByLowongan };
