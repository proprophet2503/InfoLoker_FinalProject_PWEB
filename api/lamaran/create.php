<?php
/**
 * POST /api/lamaran/create.php — Kirim lamaran (pelamar yang login).
 *
 * Data input pelamar disimpan ke 4 tabel anak sesuai 4 bagian formulir:
 *   lamaran_data_pribadi, lamaran_latar_belakang,
 *   lamaran_surat_dokumen, lamaran_pertanyaan_tambahan.
 * File CV dan Portfolio disimpan ke folder uploads beserta path-nya.
 */
require_once __DIR__ . '/../helpers.php';

require_method('POST');
require_csrf();
$me = require_role('pelamar');

$in         = input(); // multipart -> $_POST otomatis dipakai
$lowonganId = (int) ($in['lowongan_id'] ?? 0);

if ($lowonganId <= 0) {
    fail('Lowongan tidak valid.');
}

// --- Bagian 1: Data Pribadi -----------------------------------------
$nama         = trim((string) ($in['nama'] ?? $me['nama']));
$email        = trim((string) ($in['email'] ?? $me['email']));
$noHp         = trim((string) ($in['no_hp'] ?? ''));
$kota         = trim((string) ($in['kota'] ?? ''));
$linkedin     = trim((string) ($in['linkedin_url'] ?? ''));
$portfolioUrl = trim((string) ($in['portfolio_url'] ?? ''));

if ($nama === '' || $email === '') {
    fail('Nama dan email wajib diisi.');
}
if (!valid_email($email)) {
    fail('Format email tidak valid.');
}

// --- Bagian 2: Latar Belakang Profesional ---------------------------
$pengalaman  = trim((string) ($in['pengalaman'] ?? ''));
$pendidikan  = trim((string) ($in['pendidikan'] ?? ''));
$universitas = trim((string) ($in['universitas'] ?? ''));
$jurusan     = trim((string) ($in['jurusan'] ?? ''));
$gajiHarapan = trim((string) ($in['gaji_harapan'] ?? ''));
$ketersediaan = trim((string) ($in['ketersediaan'] ?? ''));
$workPref    = trim((string) ($in['work_pref'] ?? ''));
$prevCompany = trim((string) ($in['prev_company'] ?? ''));

// --- Bagian 3: Surat & Dokumen --------------------------------------
$cover = trim((string) ($in['cover_letter'] ?? ''));

// --- Bagian 4: Pertanyaan Tambahan ----------------------------------
$relokasi   = !empty($in['relokasi']) ? 1 : 0;
$lembur     = !empty($in['lembur']) ? 1 : 0;
$referral   = !empty($in['referral']) ? 1 : 0;
$sumber     = trim((string) ($in['sumber_info'] ?? ''));
$pesan      = trim((string) ($in['pesan_tambahan'] ?? ''));

$pdo = db();

// Pastikan lowongan ada & aktif.
$chk = $pdo->prepare('SELECT id FROM lowongan WHERE id = ? AND status = ? LIMIT 1');
$chk->execute([$lowonganId, 'aktif']);
if (!$chk->fetch()) {
    fail('Lowongan tidak ditemukan atau sudah ditutup.', 404);
}

// Cegah lamaran ganda.
$dup = $pdo->prepare('SELECT id FROM lamaran WHERE lowongan_id = ? AND pelamar_id = ? LIMIT 1');
$dup->execute([$lowonganId, $me['id']]);
if ($dup->fetch()) {
    fail('Anda sudah melamar lowongan ini.', 409);
}

