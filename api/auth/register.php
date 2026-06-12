<?php
/** POST /api/auth/register.php — Buat akun baru. */
require_once __DIR__ . '/../helpers.php';

require_method('POST');
require_csrf();

$in    = input();
$nama  = field($in, 'nama', '');
$email = strtolower((string) field($in, 'email', ''));
$pass  = (string) ($in['password'] ?? '');
$role  = field($in, 'role', 'pelamar');
$noHp  = field($in, 'no_hp', null);
$namaPerusahaan = field($in, 'nama_perusahaan', null);

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
if (!in_array($role, ['pelamar', 'perusahaan'], true)) {
    fail('Role tidak valid.');
}
if ($role === 'perusahaan' && ($namaPerusahaan === null || $namaPerusahaan === '')) {
    fail('Nama perusahaan wajib diisi untuk akun perusahaan.');
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
    $pdo->beginTransaction();

    $ins = $pdo->prepare(
        'INSERT INTO users (nama, email, password, role, no_hp)
         VALUES (?, ?, ?, ?, ?)'
    );
    $ins->execute([$nama, $email, $hash, $role, ($noHp !== '' ? $noHp : null)]);
    $userId = (int) $pdo->lastInsertId();

    if ($role === 'perusahaan') {
        $p = $pdo->prepare(
            'INSERT INTO perusahaan_profiles (user_id, nama_perusahaan)
             VALUES (?, ?)'
        );
        $p->execute([$userId, $namaPerusahaan]);
    } else {
        $p = $pdo->prepare('INSERT INTO pelamar_profiles (user_id) VALUES (?)');
        $p->execute([$userId]);
    }

    $pdo->commit();
} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    $msg = APP_DEBUG ? 'Gagal mendaftar: ' . $e->getMessage() : 'Gagal mendaftar. Coba lagi.';
    fail($msg, 500);
}

ok(['id' => $userId, 'nama' => $nama, 'email' => $email, 'role' => $role]);
