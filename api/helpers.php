<?php
/**
 * helpers.php — Bootstrap bersama untuk semua endpoint:
 * session aman, respons JSON, parsing input, CSRF, dan guard autentikasi.
 *
 * Setiap endpoint cukup: require_once __DIR__ . '/../helpers.php';
 */
require_once __DIR__ . '/db.php';

// ---- Session aman ----------------------------------------------------
function start_session(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }
    $secure = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || (($_SERVER['SERVER_PORT'] ?? null) == 443);

    session_set_cookie_params([
        'lifetime' => 0,
        'path'     => '/',
        'httponly' => true,
        'secure'   => $secure,
        'samesite' => 'Lax',
    ]);
    session_name('IL_SESSION');
    session_start();
}

// ---- Respons JSON ----------------------------------------------------
function json_out($data, int $code = 200): void
{
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function ok($data = null, array $extra = []): void
{
    json_out(array_merge(['success' => true, 'data' => $data], $extra));
}

function fail(string $error, int $code = 400): void
{
    json_out(['success' => false, 'error' => $error], $code);
}

// ---- Input -----------------------------------------------------------
/** Ambil body: JSON (application/json) atau form (POST). */
function input(): array
{
    $ctype = $_SERVER['CONTENT_TYPE'] ?? '';
    if (stripos($ctype, 'application/json') !== false) {
        $raw = file_get_contents('php://input');
        $data = json_decode($raw, true);
        return is_array($data) ? $data : [];
    }
    return $_POST;
}

function field(array $src, string $key, $default = null)
{
    $v = $src[$key] ?? $default;
    return is_string($v) ? trim($v) : $v;
}

function require_method(string $method): void
{
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== $method) {
        fail('Metode tidak diizinkan.', 405);
    }
}

// ---- CSRF ------------------------------------------------------------
function csrf_token(): string
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function require_csrf(): void
{
    $sent = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? ($_POST['_csrf'] ?? '');
    if (!is_string($sent) || empty($_SESSION['csrf'])
        || !hash_equals($_SESSION['csrf'], $sent)) {
        fail('Token CSRF tidak valid. Muat ulang halaman.', 419);
    }
}

// ---- Auth guard ------------------------------------------------------
function current_user(): ?array
{
    if (empty($_SESSION['user_id'])) {
        return null;
    }
    $stmt = db()->prepare(
        'SELECT id, nama, email, role, no_hp, is_active
           FROM users WHERE id = ? LIMIT 1'
    );
    $stmt->execute([$_SESSION['user_id']]);
    $user = $stmt->fetch();
    return $user ?: null;
}

function require_login(): array
{
    $user = current_user();
    if (!$user) {
        fail('Anda harus login terlebih dahulu.', 401);
    }
    if ((int) $user['is_active'] !== 1) {
        fail('Akun Anda nonaktif.', 403);
    }
    return $user;
}

function require_role(string $role): array
{
    $user = require_login();
    if ($user['role'] !== $role) {
        fail('Anda tidak punya akses ke sumber daya ini.', 403);
    }
    return $user;
}

// ---- Validasi --------------------------------------------------------
function valid_email(string $email): bool
{
    return (bool) filter_var($email, FILTER_VALIDATE_EMAIL);
}

// Setiap endpoint memulai session otomatis.
start_session();
