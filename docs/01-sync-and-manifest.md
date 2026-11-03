# Sync dan manifest

## Manifest

ROM: Infinity-X cabang 17 (menghasilkan versi 4.1, bukan 4.0). Pin device
tambahan ada di `manifest/lynx.xml` (salin ke `.repo/local_manifests/` lalu
sync ulang):

| Path | Project | Revisi |
| --- | --- | --- |
| `device/google/lynx` | LineageOS/android_device_google_lynx | lineage-24.0 |
| `device/google/gs201` | LineageOS/android_device_google_gs201 | lineage-24.0 |
| `device/google/lynx-kernels` | LineageOS/android_device_google_lynx-kernels | lineage-24.0 |
| `vendor/google/lynx` | TheMuppets/proprietary_vendor_google_lynx | lineage-24.0 |

Alasan: `Infinity-X-Devices/device_google_lynx` tidak punya branch 17
(terverifikasi 2026-11-03: hanya 15, 16, 16-qpr1, 16-qpr2), jadi lynx untuk
Android 17 memakai tree Lineage 24.0 yang diadaptasi.

## Urutan

1. `repo init` manifest Infinity-X cabang 17, lalu `repo sync`.
2. Salin `manifest/lynx.xml` ke `.repo/local_manifests/lynx.xml`, sync ulang.
3. Jalankan `patches/apply-patches.sh <root-tree>`.
4. Salin `device/infinity_lynx.mk` ke `device/google/lynx/infinity_lynx.mk`
   (AndroidProducts.mk sudah ditangani patch, tapi pastikan isinya memuat
   `infinity_lynx.mk`).
5. Lanjut ke kunci (`02-signing-keys.md`) dan kernel (`03-kernel-build.md`)
   sebelum build pertama.

## Catatan

- Sync pertama yang sukses tercatat 2026-11-01 12:33 WIB.
- `device/google/lynx-kernels/` di upstream **sengaja hanya berisi config**
  (8 file) — biner kernel (`.ko`, `boot.img`, `dtbo.img`) di-`.gitignore`
  dan harus dihasilkan lewat `03-kernel-build.md`, bukan dicari di repo.
- Jangan pernah `repo sync` dengan opsi yang menghapus perubahan lokal tanpa
  memeriksa dulu: product file dan patch di atas adalah perubahan lokal.
