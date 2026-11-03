# Gambaran build

Pipeline build Infinity-X 4.1 (Android 17, GAPPS, UNOFFICIAL) untuk lynx:

```
sync cabang 17 (+ local_manifests)
  -> apply patches (GMS, AndroidProducts, overlay extras)
  -> salin device/infinity_lynx.mk
  -> siapkan 9 pasang kunci signing (di luar repo!)
  -> build kernel gs-6.1 dari source, salin .ko + boot.img + dtbo.img
  -> mka -j2 bacon            (Soong ~5-7 jam di mesin 8 GB, Kati, Ninja)
  -> (bila plan basi) Kati-only + direct ninja
  -> ZIP -> gerbang verifikasi -> Google Drive -> flash (dengan jalan kembali)
```

Dokumen per tahap:

- `01-sync-and-manifest.md` — sync dan pin manifest.
- `02-signing-keys.md` — kunci signing (prosedur, bukan nilai kunci).
- `03-kernel-build.md` — kernel dari source.
- `04-kati-only-regeneration.md` — regenerasi plan Kati tanpa Soong.
- `05-verification-gates.md` — gerbang sebelum dipakai harian + flash aman.
- `06-build-history.md` — riwayat build #1–#12 dan pelajarannya.

## Mesin referensi

PC `bilalz`: Core i3-10100F (4c/8t), RAM 8 GB (7,7 GiB), SSD 120 GB (`/`),
HDD 500 GB (`/data`), Ubuntu Server 22.04.5 LTS, user `hiemz`, tree di
`~/infinityx` (symlink ke `/data/infinityx`). Swap permanen ~91 GiB (fstab)
+ ZRAM 6 GiB runtime = total ~97 GiB. Tuning runtime (ZRAM, swappiness=100,
vfs_cache_pressure=150, watermark_scale_factor=200, daemon-stop) diterapkan
lewat `scripts/apply-tuning.sh` (butuh sudo, hanya runtime — hilang tiap reboot).

## Aturan keras (tidak bisa ditawar)

1. Tanpa file dummy apa pun (`.ko`, `.pem`, modul, sertifikat).
2. Tanpa spoofing timestamp untuk mengelabui sistem build.
3. Restart ROM = direct ninja saja; tanpa Soong ulang, tanpa mka diam-diam
   (instruksi user 2026-11-03 12:43 WIB).
4. Bila Ninja gagal karena file hilang: enumerasi **semua** referensi dari
   graph Ninja dulu, lengkapi semuanya, baru restart.
5. ZIP yang gagal satu gerbang verifikasi pun tidak boleh di-patch — perbaiki
   di source dan build ulang.
6. Kunci signing tidak pernah masuk repo, file, log, atau chat.
7. Jangan hapus tree/file sync, jangan push GitHub tanpa perintah eksplisit,
   jangan ubah keputusan sharing internet, jangan tebak password sudo.
