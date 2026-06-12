<?php
/** GET /api/jobs/detail.php?id=NN — Satu lowongan + tambah view. */
require_once __DIR__ . '/../helpers.php';
require_once __DIR__ . '/_map.php';

$id = (int) ($_GET['id'] ?? 0);
if ($id <= 0) {
    fail('ID lowongan tidak valid.');
}

$sql = 'SELECT l.id, l.judul, l.kategori, l.tipe, l.lokasi, l.gaji_min, l.gaji_max,
               l.deskripsi, l.kualifikasi, l.posted_at, p.nama_perusahaan
          FROM lowongan l
          JOIN perusahaan_profiles p ON p.id = l.perusahaan_id
         WHERE l.id = ? AND l.status = ?
         LIMIT 1';

$stmt = db()->prepare($sql);
$stmt->execute([$id, 'aktif']);
$row = $stmt->fetch();

if (!$row) {
    fail('Lowongan tidak ditemukan.', 404);
}

// Tambah penghitung view (best-effort).
try {
    db()->prepare('UPDATE lowongan SET views = views + 1 WHERE id = ?')->execute([$id]);
} catch (PDOException $e) {
    // abaikan; bukan kegagalan kritis
}

ok(format_job($row));
