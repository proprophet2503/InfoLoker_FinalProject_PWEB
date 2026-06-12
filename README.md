# InfoLoker — Portal Lowongan Kerja

Stack: **HTML + CSS + JavaScript (Bootstrap-friendly)** di frontend, **PHP Native + PDO**
di backend, **MySQL/MariaDB** sebagai database. Dirancang agar jalan di **InfinityFree**
(juga bisa di XAMPP untuk testing lokal).

Autentikasi memakai **PHP session** + `password_hash()` (BCRYPT). Tidak ada Node.js,
tidak ada Composer — semua fitur memakai ekstensi PHP bawaan (PDO MySQL) yang
tersedia di InfinityFree.

---

## Struktur

```
(htdocs root)
├── index.html, listings.html, job-detail.html, apply.html
├── login.html, register.html, account.html, dashboard.html
├── styles.css, shared.js, api.js, auth.js
├── assets/logos/*.png
├── api/                      ← backend PHP
│   ├── config.php            ← ISI kredensial DB di sini
│   ├── db.php, helpers.php, .htaccess
│   ├── auth/   register.php login.php logout.php me.php
│   ├── profile/ update.php password.php
│   ├── jobs/   list.php detail.php _map.php
│   └── lamaran/ create.php mine.php
├── uploads/                  ← file CV (otomatis dibuat)
└── database/
    ├── schema.sql            ← import ini ke phpMyAdmin
    └── generate_schema.py    ← (opsional) regen schema dari data
```

> **Penyebab error 403 sebelumnya:** semua file harus berada **langsung di dalam
> `htdocs`**, bukan di dalam subfolder seperti `htdocs/InfoLoker_FinalProject/`.
> Kalau ada subfolder, root domain tidak punya `index.html` sehingga muncul
> *403 Forbidden*. Lihat langkah 3.

---

## Cara Setup di InfinityFree

### 1. Buat akun & domain
Login ke InfinityFree → **Create Account** → pilih subdomain gratis
(mis. `namamu.infinityfreeapp.com`) atau pasang domain sendiri. Tunggu sampai akun aktif.

### 2. Buat database MySQL
vPanel → **MySQL Databases** → buat database baru (mis. nama `infoloker`).
Catat yang diberikan InfinityFree:

| Yang dicatat            | Contoh                          |
|-------------------------|---------------------------------|
| MySQL Host name         | `sql123.infinityfree.com`       |
| Database name           | `epiz_12345678_infoloker`       |
| Database user           | `epiz_12345678`                 |
| Database password       | (password yang kamu buat)       |

### 3. Upload file ke `htdocs`
vPanel → **Online File Manager** (atau FTP via FileZilla).
Masuk ke folder **`htdocs`**, lalu upload **ISI** folder project ini
(file `index.html`, folder `api`, `assets`, `database`, dst) **langsung ke `htdocs`**.

✅ Benar: `htdocs/index.html`, `htdocs/api/...`
❌ Salah: `htdocs/InfoLoker_FinalProject/index.html`  ← ini bikin 403

Folder `database/` boleh diupload, tapi tidak wajib (hanya berisi SQL).

### 4. Isi kredensial database
Edit **`api/config.php`** (lewat File Manager) sesuai langkah 2:

```php
define('DB_HOST', 'sql123.infinityfree.com');
define('DB_NAME', 'epiz_12345678_infoloker');
define('DB_USER', 'epiz_12345678');
define('DB_PASS', 'password_database_kamu');
```

Saat sudah siap produksi, set juga `APP_DEBUG` ke `false`.

### 5. Import tabel + data
vPanel → **phpMyAdmin** → pilih database `epiz_..._infoloker` →
tab **Import** → pilih file `database/schema.sql` → **Go**.

Ini membuat 9 tabel + data contoh (10 perusahaan, 50 lowongan, beberapa akun demo).
File ini **tidak** memakai `CREATE DATABASE` karena databasenya sudah dibuat di langkah 2.

### 6. Coba buka
Buka `https://namamu.infinityfreeapp.com/`.
- Klik **Daftar** (pojok kanan atas) untuk membuat akun → tersimpan di tabel `users`.
- **Masuk**, lalu klik nama kamu di pojok kanan atas → **Akun Saya** untuk
  mengubah nama / email / no HP / password.

---

## Akun Demo (setelah import schema.sql)

| Email                   | Password      | Role       |
|-------------------------|---------------|------------|
| `pelamar@infoloker.id`  | `Password123` | pelamar    |
| `admin@infoloker.id`    | `Password123` | admin      |
| `hr@gojek.id` dll.      | `Password123` | perusahaan |

> Ganti / hapus akun demo ini sebelum dipakai sungguhan.

---

## Testing Lokal (XAMPP)

1. Copy isi project ke `C:\xampp\htdocs\` (langsung ke root htdocs).
2. Di `api/config.php`: `DB_HOST=localhost`, `DB_USER=root`, `DB_PASS=''`,
   `DB_NAME=infoloker_db`.
3. Buat database `infoloker_db` di phpMyAdmin, lalu import `database/schema.sql`.
4. Buka `http://localhost/`.
   (`api.js` memakai path absolut `/api`, jadi taruh project di root `htdocs`.
   Jika harus di subfolder, ubah `API_BASE` di `api.js`.)

---

## Catatan Keamanan

- Password di-hash dengan `password_hash()` (BCRYPT), diverifikasi `password_verify()`.
- Semua query memakai **PDO prepared statements** (anti SQL injection).
- Proteksi **CSRF**: token per session dikirim via header `X-CSRF-Token`.
- Session di-`regenerate` setelah login (anti session fixation).
- `api/.htaccess` memblokir akses langsung ke file internal; `uploads/.htaccess`
  mematikan eksekusi PHP di folder upload.
- Set `APP_DEBUG = false` di `config.php` saat produksi.

---

## Regenerasi schema (opsional)

`database/schema.sql` sudah jadi. Bila ingin membuat ulang dari sumber data,
jalankan `python3 database/generate_schema.py` (butuh file data JSON yang sesuai).
