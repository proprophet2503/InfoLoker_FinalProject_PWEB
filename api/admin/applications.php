<?php
/** GET /api/admin/applications.php — Lamaran masuk ke perusahaan HR yang login. */
require_once __DIR__ . '/../helpers.php';

$me  = require_role('perusahaan');
$cid = my_company_id((int) $me['id']);
if (!$cid) {
    fail('Profil perusahaan tidak ditemukan.', 403);
}

$sql = 'SELECT lm.id, lm.status, lm.no_referensi, lm.submitted_at, lm.catatan_hr,
               lo.judul, lo.id AS lowongan_id,
               p.nama_perusahaan,
               dp.nama AS pelamar_nama, dp.email AS pelamar_email
          FROM lamaran lm
          JOIN lowongan lo               ON lo.id = lm.lowongan_id
          JOIN perusahaan_profiles p     ON p.id = lo.perusahaan_id
          LEFT JOIN lamaran_data_pribadi dp ON dp.lamaran_id = lm.id
         WHERE lo.perusahaan_id = ?
         ORDER BY lm.submitted_at DESC, lm.id DESC';

$stmt = db()->prepare($sql);
$stmt->execute([$cid]);
ok($stmt->fetchAll());
