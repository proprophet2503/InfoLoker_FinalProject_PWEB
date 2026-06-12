<?php
/**
 * config.php — InfoLoker konfigurasi pusat.
 *
 * ISI BAGIAN INI dengan kredensial dari vPanel InfinityFree
 * (menu "MySQL Databases"). Contoh nilai InfinityFree:
 *   DB_HOST = "sqlXXX.infinityfree.com"   (BUKAN "localhost")
 *   DB_NAME = "epiz_12345678_infoloker"
 *   DB_USER = "epiz_12345678"
 *   DB_PASS = "passwordMySQLkamu"
 *
 * Untuk testing lokal (XAMPP) biasanya:
 *   DB_HOST="localhost"  DB_NAME="infoloker_db"  DB_USER="root"  DB_PASS=""
 */

// ---- Kredensial database (WAJIB DIISI) ------------------------------
define('DB_HOST', 'sqlXXX.infinityfree.com');
define('DB_NAME', 'epiz_XXXXXXXX_infoloker');
define('DB_USER', 'epiz_XXXXXXXX');
define('DB_PASS', 'GANTI_DENGAN_PASSWORD_DB');
define('DB_CHARSET', 'utf8mb4');

// ---- Pengaturan aplikasi --------------------------------------------
// Tampilkan error PHP saat pengembangan. Set false sebelum produksi.
define('APP_DEBUG', true);

// Folder upload (CV / foto). Dibuat otomatis bila belum ada.
define('UPLOAD_DIR', __DIR__ . '/../uploads');
define('MAX_UPLOAD_BYTES', 5 * 1024 * 1024); // 5 MB

// ---- Error reporting -------------------------------------------------
if (APP_DEBUG) {
    error_reporting(E_ALL);
    ini_set('display_errors', '1');
} else {
    error_reporting(0);
    ini_set('display_errors', '0');
}
