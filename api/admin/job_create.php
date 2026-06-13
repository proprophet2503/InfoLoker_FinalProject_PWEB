<?php
/**
 * POST /api/admin/job_create.php — HR menambah lowongan untuk perusahaannya.
 * Judul dibatasi pada daftar posisi dari database awal; kategori
 * diturunkan otomatis dari judul di server. Body JSON.
 */
require_once __DIR__ . '/../helpers.php';

require_method('POST');
require_csrf();
$me  = require_role('perusahaan');
$cid = my_company_id((int) $me['id']);
if (!$cid) {
    fail('Profil perusahaan tidak ditemukan.', 403);
}

// Daftar posisi tetap (dari seed) -> kategori.
$posisi = [
    'Frontend Developer'            => 'IT',
    'Backend Developer'             => 'IT',
    'UI/UX Designer'                => 'Design',
    'Digital Marketing Specialist'  => 'Marketing',
    'Data Analyst'                  => 'Data',
    'Product Manager'               => 'Management',
    'Finance Analyst'               => 'Finance',
    'HR Specialist'                 => 'HR',
    'Operations Officer'            => 'Operations',
    'Customer Support'              => 'Support',
];

$in = input();

$judul     = trim((string) ($in['judul'] ?? ''));
$tipe      = trim((string) ($in['tipe'] ?? 'Full-time'));
$lokasi    = trim((string) ($in['lokasi'] ?? ''));
$deskripsi = trim((string) ($in['deskripsi'] ?? ''));
$kualifikasi = trim((string) ($in['kualifikasi'] ?? ''));

$gajiMin = ($in['gaji_min'] ?? '') !== '' ? (int) $in['gaji_min'] : null;
$gajiMax = ($in['gaji_max'] ?? '') !== '' ? (int) $in['gaji_max'] : null;
$kebutuhan = (int) ($in['jumlah_kebutuhan'] ?? 1);
if ($kebutuhan < 1) {
    $kebutuhan = 1;
}

$tipeAllowed = ['Full-time', 'Part-time', 'Remote', 'Freelance', 'Internship'];
if (!in_array($tipe, $tipeAllowed, true)) {
    $tipe = 'Full-time';
}

if (!array_key_exists($judul, $posisi)) {
    fail('Posisi tidak valid. Pilih dari daftar yang tersedia.');
}
if ($lokasi === '' || $deskripsi === '') {
    fail('Lokasi dan deskripsi wajib diisi.');
}
$kategori = $posisi[$judul];

$nz = static fn(string $v): ?string => ($v !== '' ? $v : null);

$ins = db()->prepare(
    'INSERT INTO lowongan
        (perusahaan_id, judul, kategori, tipe, lokasi, gaji_min, gaji_max,
         deskripsi, kualifikasi, jumlah_kebutuhan, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
);
$ins->execute([
    $cid, $judul, $kategori, $tipe, $lokasi, $gajiMin, $gajiMax,
    $deskripsi, $nz($kualifikasi), $kebutuhan, 'aktif',
]);

ok(['id' => (int) db()->lastInsertId()]);
