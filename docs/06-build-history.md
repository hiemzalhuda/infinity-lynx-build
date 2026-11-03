# Riwayat build #1–#12 (ringkas, dengan pelajaran)

Semua build GAPPS mulai #4. Semua tanpa make clean, `out/` dipertahankan.

| # | Hasil | Penyebab / perbaikan |
| --- | --- | --- |
| 1 | Mati sebelum mka | Lunch abort di sync kernel (branch kernel malformed) di bawah `set -e`. Perbaikan: `set +e` di sekitar source/lunch. Jalan pintas `SKIP_KERNEL_SYNC=true` di sini menjadi akar #12. |
| 2 | Gagal Soong bootstrap | 31 modul `<nama>.google.contributions.prebuilt` undefined (`build/soong/Android.bp:140`). |
| 3 | Gagal Soong | Duplikat `DeviceIntelligenceNetworkPrebuiltAstrea` (GMS vs device). Perbaikan: `PRODUCT_MODULE_BUILD_FROM_SOURCE:= true` di product file. |
| 4 | Gagal Soong | Sertifikat di luar tree ditolak Soong. Perbaikan: salin kunci ke dalam tree (`vendor/infinity/security/`) + ubah baris cert ke path relatif. |
| 5 | Gagal OOM (137) | OOM di Soong bootstrap. Perbaikan cert #4 terbukti bekerja. |
| 6 | Gagal artifact-path | 4 file GMS di `system/`. Perbaikan: allowlist 4 path di product file (mekanisme resmi). |
| 7 | Gagal Kati | Duplikat overlay GlanceableHub (gs201 vs vendor/extras). |
| 8 | Dihentikan bersih | ~30 menit Soong, diganti #9 (-j2, metode .bak + `.disabled`). |
| 9 | Gagal artifact-path | `privapp-permissions-google.xml`, `bootanimation.zip`. Perbaikan: allowlist +2 path (total 6). |
| 10 | Gagal Ninja | `sdk_sandbox.x509.pem` hilang. Pelajaran: enumerasi semua referensi graph dulu. |
| 11 | Gagal Ninja | `bluetooth.x509.pem` hilang (rantai via `run_apex_sepolicy_tests`). |
| 12 | Gagal Ninja | `gzvm.ko` hilang — akar: kernel prebuilt tidak pernah ada (lihat `03-kernel-build.md`). Soong ~7h14m, Kati lolos, Ninja gagal penjadwalan, nol objek compile. |

## Setelah #12

- Kernel dibangun dari source, diverifikasi 262/262 + dtbo + boot.img
  (lihat `03-kernel-build.md`).
- Direct ninja pada plan #12 gagal dua kali: (1) pool `highmem_pool` tak
  dikenal (file `-f` salah — harus combined), (2) bacon gagal karena plan
  basi: tidak ada edge `boot.img`/`otapackage`, ZIP final tanpa prerequisite
  (penyebab: `build_ota_package` false saat plan dibuat karena
  `TARGET_NO_KERNEL=true` + `INSTALLED_BOOTIMAGE_TARGET` kosong).
- Regenerasi Kati-only 2026-11-03 16:01 WIB sukses, plan baru terverifikasi,
  direct ninja `-j2 bacon` berjalan sejak 16:08 WIB (lihat
  `04-kati-only-regeneration.md`).

## Pelajaran yang dicatat

- Bila Ninja gagal karena file hilang, enumerasi **semua** referensi dari
  graph sebelum restart — Ninja hanya melaporkan yang pertama.
- File dummy dan spoofing timestamp dilarang (instruksi user 2026-11-03 08:18).
- Prosedur "bypass Soong & injeksi file" yang ditempel user 2026-11-03 08:15
  **tidak diadopsi**: premisnya salah (Soong re-analysis tidak dipicu
  timestamp direktori; `mka`/`soong_ui` selalu menjalankan `soong_build`).
- Fakta empiris: walau hanya file yang ditambah tanpa edit `.bp`/`.mk`,
  `mka` tetap memutar ulang analisis Soong penuh (~6h42m–7h20m). Jangan
  pernah menjanjikan Soong singkat.
- Restart wajib direct ninja saja (12:43 WIB 2026-11-03); mka sebagai fallback
  dibatalkan — bila direct ninja tidak bisa dijalankan, berhenti dan lapor.
- Peringatan: setiap laporan restart wajib menyatakan di depan apakah
  perbaikan memaksa Soong ulang (cek artifact-path membaca source product
  file, jadi edit source selalu memicu Soong ulang).
