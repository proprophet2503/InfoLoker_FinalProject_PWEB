<?php
/** POST /api/auth/logout.php — Akhiri session. */
require_once __DIR__ . '/../helpers.php';

require_method('POST');
require_csrf();

$_SESSION = [];
if (ini_get('session.use_cookies')) {
    $p = session_get_cookie_params();
    setcookie(
        session_name(),
        '',
        time() - 42000,
        $p['path'],
        $p['domain'] ?? '',
        $p['secure'] ?? false,
        $p['httponly'] ?? true
    );
}
session_destroy();

ok(['loggedOut' => true]);
