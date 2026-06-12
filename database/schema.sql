-- =====================================================================
--  InfoLoker Database Schema  (InfinityFree-ready)
--  Engine  : MySQL / MariaDB | InnoDB | utf8mb4_unicode_ci
--  Backend : PHP Native + PDO
--
--  IMPORTANT (InfinityFree):
--   * Do NOT create the database here. Create it first in vPanel
--     ("MySQL Databases"), then import THIS file into that database
--     via phpMyAdmin. There is intentionally no CREATE DATABASE / USE.
--   * Demo login for every seeded account:  password = Password123
-- =====================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- 1. USERS ------------------------------------------------------------
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

-- 2. PELAMAR_PROFILES (1:1 users) -------------------------------------
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

-- 3. PERUSAHAAN_PROFILES (1:1 users) ----------------------------------
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

-- 4. LOWONGAN ---------------------------------------------------------
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
  kualifikasi      TEXT          NULL COMMENT 'Persyaratan, satu per baris',
  benefit          TEXT          NULL COMMENT 'Benefit, satu per baris',
  deadline         DATE          NULL,
  jumlah_kebutuhan INT           NOT NULL DEFAULT 1,
  status           ENUM('pending','aktif','ditutup','ditolak')
                                 NOT NULL DEFAULT 'aktif',
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

