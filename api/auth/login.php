<?php
/** POST /api/auth/login.php — Login dengan email + password. */
require_once __DIR__ . '/../helpers.php';

require_method('POST');
require_csrf();

$in    = input();
$email = strtolower((string) field($in, 'email', ''));
$pass  = (string) ($in['password'] ?? '');

if ($email === '' || $pass === '') {
    fail('Email dan password wajib diisi.');
}

$stmt = db()->prepare(
    'SELECT id, nama, email, password, role, is_active
       FROM users WHERE email = ? LIMIT 1'
);
$stmt->execute([$email]);
$user = $stmt->fetch();

// Pesan generik supaya tidak membocorkan email mana yang terdaftar.
if (!$user || !password_verify($pass, $user['password'])) {
    fail('Email atau password salah.', 401);
}
if ((int) $user['is_active'] !== 1) {
    fail('Akun Anda nonaktif. Hubungi admin.', 403);
}

// Cegah session fixation.
session_regenerate_id(true);
$_SESSION['user_id'] = (int) $user['id'];

ok([
    'id'    => (int) $user['id'],
    'nama'  => $user['nama'],
    'email' => $user['email'],
    'role'  => $user['role'],
]);
