const { pool } = require('../config/db');

async function getSaya(req, res) {
  const [users] = await pool.query('SELECT id, nama, email, role, no_hp, is_active, created_at FROM users WHERE id = ?', [req.user.id]);
  if (!users.length) return res.status(404).json({ success: false, error: 'User tidak ditemukan' });
  const user = users[0];

  let profil = null;
  if (user.role === 'pelamar') {
    const [r] = await pool.query('SELECT * FROM pelamar_profiles WHERE user_id = ?', [req.user.id]);
    profil = r[0] || null;
    const [skills]  = await pool.query('SELECT * FROM skills WHERE pelamar_id = ?', [req.user.id]);
    const [exp]     = await pool.query('SELECT * FROM pengalaman_kerja WHERE pelamar_id = ? ORDER BY mulai DESC', [req.user.id]);
    const [edu]     = await pool.query('SELECT * FROM pendidikan WHERE pelamar_id = ? ORDER BY tahun_masuk DESC', [req.user.id]);
    profil = { ...profil, skills, pengalaman_kerja: exp, pendidikan: edu };
  } else if (user.role === 'perusahaan') {
    const [r] = await pool.query('SELECT * FROM perusahaan_profiles WHERE user_id = ?', [req.user.id]);
    profil = r[0] || null;
  }

  res.json({ success: true, data: { ...user, profil } });
}

async function updateSaya(req, res) {
  const { nama, no_hp } = req.body;
  await pool.query('UPDATE users SET nama = ?, no_hp = ?, updated_at = NOW() WHERE id = ?', [nama, no_hp || null, req.user.id]);

  if (req.user.role === 'pelamar') {
    const { headline, about, kota, tanggal_lahir, linkedin_url } = req.body;
    await pool.query(
      `INSERT INTO pelamar_profiles (user_id, headline, about, kota, tanggal_lahir, linkedin_url)
       VALUES (?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE headline=VALUES(headline), about=VALUES(about),
         kota=VALUES(kota), tanggal_lahir=VALUES(tanggal_lahir), linkedin_url=VALUES(linkedin_url)`,
      [req.user.id, headline || null, about || null, kota || null, tanggal_lahir || null, linkedin_url || null]
    );
  } else if (req.user.role === 'perusahaan') {
    const { nama_perusahaan, deskripsi, industri, ukuran, website, kota } = req.body;
    await pool.query(
      `INSERT INTO perusahaan_profiles (user_id, nama_perusahaan, deskripsi, industri, ukuran, website, kota)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE nama_perusahaan=VALUES(nama_perusahaan), deskripsi=VALUES(deskripsi),
         industri=VALUES(industri), ukuran=VALUES(ukuran), website=VALUES(website), kota=VALUES(kota)`,
      [req.user.id, nama_perusahaan, deskripsi || null, industri || null, ukuran || null, website || null, kota || null]
    );
  }

  res.json({ success: true });
}

async function uploadFoto(req, res) {
  const filename = req.file?.filename;
  if (!filename) return res.status(400).json({ success: false, error: 'Foto tidak ditemukan' });
  await pool.query('UPDATE pelamar_profiles SET foto = ? WHERE user_id = ?', [filename, req.user.id]);
  res.json({ success: true, data: { foto: filename } });
}

async function uploadLogo(req, res) {
  const filename = req.file?.filename;
  if (!filename) return res.status(400).json({ success: false, error: 'Logo tidak ditemukan' });
  await pool.query('UPDATE perusahaan_profiles SET logo = ? WHERE user_id = ?', [filename, req.user.id]);
  res.json({ success: true, data: { logo: filename } });
}

module.exports = { getSaya, updateSaya, uploadFoto, uploadLogo };
