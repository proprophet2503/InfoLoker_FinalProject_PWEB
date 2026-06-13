<?php
/**
 * GET /api/admin/application_detail.php?id=NN — Detail satu lamaran (4 tabel).
 * Hanya untuk HR pemilik perusahaan dari lowongan terkait.
 * Efek samping: bila status masih 'pending', otomatis jadi 'review'.
 */
require_once __DIR__ . '/../helpers.php';

$me  = require_role('perusahaan');
$cid = my_company_id((int) $me['id']);
if (!$cid) {
    fail('Profil perusahaan tidak ditemukan.', 403);
}

$id = (int) ($_GET['id'] ?? 0);
if ($id <= 0) {
    fail('ID lamaran tidak valid.');
}

$pdo = db();

$head = $pdo->prepare(
    'SELECT lm.id, lm.status, lm.no_referensi, lm.submitted_at, lm.catatan_hr,
            lo.judul, lo.lokasi, lo.tipe, lo.perusahaan_id, p.nama_perusahaan
       FROM lamaran lm
       JOIN lowongan lo            ON lo.id = lm.lowongan_id
       JOIN perusahaan_profiles p  ON p.id = lo.perusahaan_id
      WHERE lm.id = ? LIMIT 1'
);
$head->execute([$id]);
$row = $head->fetch();
if (!$row || (int) $row['perusahaan_id'] !== $cid) {
    fail('Lamaran tidak ditemukan.', 404);
}
unset($row['perusahaan_id']);

// Tandai sudah dibuka: pending -> review.
if ($row['status'] === 'pending') {
    $pdo->prepare("UPDATE lamaran SET status = 'review' WHERE id = ?")->execute([$id]);
    $row['status'] = 'review';
}

$one = static function (string $sql) use ($pdo, $id): array {
    $s = $pdo->prepare($sql);
    $s->execute([$id]);
    return $s->fetch() ?: [];
};

ok([
    'lamaran'            => $row,
    'data_pribadi'       => $one('SELECT nama, email, no_hp, kota, linkedin_url, portfolio_url FROM lamaran_data_pribadi WHERE lamaran_id = ?'),
    'latar_belakang'     => $one('SELECT pengalaman, pendidikan, universitas, jurusan, gaji_harapan, ketersediaan, work_pref, prev_company FROM lamaran_latar_belakang WHERE lamaran_id = ?'),
    'surat_dokumen'      => $one('SELECT cover_letter, cv_path, portfolio_path FROM lamaran_surat_dokumen WHERE lamaran_id = ?'),
    'pertanyaan_tambahan'=> $one('SELECT relokasi, lembur, referral, sumber_info, pesan_tambahan FROM lamaran_pertanyaan_tambahan WHERE lamaran_id = ?'),
]);
