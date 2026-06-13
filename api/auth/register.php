<?php
/**
 * POST /api/auth/register.php — Buat akun baru.
 * Pendaftaran hanya untuk PELAMAR. Akun perusahaan (HR) sudah
 * disediakan langsung dari schema, tidak melalui registrasi.
 */
require_once __DIR__ . '/../helpers.php';

require_method('POST');
require_csrf();

$in    = input();
$nama  = field($in, 'nama', '');
$email = strtolower((string) field($in, 'email', ''));
$pass  = (string) ($in['password'] ?? '');
$noHp  = field($in, 'no_hp', null);

// --- Validasi ---
if ($nama === '' || $email === '' || $pass === '') {
    fail('Nama, email, dan password wajib diisi.');
}
if (mb_strlen($nama) > 100) {
    fail('Nama terlalu panjang (maks 100 karakter).');
}
if (!valid_email($email)) {
    fail('Format email tidak valid.');
}
if (strlen($pass) < 8 || !preg_match('/\d/', $pass)) {
    fail('Password minimal 8 karakter dan mengandung angka.');
}

$pdo = db();

// Email unik?
$check = $pdo->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
$check->execute([$email]);
if ($check->fetch()) {
    fail('Email sudah terdaftar. Silakan login.', 409);
}

$hash = password_hash($pass, PASSWORD_BCRYPT);

try {
    $ins = $pdo->prepare(
        'INSERT INTO users (nama, email, password, role, no_hp)
         VALUES (?, ?, ?, ?, ?)'
    );
    $ins->execute([$nama, $email, $hash, 'pelamar', ($noHp !== '' ? $noHp : null)]);
    $userId = (int) $pdo->lastInsertId();
} catch (PDOException $e) {
    $msg = APP_DEBUG ? 'Gagal mendaftar: ' . $e->getMessage() : 'Gagal mendaftar. Coba lagi.';
    fail($msg, 500);
}

ok(['id' => $userId, 'nama' => $nama, 'email' => $email, 'role' => 'pelamar']);
