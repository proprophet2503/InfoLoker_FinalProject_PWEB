<?php
/**
 * db.php — Koneksi PDO tunggal (singleton) ke MySQL.
 * Dipakai oleh semua endpoint melalui helpers.php.
 */
require_once __DIR__ . '/config.php';

function db(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $dsn = sprintf(
        'mysql:host=%s;dbname=%s;charset=%s',
        DB_HOST,
        DB_NAME,
        DB_CHARSET
    );

    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];

    try {
        $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
    } catch (PDOException $e) {
        http_response_code(500);
        header('Content-Type: application/json');
        $msg = APP_DEBUG
            ? 'Koneksi database gagal: ' . $e->getMessage()
            : 'Koneksi database gagal. Coba lagi nanti.';
        echo json_encode(['success' => false, 'error' => $msg]);
        exit;
    }

    return $pdo;
}
