<?php
/** GET /api/lamaran/mine.php — Riwayat lamaran pelamar yang login. */
require_once __DIR__ . '/../helpers.php';

$me = require_role('pelamar');

$sql = 'SELECT lm.id, lm.status, lm.catatan_hr, lm.no_referensi, lm.submitted_at,
               lo.judul, p.nama_perusahaan
          FROM lamaran lm
          JOIN lowongan lo            ON lo.id = lm.lowongan_id
          JOIN perusahaan_profiles p  ON p.id = lo.perusahaan_id
         WHERE lm.pelamar_id = ?
         ORDER BY lm.submitted_at DESC';

$stmt = db()->prepare($sql);
$stmt->execute([$me['id']]);

ok($stmt->fetchAll());
