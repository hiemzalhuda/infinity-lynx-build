# Credits

Repo ini berdiri di atas karya banyak pihak. Semua credit di bawah ini wajib
dipertahankan bila repo ini di-fork, disalin, atau dipakai sebagai dasar
build lain.

## Build ini

- **HIEMZ (Rohimmul Huda)** — maintainer build UNOFFICIAL ini; adaptasi
  Infinity-X Android 17 untuk lynx dari tree LineageOS 24.0, product makefile
  `device/infinity_lynx.mk`, seluruh perbaikan build #1–#12, prosedur Kati-only,
  dan dokumentasi di repo ini.

## Struktur repo (referensi tata letak)

- **Pyrtles (Pyrtle93)** — maintainer Infinity-X seri Pixel 7. Susunan
  `device/` repo ini (product makefile, slot `overlay-infinity/`,
  `rro_overlays/`, `sepolicy/`) mengikuti tata letak repo device beliau
  (`Infinity-X-Devices/device_google_lynx`, cabang 16). Tree Android 17 di sini
  **bukan** tree beliau, **bukan** turunan langsung dari tree beliau, dan
  **bukan** build OFFICIAL beliau. Terima kasih atas tree A16 resminya yang
  menjadi acuan struktur — dan atas ROM A16 official yang sebelumnya lolos
  myJAPFA di perangkat ini.

## Basis source (upstream)

- **ProjectInfinity-X** — ROM Infinity-X, `vendor/infinity` (config common,
  sistem build Infinity-X), dan `vendor/extras` (RRO overlay). Lisensi Apache-2.0.
- **LineageOS** — tree device `device/google/lynx`, `device/google/gs201`,
  dan `device/google/lynx-kernels` (cabang `lineage-24.0`), serta sistem build
  AOSP/Soong/Kati yang dipakai. Lisensi Apache-2.0.
- **CalyxOS** — tree device Pyrtles yang menjadi acuan struktur diturunkan
  dari Calyx; disebut di sini karena rantai turunannya melewati Calyx.
- **TheMuppets** — `proprietary_vendor_google_lynx` (blob proprietary
  Pixel 7a, cabang `lineage-24.0`). Blob proprietary tetap milik Google/
  pemegang haknya, bukan open source.
- **Google** — AOSP, kernel Pixel gs-6.1 (GKI, `android14-6.1-2026-03_r24`),
  dan GMS (proprietary). Fingerprint stock yang dipakai di product makefile
  adalah nilai resmi factory image Pixel 7a Android 17 Oktober 2026
  (`CP3A.261005.002.A1`), bukan karangan.
- **tejas101k** — `proprietary_vendor_pixel_gms` (GitLab) yang menjadi sumber
  modul GMS di build ini (varian GAPPS).

## Lisensi per komponen

- File-file AOSP / LineageOS / Infinity-X di repo ini: Apache-2.0 (lihat
  header SPDX di tiap file).
- Blob proprietary (TheMuppets, GMS): tetap proprietary, hanya dipakai untuk
  build perangkat ini, tidak didistribusikan ulang lewat repo ini.
- Dokumen dan skrip karya HIEMZ di repo ini: bebas dipakai untuk build ulang
  perangkat ini dengan credit di atas tetap dicantumkan.

## Penafian

Repo ini tidak berafiliasi dengan dan tidak didukung oleh Google, LineageOS,
ProjectInfinity-X, Pyrtles, CalyxOS, maupun TheMuppets. Nama-nama di atas
disebut sebagai atribusi karya, bukan sebagai dukungan terhadap build ini.
