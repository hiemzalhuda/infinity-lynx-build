# Infinity-X untuk Pixel 7a (lynx) — build HIEMZ

Build **UNOFFICIAL** Infinity-X **4.1** (Android 17, varian **GAPPS**) untuk Pixel 7a
(lynx), diadaptasi dari tree LineageOS 24.0 karena Infinity-X-Devices belum punya
branch 17 untuk lynx. Repo ini adalah **lapisan adaptasi HIEMZ di atas tree
upstream** — bukan fork penuh — supaya build ulang tetap gampang tanpa
kehilangan jejak ke upstream. Susunan `device/`-nya mengikuti slot-slot repo
device milik Pyrtles (Pyrtle93), maintainer Infinity-X seri Pixel 7
(lihat `CREDITS.md`).

> **Bukan build OFFICIAL.** Label OFFICIAL milik Pyrtles untuk tree Android 16
> resminya. Build ini UNOFFICIAL dan tidak boleh dilabeli OFFICIAL.

> **JANGAN PERNAH commit kunci signing ke repo ini (atau repo mana pun).**
> Kunci privat hanya dibackup offline (lihat `docs/02-signing-keys.md`).
> `.gitignore` repo ini memblokir `security/`, `*.bak`, `*.ko`, `boot.img`,
> `dtbo.img`, dan `out/`.

## Isi repo

| Jalur | Isi |
| --- | --- |
| `device/infinity_lynx.mk` | Product makefile build ini (verbatim dari tree build). Maintainer HIEMZ, inherit Infinity-X common + `aosp_lynx.mk`, fingerprint stock A17, allowlist artifact GMS, cert signing, `PRODUCT_MODULE_BUILD_FROM_SOURCE`. |
| `device/AndroidProducts.mk` | Registrasi product makefile (`aosp_lynx`, `lineage_lynx`, `infinity_lynx`). |
| `device/overlay-infinity/` | Slot overlay gaya Pyrtles — penjelasannya di `README.md` di dalamnya. |
| `device/rro_overlays/` | Slot RRO overlay — penjelasan duplikat GlanceableHub di `README.md` di dalamnya. |
| `device/sepolicy/` | Slot sepolicy — penjelasan di `README.md` di dalamnya. |
| `manifest/lynx.xml` | Pin local manifest (4 project, semua `lineage-24.0`). |
| `patches/` | Patch sumber + skrip `apply-patches.sh` (GMS, AndroidProducts, rename overlay extras). |
| `scripts/` | Skrip build, Kati-only, direct ninja, dan tuning pasca-reboot. |
| `docs/` | Prosedur lengkap: sync, kunci, kernel, regenerasi Kati-only, gerbang verifikasi, riwayat build #1–#12. |

## Build ulang, ringkas

1. Sync tree Infinity-X cabang 17, lalu salin `manifest/lynx.xml` ke
   `.repo/local_manifests/` dan sync ulang (lihat `docs/01-sync-and-manifest.md`).
2. Jalankan `patches/apply-patches.sh <root-tree>` dari repo ini.
3. Salin `device/infinity_lynx.mk` dan `device/AndroidProducts.mk` ke
   `device/google/lynx/` (AndroidProducts.mk ditimpa dengan versi repo ini).
4. Siapkan kunci signing (9 pasang, `docs/02-signing-keys.md`) — **di luar repo** —
   ke `vendor/infinity/security/` dan backup offline ke `~/.android-certs`.
5. Build kernel dari source dan salin hasilnya (`docs/03-kernel-build.md`) —
   jangan pernah memakai `.ko` dummy.
6. Build: `scripts/build-lynx-lowram.sh` (mka `-j2 bacon`). Bila plan Kati
   sudah basi (mis. boot.img baru muncul setelah plan dibuat), regenerasi
   dengan `scripts/run-kati-only.sh` lalu `scripts/run-ninja-only.sh`
   (lihat `docs/04-kati-only-regeneration.md`).
7. Sebelum dipakai harian, loloskan semua gerbang `docs/05-verification-gates.md`.
   ZIP yang gagal satu gerbang pun tidak boleh di-patch — perbaiki di source
   dan build ulang.

## Catatan yang bisa membingungkan

- Header `scripts/build-lynx-lowram.sh` masih tertulis "v4.0" — itu label lama.
  Build yang dihasilkan manifest cabang 17 adalah **4.1**.
- Komentar `scripts/run-kati-only.sh` masih tertulis "Rev 2", tapi isinya
  sudah revisi yang berhasil (semua variabel lingkungan yang dibutuhkan ada).
- Skrip-skrip di sini ditulis untuk mesin build `bilalz` (Ubuntu Server 22.04,
  user `hiemz`, tree di `~/infinityx`). Sesuaikan path bila mesinnya beda.
- ZIP hasil build **tidak** disimpan di repo ini. Hasil build terakhir yang
  didokumentasikan di sini: kompilasi direct ninja sejak 2026-11-03 16:08 WIB
  (plan hasil regenerasi Kati-only 16:01 WIB); status live ada di chat, bukan
  di repo ini.

## Aturan keras build ini

- Tanpa file dummy (`.ko`, `.pem`, atau apa pun), tanpa spoofing timestamp.
- Restart ROM = direct ninja saja; tanpa Soong ulang, tanpa mka diam-diam
  (instruksi user 2026-11-03 12:43 WIB).
- Bila Ninja gagal karena file hilang: enumerasi **semua** referensi dari
  graph Ninja dulu, lengkapi semuanya, baru restart — Ninja hanya melaporkan
  file hilang yang pertama.
- Jangan hapus tree/file sync, jangan push GitHub tanpa perintah eksplisit,
  jangan ubah keputusan sharing internet, jangan tebak password sudo.