-- 5. LAMARAN ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS lamaran (
  id            INT           NOT NULL AUTO_INCREMENT,
  lowongan_id   INT           NOT NULL,
  pelamar_id    INT           NOT NULL,
  cover_letter  TEXT          NULL,
  cv_path       VARCHAR(255)  NULL,
  foto_path     VARCHAR(255)  NULL,
  skills        TEXT          NULL COMMENT 'Skills, satu per baris',
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

-- 6. BOOKMARKS --------------------------------------------------------
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

-- 7. SKILLS -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS skills (
  id          INT          NOT NULL AUTO_INCREMENT,
  pelamar_id  INT          NOT NULL,
  nama_skill  VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  INDEX idx_pelamar (pelamar_id),
  CONSTRAINT fk_sk_pelamar FOREIGN KEY (pelamar_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. PENGALAMAN_KERJA -------------------------------------------------
CREATE TABLE IF NOT EXISTS pengalaman_kerja (
  id          INT          NOT NULL AUTO_INCREMENT,
  pelamar_id  INT          NOT NULL,
  posisi      VARCHAR(150) NOT NULL,
  perusahaan  VARCHAR(150) NOT NULL,
  mulai       DATE         NOT NULL,
  selesai     DATE         NULL COMMENT 'NULL = masih aktif',
  deskripsi   TEXT         NULL,
  PRIMARY KEY (id),
  INDEX idx_pelamar (pelamar_id),
  CONSTRAINT fk_px_pelamar FOREIGN KEY (pelamar_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. PENDIDIKAN -------------------------------------------------------
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


-- =================== SEED DATA ===================

-- Demo password for ALL accounts below = Password123

INSERT IGNORE INTO users (id, nama, email, password, role) VALUES
  (1, 'Admin InfoLoker', 'admin@infoloker.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'admin');

INSERT IGNORE INTO users (id, nama, email, password, role) VALUES
  (2, 'Bank BCA Recruitment', 'hr@bankbca.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'perusahaan'),
  (3, 'Bank Mandiri Recruitment', 'hr@bankmandiri.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'perusahaan'),
  (4, 'Bukalapak Recruitment', 'hr@bukalapak.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'perusahaan'),
  (5, 'DANA Recruitment', 'hr@dana.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'perusahaan'),
  (6, 'Gojek Recruitment', 'hr@gojek.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'perusahaan'),
  (7, 'OVO Recruitment', 'hr@ovo.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'perusahaan'),
  (8, 'Shopee Recruitment', 'hr@shopee.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'perusahaan'),
  (9, 'Telkom Indonesia Recruitment', 'hr@telkomindonesia.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'perusahaan'),
  (10, 'Tokopedia Recruitment', 'hr@tokopedia.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'perusahaan'),
  (11, 'Traveloka Recruitment', 'hr@traveloka.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'perusahaan');

INSERT IGNORE INTO users (id, nama, email, password, role, no_hp) VALUES
  (12, 'Budi Pelamar', 'pelamar@infoloker.id', '$2y$10$dXZnKtr3YVB6Zylaw25M9OpfnzwOEFpqtIrNzZhKMrKy9BmuJL5CW', 'pelamar', '081234567890');

INSERT IGNORE INTO perusahaan_profiles (id, user_id, nama_perusahaan, logo, deskripsi, industri, is_verified) VALUES
  (1, 2, 'Bank BCA', 'Bank BCA.png', 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1),
  (2, 3, 'Bank Mandiri', 'Bank Mandiri.png', 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1),
  (3, 4, 'Bukalapak', 'Bukalapak.png', 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1),
  (4, 5, 'DANA', 'DANA.png', 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1),
  (5, 6, 'Gojek', 'Gojek.png', 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1),
  (6, 7, 'OVO', 'OVO.png', 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1),
  (7, 8, 'Shopee', 'Shopee.png', 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1),
  (8, 9, 'Telkom Indonesia', 'Telkom Indonesia.png', 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1),
  (9, 10, 'Tokopedia', 'Tokopedia.png', 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1),
  (10, 11, 'Traveloka', 'Traveloka.png', 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1);

INSERT IGNORE INTO pelamar_profiles (user_id, headline, kota) VALUES (12, 'Fresh Graduate', 'Jakarta');

INSERT IGNORE INTO lowongan
  (id, perusahaan_id, judul, kategori, tipe, lokasi, gaji_min, gaji_max, deskripsi, kualifikasi, posted_at, status)
VALUES
  (1, 5, 'Frontend Developer', 'IT', 'Full-time', 'Jakarta', 5000000, 8000000, 'Posisi Frontend Developer di Gojek untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-19', 'aktif'),
  (2, 5, 'Backend Developer', 'IT', 'Freelance', 'Bandung', 6000000, 9000000, 'Posisi Backend Developer di Gojek untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-18', 'aktif'),
  (3, 5, 'UI/UX Designer', 'Design', 'Full-time', 'Surabaya', 7000000, 10000000, 'Posisi UI/UX Designer di Gojek untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-17', 'aktif'),
  (4, 5, 'Digital Marketing Specialist', 'Marketing', 'Freelance', 'Yogyakarta', 8000000, 11000000, 'Posisi Digital Marketing Specialist di Gojek untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-16', 'aktif'),
  (5, 5, 'Data Analyst', 'Data', 'Full-time', 'Semarang', 9000000, 12000000, 'Posisi Data Analyst di Gojek untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-15', 'aktif'),
  (6, 9, 'Backend Developer', 'IT', 'Full-time', 'Surabaya', 5000000, 8000000, 'Posisi Backend Developer di Tokopedia untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-14', 'aktif'),
  (7, 9, 'UI/UX Designer', 'Design', 'Freelance', 'Yogyakarta', 6000000, 9000000, 'Posisi UI/UX Designer di Tokopedia untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-13', 'aktif'),
  (8, 9, 'Digital Marketing Specialist', 'Marketing', 'Full-time', 'Semarang', 7000000, 10000000, 'Posisi Digital Marketing Specialist di Tokopedia untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-12', 'aktif'),
  (9, 9, 'Data Analyst', 'Data', 'Freelance', 'Malang', 8000000, 11000000, 'Posisi Data Analyst di Tokopedia untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-11', 'aktif'),
  (10, 9, 'Product Manager', 'Management', 'Full-time', 'Denpasar', 9000000, 12000000, 'Posisi Product Manager di Tokopedia untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-10', 'aktif'),
  (11, 7, 'UI/UX Designer', 'Design', 'Full-time', 'Semarang', 5000000, 8000000, 'Posisi UI/UX Designer di Shopee untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-09', 'aktif'),
  (12, 7, 'Digital Marketing Specialist', 'Marketing', 'Freelance', 'Malang', 6000000, 9000000, 'Posisi Digital Marketing Specialist di Shopee untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-08', 'aktif'),
  (13, 7, 'Data Analyst', 'Data', 'Full-time', 'Denpasar', 7000000, 10000000, 'Posisi Data Analyst di Shopee untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-07', 'aktif'),
  (14, 7, 'Product Manager', 'Management', 'Freelance', 'Medan', 8000000, 11000000, 'Posisi Product Manager di Shopee untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-06', 'aktif'),
  (15, 7, 'Finance Analyst', 'Finance', 'Full-time', 'Makassar', 9000000, 12000000, 'Posisi Finance Analyst di Shopee untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-20', 'aktif'),
  (16, 3, 'Digital Marketing Specialist', 'Marketing', 'Full-time', 'Denpasar', 5000000, 8000000, 'Posisi Digital Marketing Specialist di Bukalapak untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-19', 'aktif'),
  (17, 3, 'Data Analyst', 'Data', 'Freelance', 'Medan', 6000000, 9000000, 'Posisi Data Analyst di Bukalapak untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-18', 'aktif'),
  (18, 3, 'Product Manager', 'Management', 'Full-time', 'Makassar', 7000000, 10000000, 'Posisi Product Manager di Bukalapak untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-17', 'aktif'),
  (19, 3, 'Finance Analyst', 'Finance', 'Freelance', 'Balikpapan', 8000000, 11000000, 'Posisi Finance Analyst di Bukalapak untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-16', 'aktif'),
  (20, 3, 'HR Specialist', 'HR', 'Full-time', 'Jakarta', 9000000, 12000000, 'Posisi HR Specialist di Bukalapak untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-15', 'aktif'),
  (21, 10, 'Data Analyst', 'Data', 'Full-time', 'Makassar', 5000000, 8000000, 'Posisi Data Analyst di Traveloka untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-14', 'aktif'),
  (22, 10, 'Product Manager', 'Management', 'Freelance', 'Balikpapan', 6000000, 9000000, 'Posisi Product Manager di Traveloka untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-13', 'aktif'),
  (23, 10, 'Finance Analyst', 'Finance', 'Full-time', 'Jakarta', 7000000, 10000000, 'Posisi Finance Analyst di Traveloka untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-12', 'aktif'),
  (24, 10, 'HR Specialist', 'HR', 'Freelance', 'Bandung', 8000000, 11000000, 'Posisi HR Specialist di Traveloka untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-11', 'aktif'),
  (25, 10, 'Operations Officer', 'Operations', 'Full-time', 'Surabaya', 9000000, 12000000, 'Posisi Operations Officer di Traveloka untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-10', 'aktif'),
  (26, 6, 'Product Manager', 'Management', 'Full-time', 'Jakarta', 5000000, 8000000, 'Posisi Product Manager di OVO untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-09', 'aktif'),
  (27, 6, 'Finance Analyst', 'Finance', 'Freelance', 'Bandung', 6000000, 9000000, 'Posisi Finance Analyst di OVO untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-08', 'aktif'),
  (28, 6, 'HR Specialist', 'HR', 'Full-time', 'Surabaya', 7000000, 10000000, 'Posisi HR Specialist di OVO untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-07', 'aktif'),
  (29, 6, 'Operations Officer', 'Operations', 'Freelance', 'Yogyakarta', 8000000, 11000000, 'Posisi Operations Officer di OVO untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-06', 'aktif'),
  (30, 6, 'Customer Support', 'Support', 'Full-time', 'Semarang', 9000000, 12000000, 'Posisi Customer Support di OVO untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-20', 'aktif'),
  (31, 8, 'Finance Analyst', 'Finance', 'Full-time', 'Surabaya', 5000000, 8000000, 'Posisi Finance Analyst di Telkom Indonesia untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-19', 'aktif'),
  (32, 8, 'HR Specialist', 'HR', 'Freelance', 'Yogyakarta', 6000000, 9000000, 'Posisi HR Specialist di Telkom Indonesia untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-18', 'aktif'),
  (33, 8, 'Operations Officer', 'Operations', 'Full-time', 'Semarang', 7000000, 10000000, 'Posisi Operations Officer di Telkom Indonesia untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-17', 'aktif'),
  (34, 8, 'Customer Support', 'Support', 'Freelance', 'Malang', 8000000, 11000000, 'Posisi Customer Support di Telkom Indonesia untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-16', 'aktif'),
  (35, 8, 'Frontend Developer', 'IT', 'Full-time', 'Denpasar', 9000000, 12000000, 'Posisi Frontend Developer di Telkom Indonesia untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-15', 'aktif'),
  (36, 1, 'HR Specialist', 'HR', 'Full-time', 'Semarang', 5000000, 8000000, 'Posisi HR Specialist di Bank BCA untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-14', 'aktif'),
  (37, 1, 'Operations Officer', 'Operations', 'Freelance', 'Malang', 6000000, 9000000, 'Posisi Operations Officer di Bank BCA untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-13', 'aktif'),
  (38, 1, 'Customer Support', 'Support', 'Full-time', 'Denpasar', 7000000, 10000000, 'Posisi Customer Support di Bank BCA untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-12', 'aktif'),
  (39, 1, 'Frontend Developer', 'IT', 'Freelance', 'Medan', 8000000, 11000000, 'Posisi Frontend Developer di Bank BCA untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-11', 'aktif'),
  (40, 1, 'Backend Developer', 'IT', 'Full-time', 'Makassar', 9000000, 12000000, 'Posisi Backend Developer di Bank BCA untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-10', 'aktif'),
  (41, 2, 'Operations Officer', 'Operations', 'Full-time', 'Denpasar', 5000000, 8000000, 'Posisi Operations Officer di Bank Mandiri untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-09', 'aktif'),
  (42, 2, 'Customer Support', 'Support', 'Freelance', 'Medan', 6000000, 9000000, 'Posisi Customer Support di Bank Mandiri untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-08', 'aktif'),
  (43, 2, 'Frontend Developer', 'IT', 'Full-time', 'Makassar', 7000000, 10000000, 'Posisi Frontend Developer di Bank Mandiri untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-07', 'aktif'),
  (44, 2, 'Backend Developer', 'IT', 'Freelance', 'Balikpapan', 8000000, 11000000, 'Posisi Backend Developer di Bank Mandiri untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-06', 'aktif'),
  (45, 2, 'UI/UX Designer', 'Design', 'Full-time', 'Jakarta', 9000000, 12000000, 'Posisi UI/UX Designer di Bank Mandiri untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-20', 'aktif'),
  (46, 4, 'Customer Support', 'Support', 'Full-time', 'Makassar', 5000000, 8000000, 'Posisi Customer Support di DANA untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-19', 'aktif'),
  (47, 4, 'Frontend Developer', 'IT', 'Freelance', 'Balikpapan', 6000000, 9000000, 'Posisi Frontend Developer di DANA untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-18', 'aktif'),
  (48, 4, 'Backend Developer', 'IT', 'Full-time', 'Jakarta', 7000000, 10000000, 'Posisi Backend Developer di DANA untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-17', 'aktif'),
  (49, 4, 'UI/UX Designer', 'Design', 'Freelance', 'Bandung', 8000000, 11000000, 'Posisi UI/UX Designer di DANA untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-16', 'aktif'),
  (50, 4, 'Digital Marketing Specialist', 'Marketing', 'Full-time', 'Surabaya', 9000000, 12000000, 'Posisi Digital Marketing Specialist di DANA untuk mendukung operasional dan pengembangan bisnis.', 'Pengalaman relevan
Komunikasi baik
Problem solving', '2026-04-15', 'aktif');

SET FOREIGN_KEY_CHECKS = 1;
