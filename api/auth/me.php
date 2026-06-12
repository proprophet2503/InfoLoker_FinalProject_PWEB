<?php
/** GET /api/auth/me.php — User saat ini + token CSRF. Selalu 200. */
require_once __DIR__ . '/../helpers.php';

$user = current_user();
$payload = [
    'user' => $user ? [
        'id'    => (int) $user['id'],
        'nama'  => $user['nama'],
        'email' => $user['email'],
        'role'  => $user['role'],
        'no_hp' => $user['no_hp'],
    ] : null,
    'csrf' => csrf_token(),
];

ok($payload);
