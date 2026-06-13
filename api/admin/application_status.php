<?php
/**
 * POST /api/admin/application_status.php — HR terima/tolak lamaran perusahaannya.
 * Body JSON: { id, status: 'diterima'|'ditolak'|'review', catatan_hr? }
 */
require_once __DIR__ . '/../helpers.php';

require_method('POST');
require_csrf();
$me  = require_role('perusahaan');
$cid = my_company_id((int) $me['id']);
if (!$cid) {
    fail('Profil perusahaan tidak ditemukan.', 403);
}

$in      = input();
$id      = (int) ($in['id'] ?? 0);
$status  = trim((string) ($in['status'] ?? ''));
$catatan = trim((string) ($in['catatan_hr'] ?? ''));

$allowed = ['review', 'diterima', 'ditolak'];
if ($id <= 0 || !in_array($status, $allowed, true)) {
    fail('Data tidak valid.');
}

$pdo = db();

// Pastikan lamaran ini milik perusahaan HR yang login.
$chk = $pdo->prepare(
    'SELECT lm.id
       FROM lamaran lm
       JOIN lowongan lo ON lo.id = lm.lowongan_id
      WHERE lm.id = ? AND lo.perusahaan_id = ? LIMIT 1'
);
$chk->execute([$id, $cid]);
if (!$chk->fetch()) {
    fail('Lamaran tidak ditemukan.', 404);
}

$upd = $pdo->prepare('UPDATE lamaran SET status = ?, catatan_hr = ? WHERE id = ?');
$upd->execute([$status, ($catatan !== '' ? $catatan : null), $id]);

ok(['id' => $id, 'status' => $status]);
