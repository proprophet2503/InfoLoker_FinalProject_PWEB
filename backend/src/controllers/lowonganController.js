const { pool } = require('../config/db');

async function list(req, res) {
  const { q, kategori, lokasi, tipe, gaji_min, page = 1, limit = 10 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  let where = ['l.status = "aktif"'];
  const params = [];

  if (q)        { where.push('(l.judul LIKE ? OR p.nama_perusahaan LIKE ?)'); params.push(`%${q}%`,`%${q}%`); }
  if (kategori) { where.push('l.kategori = ?'); params.push(kategori); }
  if (lokasi)   { where.push('l.lokasi = ?');   params.push(lokasi); }
  if (tipe)     { where.push('l.tipe = ?');     params.push(tipe); }
  if (gaji_min) { where.push('l.gaji_min >= ?'); params.push(parseInt(gaji_min)); }

  const sql = `SELECT l.*, p.nama_perusahaan, p.logo, p.kota AS kota_perusahaan
               FROM lowongan l
               JOIN perusahaan_profiles p ON l.perusahaan_id = p.id
               WHERE ${where.join(' AND ')}
               ORDER BY l.posted_at DESC
               LIMIT ? OFFSET ?`;
  const [rows]  = await pool.query(sql, [...params, parseInt(limit), offset]);
  const [[{total}]] = await pool.query(
    `SELECT COUNT(*) AS total FROM lowongan l JOIN perusahaan_profiles p ON l.perusahaan_id=p.id WHERE ${where.join(' AND ')}`,
    params
  );
  res.json({ success: true, data: rows, meta: { total, page: parseInt(page), limit: parseInt(limit) } });
}

async function detail(req, res) {
  const [rows] = await pool.query(
    `SELECT l.*, p.nama_perusahaan, p.logo, p.deskripsi AS deskripsi_perusahaan, p.website, p.kota AS kota_perusahaan
     FROM lowongan l JOIN perusahaan_profiles p ON l.perusahaan_id = p.id
     WHERE l.id = ? AND l.status = 'aktif'`,
    [req.params.id]
  );
  if (!rows.length) return res.status(404).json({ success: false, error: 'Lowongan tidak ditemukan' });
  await pool.query('UPDATE lowongan SET views = views + 1 WHERE id = ?', [req.params.id]);
  res.json({ success: true, data: rows[0] });
}

async function create(req, res) {
  const [prof] = await pool.query('SELECT id FROM perusahaan_profiles WHERE user_id = ?', [req.user.id]);
  if (!prof.length) return res.status(400).json({ success: false, error: 'Profil perusahaan belum dilengkapi' });

  const { judul, kategori, tipe, lokasi, gaji_min, gaji_max, deskripsi, kualifikasi, benefit, deadline, jumlah_kebutuhan } = req.body;
  const [result] = await pool.query(
    `INSERT INTO lowongan (perusahaan_id, judul, kategori, tipe, lokasi, gaji_min, gaji_max, deskripsi, kualifikasi, benefit, deadline, jumlah_kebutuhan)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [prof[0].id, judul, kategori, tipe, lokasi, gaji_min || null, gaji_max || null, deskripsi,
     JSON.stringify(kualifikasi || []), JSON.stringify(benefit || []), deadline || null, jumlah_kebutuhan || 1]
  );
  res.status(201).json({ success: true, data: { id: result.insertId } });
}

async function update(req, res) {
  const [prof] = await pool.query('SELECT id FROM perusahaan_profiles WHERE user_id = ?', [req.user.id]);
  if (!prof.length) return res.status(403).json({ success: false, error: 'Akses ditolak' });
  const { judul, kategori, tipe, lokasi, gaji_min, gaji_max, deskripsi, kualifikasi, benefit, deadline, jumlah_kebutuhan } = req.body;
  await pool.query(
    `UPDATE lowongan SET judul=?, kategori=?, tipe=?, lokasi=?, gaji_min=?, gaji_max=?, deskripsi=?,
     kualifikasi=?, benefit=?, deadline=?, jumlah_kebutuhan=?, status='pending', updated_at=NOW()
     WHERE id = ? AND perusahaan_id = ?`,
    [judul, kategori, tipe, lokasi, gaji_min||null, gaji_max||null, deskripsi,
     JSON.stringify(kualifikasi||[]), JSON.stringify(benefit||[]), deadline||null, jumlah_kebutuhan||1,
     req.params.id, prof[0].id]
  );
  res.json({ success: true });
}

async function remove(req, res) {
  if (req.user.role === 'admin') {
    await pool.query('DELETE FROM lowongan WHERE id = ?', [req.params.id]);
  } else {
    const [prof] = await pool.query('SELECT id FROM perusahaan_profiles WHERE user_id = ?', [req.user.id]);
    if (!prof.length) return res.status(403).json({ success: false, error: 'Akses ditolak' });
    await pool.query('DELETE FROM lowongan WHERE id = ? AND perusahaan_id = ?', [req.params.id, prof[0].id]);
  }
  res.json({ success: true });
}

async function updateStatus(req, res) {
  const { status } = req.body;
  if (!['pending','aktif','ditutup','ditolak'].includes(status))
    return res.status(400).json({ success: false, error: 'Status tidak valid' });
  await pool.query('UPDATE lowongan SET status = ?, updated_at = NOW() WHERE id = ?', [status, req.params.id]);
  res.json({ success: true });
}

module.exports = { list, detail, create, update, remove, updateStatus };
