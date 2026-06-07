# InfoLoker Portal Lowongan Kerja

Portal lowongan kerja berbasis web yang memungkinkan pengguna menelusuri, memfilter, dan melamar pekerjaan secara online. Dibangun menggunakan HTML, CSS, dan JavaScript murni tanpa framework tambahan.

InfoLoker adalah portal lowongan kerja berbasis web yang dibangun menggunakan HTML, CSS, dan JavaScript murni tanpa framework tambahan. Portal ini menampilkan 50 data lowongan dari berbagai perusahaan dan kategori di Indonesia, lengkap dengan fitur filter multi-kriteria yang memungkinkan pengguna menyaring lowongan berdasarkan lokasi, kategori, tipe pekerjaan, serta pencarian teks secara real-time. Seluruh data dikelola dalam satu file JSON dan dimuat secara dinamis menggunakan Fetch API, sementara fungsi-fungsi utilitas seperti sanitasi output, format tanggal, dan render komponen dipusatkan dalam satu file shared.js yang digunakan bersama di semua halaman.
Proyek ini terdiri dari empat halaman utama: beranda dengan hero section dan kategori populer, halaman daftar lowongan dengan sidebar filter, halaman detail pekerjaan yang memuat data secara dinamis dari URL parameter, serta halaman form lamaran dengan validasi input. Desain menggunakan sistem CSS custom properties yang konsisten di seluruh halaman, dengan palet warna biru LinkedIn sebagai identitas visual utama. Hasil akhirnya adalah portal yang ringan, responsif, dan dapat dijalankan hanya dengan local server tanpa dependensi eksternal apapun.
2

---

## Fitur

- **Daftar Lowongan**  Menampilkan 50 data lowongan kerja dalam tampilan grid yang responsif.
- **Filter Multi-Kriteria** Filter berdasarkan lokasi, kategori, tipe pekerjaan, dan pencarian teks secara real-time.
- **Detail Pekerjaan**  Halaman detail lengkap berisi deskripsi posisi, kualifikasi, informasi perusahaan, dan lowongan terkait.
- **Form Lamaran**  Formulir interaktif dengan validasi input dan konfirmasi submission.

---

## Struktur File

```
project/
├── assets/
│   └── logos/               # Logo perusahaan 
├── index.html               # Halaman beranda
├── listings.html            # Daftar dan filter lowongan
├── job-detail.html          # Detail pekerjaan
├── apply.html               # Form lamaran
├── shared.js                # Fungsi dan utilitas bersama
├── style.css                # style global theme terinspirasi linkedin
└── job_portal_50_data.json  # Data 50 lowongan kerja
```

---

## Format Data

Data lowongan tersimpan dalam file JSON dengan struktur berikut:

```json
{
  "id": 1,
  "title": "Frontend Developer",
  "company": "Gojek",
  "location": "Jakarta",
  "category": "IT",
  "type": "Full-time",
  "salary": "Rp5.000.000 - Rp8.000.000",
  "posted_date": "2026-04-19",
  "description": "Deskripsi posisi...",
  "requirements": ["Pengalaman relevan", "Komunikasi baik"]
}
```

---

## Teknologi

- HTML5
- CSS3 dengan Custom Properties
- JavaScript ES6+ (Vanilla, tanpa framework)
- JSON sebagai sumber data

---

## Catatan Pengembangan

- Logo perusahaan dapat ditambahkan di folder `assets/logos/[NamaPerusahaan].png`. Jika file tidak ditemukan, sistem akan menampilkan inisial nama perusahaan sebagai fallback.
- Untuk menambah data lowongan, cukup tambahkan objek baru ke dalam file `job_portal_50_data.json` dengan mengikuti format yang sudah ada.
- Seluruh output HTML diproses melalui fungsi `esc()` di `shared.js` untuk mencegah serangan XSS.
