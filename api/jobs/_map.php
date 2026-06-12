<?php
/**
 * _map.php — Ubah baris DB lowongan menjadi bentuk yang dipakai frontend.
 * Bentuk: id,title,company,location,category,type,salary,posted_date,
 *         description,requirements[]
 */

function rupiah(?int $n): string
{
    return 'Rp' . number_format((int) $n, 0, ',', '.');
}

function format_salary(?int $min, ?int $max): string
{
    if ($min === null && $max === null) {
        return 'Gaji dirahasiakan';
    }
    if ($min !== null && $max !== null && $min !== $max) {
        return rupiah($min) . ' - ' . rupiah($max);
    }
    return rupiah($max ?? $min);
}

function format_job(array $r): array
{
    $reqs = [];
    if (!empty($r['kualifikasi'])) {
        $reqs = array_values(array_filter(array_map('trim', preg_split('/\r\n|\r|\n/', $r['kualifikasi']))));
    }
    return [
        'id'           => (int) $r['id'],
        'title'        => $r['judul'],
        'company'      => $r['nama_perusahaan'],
        'location'     => $r['lokasi'],
        'category'     => $r['kategori'],
        'type'         => $r['tipe'],
        'salary'       => format_salary(
            isset($r['gaji_min']) ? (int) $r['gaji_min'] : null,
            isset($r['gaji_max']) ? (int) $r['gaji_max'] : null
        ),
        'posted_date'  => $r['posted_at'],
        'description'  => $r['deskripsi'],
        'requirements' => $reqs,
    ];
}
