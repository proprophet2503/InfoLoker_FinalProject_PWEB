-- ============================================================
-- InfoLoker Database Schema
-- Database : infoloker_db
-- Engine   : MySQL 8.x | InnoDB
-- Charset  : utf8mb4_unicode_ci
-- Backend  : PHP Native + PDO
-- Dibuat   : 2026-06-07
-- ============================================================

CREATE DATABASE IF NOT EXISTS infoloker_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE infoloker_db;

-- ============================================================
-- 1. TABEL USERS
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id          INT           NOT NULL AUTO_INCREMENT,
  nama        VARCHAR(100)  NOT NULL,
  email       VARCHAR(150)  NOT NULL,
  password    VARCHAR(255)  NOT NULL,
  role        ENUM('admin','pelamar','perusahaan') NOT NULL DEFAULT 'pelamar',
  no_hp       VARCHAR(20)   NULL,
  is_active   TINYINT(1)    NOT NULL DEFAULT 1,
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 2. TABEL PELAMAR_PROFILES (1:1 dengan users)
-- ============================================================
CREATE TABLE IF NOT EXISTS pelamar_profiles (
  id            INT           NOT NULL AUTO_INCREMENT,
  user_id       INT           NOT NULL,
  foto          VARCHAR(255)  NULL,
  headline      VARCHAR(255)  NULL,
  about         TEXT          NULL,
  kota          VARCHAR(100)  NULL,
  tanggal_lahir DATE          NULL,
  cv_path       VARCHAR(255)  NULL,
  linkedin_url  VARCHAR(255)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_user (user_id),
  CONSTRAINT fk_pp_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3. TABEL PERUSAHAAN_PROFILES (1:1 dengan users)
-- ============================================================
CREATE TABLE IF NOT EXISTS perusahaan_profiles (
  id               INT           NOT NULL AUTO_INCREMENT,
  user_id          INT           NOT NULL,
  nama_perusahaan  VARCHAR(150)  NOT NULL,
  logo             VARCHAR(255)  NULL,
  deskripsi        TEXT          NULL,
  industri         VARCHAR(100)  NULL,
  ukuran           VARCHAR(50)   NULL,
  website          VARCHAR(255)  NULL,
  kota             VARCHAR(100)  NULL,
  is_verified      TINYINT(1)    NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_user (user_id),
  CONSTRAINT fk_cp_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4. TABEL LOWONGAN
-- ============================================================
CREATE TABLE IF NOT EXISTS lowongan (
  id               INT           NOT NULL AUTO_INCREMENT,
  perusahaan_id    INT           NOT NULL,
  judul            VARCHAR(200)  NOT NULL,
  kategori         VARCHAR(100)  NOT NULL,
  tipe             ENUM('Full-time','Part-time','Remote','Freelance','Internship')
                                 NOT NULL DEFAULT 'Full-time',
  lokasi           VARCHAR(100)  NOT NULL,
  gaji_min         BIGINT        NULL,
  gaji_max         BIGINT        NULL,
  deskripsi        TEXT          NOT NULL,
  kualifikasi      TEXT          NULL COMMENT 'JSON array persyaratan',
  benefit          TEXT          NULL COMMENT 'JSON array benefit',
  deadline         DATE          NULL,
  jumlah_kebutuhan INT           NOT NULL DEFAULT 1,
  status           ENUM('pending','aktif','ditutup','ditolak')
                                 NOT NULL DEFAULT 'pending',
  views            INT           NOT NULL DEFAULT 0,
  posted_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_kategori   (kategori),
  INDEX idx_lokasi     (lokasi),
  INDEX idx_status     (status),
  INDEX idx_perusahaan (perusahaan_id),
  CONSTRAINT fk_lo_perusahaan FOREIGN KEY (perusahaan_id)
    REFERENCES perusahaan_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 5. TABEL LAMARAN
-- ============================================================
CREATE TABLE IF NOT EXISTS lamaran (
  id            INT           NOT NULL AUTO_INCREMENT,
  lowongan_id   INT           NOT NULL,
  pelamar_id    INT           NOT NULL,
  cover_letter  TEXT          NOT NULL,
  cv_path       VARCHAR(255)  NOT NULL,
  foto_path     VARCHAR(255)  NULL,
  skills        TEXT          NULL COMMENT 'JSON array skills',
  pengalaman    TEXT          NULL,
  sumber_info   VARCHAR(100)  NULL,
  status        ENUM('pending','review','diterima','ditolak')
                              NOT NULL DEFAULT 'pending',
  catatan_hr    TEXT          NULL,
  no_referensi  VARCHAR(50)   NOT NULL,
  submitted_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_referensi (no_referensi),
  UNIQUE KEY uq_lamaran   (lowongan_id, pelamar_id),
  INDEX idx_pelamar (pelamar_id),
  INDEX idx_status  (status),
  CONSTRAINT fk_lm_lowongan FOREIGN KEY (lowongan_id)
    REFERENCES lowongan(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_lm_pelamar  FOREIGN KEY (pelamar_id)
    REFERENCES users(id)    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 6. TABEL BOOKMARKS
-- ============================================================
CREATE TABLE IF NOT EXISTS bookmarks (
  id          INT       NOT NULL AUTO_INCREMENT,
  user_id     INT       NOT NULL,
  lowongan_id INT       NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_bookmark (user_id, lowongan_id),
  CONSTRAINT fk_bk_user     FOREIGN KEY (user_id)
    REFERENCES users(id)    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_bk_lowongan FOREIGN KEY (lowongan_id)
    REFERENCES lowongan(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7. TABEL SKILLS
-- ============================================================
CREATE TABLE IF NOT EXISTS skills (
  id          INT          NOT NULL AUTO_INCREMENT,
  pelamar_id  INT          NOT NULL,
  nama_skill  VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  INDEX idx_pelamar (pelamar_id),
  CONSTRAINT fk_sk_pelamar FOREIGN KEY (pelamar_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 8. TABEL PENGALAMAN_KERJA
-- ============================================================
CREATE TABLE IF NOT EXISTS pengalaman_kerja (
  id          INT          NOT NULL AUTO_INCREMENT,
  pelamar_id  INT          NOT NULL,
  posisi      VARCHAR(150) NOT NULL,
  perusahaan  VARCHAR(150) NOT NULL,
  mulai       DATE         NOT NULL,
  selesai     DATE         NULL COMMENT 'NULL = masih aktif bekerja',
  deskripsi   TEXT         NULL,
  PRIMARY KEY (id),
  INDEX idx_pelamar (pelamar_id),
  CONSTRAINT fk_px_pelamar FOREIGN KEY (pelamar_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 9. TABEL PENDIDIKAN
-- ============================================================
CREATE TABLE IF NOT EXISTS pendidikan (
  id           INT     NOT NULL AUTO_INCREMENT,
  pelamar_id   INT     NOT NULL,
  institusi    VARCHAR(200) NOT NULL,
  jurusan      VARCHAR(150) NULL,
  jenjang      ENUM('SMA','D3','S1','S2','S3') NOT NULL DEFAULT 'S1',
  tahun_masuk  YEAR    NOT NULL,
  tahun_lulus  YEAR    NULL COMMENT 'NULL = belum lulus',
  PRIMARY KEY (id),
  INDEX idx_pelamar (pelamar_id),
  CONSTRAINT fk_pd_pelamar FOREIGN KEY (pelamar_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- SEED: Akun admin default
-- GANTI hash dengan output password_hash('passwordmu', PASSWORD_BCRYPT) di PHP
-- Contoh: php -r "echo password_hash('Admin1234!', PASSWORD_BCRYPT);"
-- ============================================================
INSERT IGNORE INTO users (nama, email, password, role, is_active)
VALUES (
  'Admin InfoLoker',
  'admin@infoloker.id',
  '$2y$10$REPLACE_THIS_WITH_REAL_PASSWORD_HASH_BEFORE_DEPLOY',
  'admin',
  1
);
