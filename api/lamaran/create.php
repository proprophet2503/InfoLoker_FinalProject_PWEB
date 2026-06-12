<?php
/** POST /api/lamaran/create.php — Kirim lamaran (pelamar yang login). */
require_once __DIR__ . '/../helpers.php';

require_method('POST');
require_csrf();
$me = require_role('pelamar');

$in         = input(); // untuk multipart, $_POST otomatis dipakai
$lowonganId = (int) ($in['lowongan_id'] ?? 0);
$cover      = trim((string) ($in['cover_letter'] ?? ''));
$pengalaman = trim((string) ($in['pengalaman'] ?? ''));
$sumber     = trim((string) ($in['sumber_info'] ?? ''));

// skills bisa berupa array (JSON) atau string dipisah baris/koma
$skillsRaw = $in['skills'] ?? '';
if (is_array($skillsRaw)) {
    $skills = implode("\n", array_map('trim', $skillsRaw));
} else {
    $skills = trim((string) $skillsRaw);
}

if ($lowonganId <= 0) {
    fail('Lowongan tidak valid.');
}

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

// Upload CV opsional.
$cvPath = null;
if (!empty($_FILES['cv']) && ($_FILES['cv']['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_OK) {
    $cvPath = save_upload($_FILES['cv'], 'cv', $me['id']);
}

$noRef = 'IL-' . date('ymd') . '-' . strtoupper(bin2hex(random_bytes(3)));

try {
    $ins = $pdo->prepare(
        'INSERT INTO lamaran
            (lowongan_id, pelamar_id, cover_letter, cv_path, skills, pengalaman, sumber_info, no_referensi)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    );
    $ins->execute([
        $lowonganId,
        $me['id'],
        ($cover !== '' ? $cover : null),
        $cvPath,
        ($skills !== '' ? $skills : null),
        ($pengalaman !== '' ? $pengalaman : null),
        ($sumber !== '' ? $sumber : null),
        $noRef,
    ]);
} catch (PDOException $e) {
    $msg = APP_DEBUG ? 'Gagal mengirim lamaran: ' . $e->getMessage() : 'Gagal mengirim lamaran. Coba lagi.';
    fail($msg, 500);
}

ok(['id' => (int) $pdo->lastInsertId(), 'no_referensi' => $noRef]);


/** Simpan file upload ke folder uploads, kembalikan path relatif. */
function save_upload(array $file, string $prefix, int $userId): ?string
{
    if (($file['size'] ?? 0) > MAX_UPLOAD_BYTES) {
        fail('Ukuran file melebihi batas 5 MB.', 413);
    }
    $ext = strtolower(pathinfo($file['name'] ?? '', PATHINFO_EXTENSION));
    $allowed = ['pdf', 'doc', 'docx'];
    if (!in_array($ext, $allowed, true)) {
        fail('Format CV harus PDF, DOC, atau DOCX.');
    }
    if (!is_dir(UPLOAD_DIR) && !mkdir(UPLOAD_DIR, 0755, true) && !is_dir(UPLOAD_DIR)) {
        fail('Server gagal menyiapkan folder upload.', 500);
    }
    $safe = $prefix . '_' . $userId . '_' . time() . '.' . $ext;
    $dest = UPLOAD_DIR . '/' . $safe;
    if (!move_uploaded_file($file['tmp_name'], $dest)) {
        fail('Gagal menyimpan file.', 500);
    }
    return 'uploads/' . $safe;
}
