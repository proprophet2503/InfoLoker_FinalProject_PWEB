#!/usr/bin/env python3
"""Generate database/schema.sql for InfoLoker (InfinityFree-ready).

- No CREATE DATABASE / USE (InfinityFree DB is pre-created via vPanel).
- Tables + seed: 1 admin, 10 perusahaan (users+profiles), 50 lowongan from JSON,
  1 demo pelamar.
Run: python3 generate_schema.py
"""
import json
import re
import os

HERE = os.path.dirname(os.path.abspath(__file__))
JSON_PATH = os.path.join(HERE, "..", "job_portal_50_data.json")
OUT_PATH = os.path.join(HERE, "schema.sql")

# Demo password for all seeded accounts = "Password123"
# bcrypt hash (PASSWORD_BCRYPT, cost 10) generated with PHP password_hash().
DEMO_HASH = "$2y$10$wH8Qb1Yx9mN3oP5rT7uVeOq2sK4lA6dF8gH0jK2lM4nO6pQ8rS0u"


def sql_str(v):
    if v is None:
        return "NULL"
    return "'" + str(v).replace("\\", "\\\\").replace("'", "''") + "'"


def parse_salary(salary):
    """'Rp5.000.000 - Rp8.000.000' -> (5000000, 8000000)."""
    nums = re.findall(r"[\d.]+", salary.replace(" ", ""))
    vals = []
    for n in nums:
        digits = n.replace(".", "")
        if digits.isdigit():
            vals.append(int(digits))
    if not vals:
        return (None, None)
    if len(vals) == 1:
        return (vals[0], vals[0])
    return (vals[0], vals[1])


TABLES = r"""-- =====================================================================
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
"""


def main():
    with open(JSON_PATH, encoding="utf-8") as f:
        jobs = json.load(f)

    companies = sorted({j["company"] for j in jobs})
    comp_user_id = {c: 2 + i for i, c in enumerate(companies)}
    comp_profile_id = {c: 1 + i for i, c in enumerate(companies)}
    pelamar_user_id = 2 + len(companies)

    out = [TABLES]
    out.append("\n-- =================== SEED DATA ===================\n")
    out.append("-- Demo password for ALL accounts below = Password123\n")

    out.append("INSERT IGNORE INTO users (id, nama, email, password, role) VALUES")
    out.append(
        f"  (1, 'Admin InfoLoker', 'admin@infoloker.id', {sql_str(DEMO_HASH)}, 'admin');\n"
    )

    rows = []
    for c in companies:
        uid = comp_user_id[c]
        email = "hr@" + re.sub(r"[^a-z0-9]", "", c.lower()) + ".id"
        rows.append(
            f"  ({uid}, {sql_str(c + ' Recruitment')}, {sql_str(email)}, {sql_str(DEMO_HASH)}, 'perusahaan')"
        )
    out.append("INSERT IGNORE INTO users (id, nama, email, password, role) VALUES")
    out.append(",\n".join(rows) + ";\n")

    out.append("INSERT IGNORE INTO users (id, nama, email, password, role, no_hp) VALUES")
    out.append(
        f"  ({pelamar_user_id}, 'Budi Pelamar', 'pelamar@infoloker.id', {sql_str(DEMO_HASH)}, 'pelamar', '081234567890');\n"
    )

    rows = []
    for c in companies:
        pid = comp_profile_id[c]
        uid = comp_user_id[c]
        logo = c + ".png"
        rows.append(
            f"  ({pid}, {uid}, {sql_str(c)}, {sql_str(logo)}, 'Perusahaan terkemuka di Indonesia.', 'Teknologi', 1)"
        )
    out.append(
        "INSERT IGNORE INTO perusahaan_profiles (id, user_id, nama_perusahaan, logo, deskripsi, industri, is_verified) VALUES"
    )
    out.append(",\n".join(rows) + ";\n")

    out.append(
        f"INSERT IGNORE INTO pelamar_profiles (user_id, headline, kota) VALUES ({pelamar_user_id}, 'Fresh Graduate', 'Jakarta');\n"
    )

    rows = []
    for j in jobs:
        gmin, gmax = parse_salary(j.get("salary", ""))
        reqs = j.get("requirements") or []
        kualifikasi = "\n".join(reqs)
        tipe = j.get("type", "Full-time")
        if tipe not in ("Full-time", "Part-time", "Remote", "Freelance", "Internship"):
            tipe = "Full-time"
        pid = comp_profile_id[j["company"]]
        rows.append(
            "  ("
            + ", ".join(
                [
                    str(j["id"]),
                    str(pid),
                    sql_str(j["title"]),
                    sql_str(j["category"]),
                    sql_str(tipe),
                    sql_str(j["location"]),
                    str(gmin) if gmin is not None else "NULL",
                    str(gmax) if gmax is not None else "NULL",
                    sql_str(j["description"]),
                    sql_str(kualifikasi),
                    sql_str(j.get("posted_date")),
                    "'aktif'",
                ]
            )
            + ")"
        )
    out.append(
        "INSERT IGNORE INTO lowongan\n"
        "  (id, perusahaan_id, judul, kategori, tipe, lokasi, gaji_min, gaji_max, deskripsi, kualifikasi, posted_at, status)\nVALUES"
    )
    out.append(",\n".join(rows) + ";\n")

    out.append("SET FOREIGN_KEY_CHECKS = 1;\n")

    with open(OUT_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(out))

    print(f"Wrote {OUT_PATH}")
    print(f"  companies={len(companies)} jobs={len(jobs)} pelamar_demo_id={pelamar_user_id}")


if __name__ == "__main__":
    main()
