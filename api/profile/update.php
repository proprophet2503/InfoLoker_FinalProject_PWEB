<?php
/** POST /api/profile/update.php — Ubah data pribadi dasar (user yang login). */
require_once __DIR__ . '/../helpers.php';

require_method('POST');
require_csrf();
$me = require_login();

$in    = input();
$nama  = field($in, 'nama', '');
$email = strtolower((string) field($in, 'email', ''));
$noHp  = field($in, 'no_hp', null);

if ($nama === '' || $email === '') {
    fail('Nama dan email wajib diisi.');
}
if (mb_strlen($nama) > 100) {
    fail('Nama terlalu panjang (maks 100 karakter).');
}
if (!valid_email($email)) {
    fail('Format email tidak valid.');
}

$pdo = db();

// Pastikan email tidak dipakai user lain.
$dup = $pdo->prepare('SELECT id FROM users WHERE email = ? AND id <> ? LIMIT 1');
$dup->execute([$email, $me['id']]);
if ($dup->fetch()) {
    fail('Email sudah dipakai akun lain.', 409);
}

$upd = $pdo->prepare(
    'UPDATE users SET nama = ?, email = ?, no_hp = ? WHERE id = ?'
);
$upd->execute([$nama, $email, ($noHp !== '' ? $noHp : null), $me['id']]);

ok([
    'id'    => (int) $me['id'],
    'nama'  => $nama,
    'email' => $email,
    'role'  => $me['role'],
    'no_hp' => ($noHp !== '' ? $noHp : null),
]);
