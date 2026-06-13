<?php
/** GET /api/auth/me.php — User saat ini + token CSRF. Selalu 200. */
require_once __DIR__ . '/../helpers.php';

$user = current_user();

$namaPerusahaan = null;
if ($user && $user['role'] === 'perusahaan') {
    $q = db()->prepare('SELECT nama_perusahaan FROM perusahaan_profiles WHERE user_id = ? LIMIT 1');
    $q->execute([$user['id']]);
    $namaPerusahaan = $q->fetchColumn() ?: null;
}

$payload = [
    'user' => $user ? [
        'id'    => (int) $user['id'],
        'nama'  => $user['nama'],
        'email' => $user['email'],
        'role'  => $user['role'],
        'no_hp' => $user['no_hp'],
        'nama_perusahaan' => $namaPerusahaan,
    ] : null,
    'csrf' => csrf_token(),
];

ok($payload);
