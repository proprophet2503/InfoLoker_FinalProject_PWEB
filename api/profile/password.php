<?php
/** POST /api/profile/password.php — Ganti password (user yang login). */
require_once __DIR__ . '/../helpers.php';

require_method('POST');
require_csrf();
$me = require_login();

$in      = input();
$current = (string) ($in['current_password'] ?? '');
$new     = (string) ($in['new_password'] ?? '');

if ($current === '' || $new === '') {
    fail('Password lama dan baru wajib diisi.');
}
if (strlen($new) < 8 || !preg_match('/\d/', $new)) {
    fail('Password baru minimal 8 karakter dan mengandung angka.');
}

$pdo  = db();
$stmt = $pdo->prepare('SELECT password FROM users WHERE id = ? LIMIT 1');
$stmt->execute([$me['id']]);
$row = $stmt->fetch();

if (!$row || !password_verify($current, $row['password'])) {
    fail('Password lama salah.', 401);
}

$hash = password_hash($new, PASSWORD_BCRYPT);
$upd  = $pdo->prepare('UPDATE users SET password = ? WHERE id = ?');
$upd->execute([$hash, $me['id']]);

ok(['changed' => true]);