// Upload CV (opsional) & Portfolio (opsional) — keduanya disimpan + path.
$cvPath = null;
if (!empty($_FILES['cv']) && ($_FILES['cv']['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_OK) {
    $cvPath = save_upload($_FILES['cv'], 'cv', $me['id'], ['pdf', 'doc', 'docx']);
}
$portfolioPath = null;
if (!empty($_FILES['portfolio']) && ($_FILES['portfolio']['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_OK) {
    $portfolioPath = save_upload($_FILES['portfolio'], 'porto', $me['id'], ['pdf', 'zip', 'rar', 'pptx']);
}

$noRef = 'IL-' . date('ymd') . '-' . strtoupper(bin2hex(random_bytes(3)));

$nz = static fn(string $v): ?string => ($v !== '' ? $v : null);

try {
    $pdo->beginTransaction();

    // Record induk.
    $ins = $pdo->prepare(
        'INSERT INTO lamaran (lowongan_id, pelamar_id, no_referensi) VALUES (?, ?, ?)'
    );
    $ins->execute([$lowonganId, $me['id'], $noRef]);
    $lamaranId = (int) $pdo->lastInsertId();

    // 5a. Data pribadi.
    $pdo->prepare(
        'INSERT INTO lamaran_data_pribadi
            (lamaran_id, nama, email, no_hp, kota, linkedin_url, portfolio_url)
         VALUES (?, ?, ?, ?, ?, ?, ?)'
    )->execute([$lamaranId, $nama, $email, $nz($noHp), $nz($kota), $nz($linkedin), $nz($portfolioUrl)]);

    // 5b. Latar belakang.
    $pdo->prepare(
        'INSERT INTO lamaran_latar_belakang
            (lamaran_id, pengalaman, pendidikan, universitas, jurusan,
             gaji_harapan, ketersediaan, work_pref, prev_company)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    )->execute([
        $lamaranId, $nz($pengalaman), $nz($pendidikan), $nz($universitas), $nz($jurusan),
        $nz($gajiHarapan), $nz($ketersediaan), $nz($workPref), $nz($prevCompany),
    ]);

    // 5c. Surat & dokumen.
    $pdo->prepare(
        'INSERT INTO lamaran_surat_dokumen
            (lamaran_id, cover_letter, cv_path, portfolio_path)
         VALUES (?, ?, ?, ?)'
    )->execute([$lamaranId, $nz($cover), $cvPath, $portfolioPath]);

    // 5d. Pertanyaan tambahan.
    $pdo->prepare(
        'INSERT INTO lamaran_pertanyaan_tambahan
            (lamaran_id, relokasi, lembur, referral, sumber_info, pesan_tambahan)
         VALUES (?, ?, ?, ?, ?, ?)'
    )->execute([$lamaranId, $relokasi, $lembur, $referral, $nz($sumber), $nz($pesan)]);

    $pdo->commit();
} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    $msg = APP_DEBUG ? 'Gagal mengirim lamaran: ' . $e->getMessage() : 'Gagal mengirim lamaran. Coba lagi.';
    fail($msg, 500);
}

ok(['id' => $lamaranId, 'no_referensi' => $noRef]);


/** Simpan file upload ke folder uploads, kembalikan path relatif. */
function save_upload(array $file, string $prefix, int $userId, array $allowed): ?string
{
    if (($file['size'] ?? 0) > MAX_UPLOAD_BYTES) {
        fail('Ukuran file melebihi batas 5 MB.', 413);
    }
    $ext = strtolower(pathinfo($file['name'] ?? '', PATHINFO_EXTENSION));
    if (!in_array($ext, $allowed, true)) {
        fail('Format file ' . $prefix . ' tidak diizinkan. Diperbolehkan: ' . implode(', ', $allowed) . '.');
    }
    if (!is_dir(UPLOAD_DIR) && !mkdir(UPLOAD_DIR, 0755, true) && !is_dir(UPLOAD_DIR)) {
        fail('Server gagal menyiapkan folder upload.', 500);
    }
    $safe = $prefix . '_' . $userId . '_' . time() . '_' . bin2hex(random_bytes(3)) . '.' . $ext;
    $dest = UPLOAD_DIR . '/' . $safe;
    if (!move_uploaded_file($file['tmp_name'], $dest)) {
        fail('Gagal menyimpan file.', 500);
    }
    return 'uploads/' . $safe;
}
