<?php
/** GET /api/jobs/list.php — Semua lowongan berstatus aktif. */
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/_map.php';

$sql = 'SELECT l.id, l.judul, l.kategori, l.tipe, l.lokasi, l.gaji_min, l.gaji_max,
               l.deskripsi, l.kualifikasi, l.posted_at, p.nama_perusahaan
          FROM lowongan l
          JOIN perusahaan_profiles p ON p.id = l.perusahaan_id
         WHERE l.status = ?
         ORDER BY l.posted_at DESC, l.id DESC';

$stmt = db()->prepare($sql);
$stmt->execute(['aktif']);
$rows = $stmt->fetchAll();

$jobs = array_map('format_job', $rows);
ok($jobs);
