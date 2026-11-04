# Regenerasi plan Kati-only (tanpa Soong, tanpa mka)

## Kapan dipakai

Bila plan Ninja (`out/build-infinity_lynx.ninja`) dibuat saat sebuah
prerequisite belum ada — kasus nyata: plan #12 dibuat saat `boot.img` belum
ada, sehingga `build_ota_package` false, plan tidak punya edge `boot.img`
maupun `otapackage`, dan edge ZIP final tidak punya prerequisite (bacon gagal
`mv: missing destination file operand`). Plan seperti itu **tidak bisa
diperbaiki dengan direct ninja** — harus diregenerasi.

Syarat: tidak ada input Soong yang berubah (tidak ada edit `.bp`, `.mk`,
atau product file) sejak plan lama dibuat. Bila input Soong berubah, prosedur
ini tidak berlaku — ikuti instruksi user saat itu (aturan direct-ninja-only
tetap berlaku; jangan diam-diam menjalankan mka).

## Skrip

`scripts/run-kati-only.sh` — replika invokasi `runKatiBuild` dari soong_ui
(`build/soong/ui/build/kati.go`), hanya Kati, tanpa Soong:

- Biner: `prebuilts/build-tools/linux-x86/bin/ckati`.
- Argumen: `--ninja --ninja_dir=out --ninja_suffix=-infinity_lynx
  --no_ninja_prelude --use_ninja_phony_output --regen
  --ignore_optional_include=out/%.P --detect_android_echo --color_warnings
  --gen_all_targets --use_find_emulator --werror_find_emulator
  --no_builtin_rules --werror_suffix_rules --werror_real_to_phony
  --top_level_phony --werror_phony_looks_real --werror_writable --kati_stats
  --writable out/ --werror_implicit_rules --werror_overriding_commands
  -f build/make/core/main.mk` + variabel trailing
  `SOONG_MAKEVARS_MK=out/soong/make_vars-infinity_lynx.mk
  SOONG_ANDROID_MK=out/soong/Android-infinity_lynx.mk
  TARGET_DEVICE_DIR=device/google/lynx/lynx
  KATI_PACKAGE_MK_DIR=out/soong/kati_packaging-infinity_lynx`.
- Variabel lingkungan yang wajib ditambahkan (pelajaran dari 3 percobaan gagal):
  `OUT_DIR=out`, `TMPDIR=/tmp`, `BUILD_DATETIME_FILE=out/build_date.txt`,
  `ANDROID_JAVA_HOME=prebuilts/jdk/jdk21/linux-x86` (relatif, bukan absolut),
  `PATH` diawali direktori bin JDK tersebut, `BUILD_USERNAME=hiemz`,
  unset `SOONG_USE_PARTIAL_COMPILE`/`BUILD_HOSTNAME`/`BUILD_NUMBER`,
  `HAS_BUILD_NUMBER=false`.
- `TARGET_DEVICE_DIR=device/google/lynx/lynx` (direktori bersarang —
  BoardConfig.mk ada di `lynx/lynx/`).
- **Tidak ada auto-restore plan.** Versi awal skrip mengembalikan plan
  lama otomatis bila ckati gagal — perilaku ini **dihapus 2026-11-05**:
  backup plan lama (`/data/kati-backup-20261103`) sudah dihapus
  2026-11-04, dan memakai plan basi justru berbahaya (plan basi adalah
  penyebab kegagalan bacon 2026-11-03: tidak ada edge boot.img/OTA).
  Bila ckati gagal, skrip berhenti dengan pesan jelas dan tidak
  mengembalikan apa pun — diagnosis dulu, jangan pakai plan lama.

Catatan: `lunch` memicu `soong_ui --dumpvars-mode` (~5 menit cache dingin,
~1–2 menit hangat; berat I/O, bukan analisis Soong penuh, bukan hang).
Invokasi KatiPackage/CleanSpec tidak direplikasi — file ninja package
dibiarkan apa adanya (rantai bacon/OTA ada di build file, terverifikasi aman).

## Verifikasi plan baru (wajib sebelum direct ninja)

Acuan keberhasilan 2026-11-03 16:01 WIB: `CKATI_EXIT=0`, 11.491.634 simbol,
plan baru 1.626.645.265 byte. Tiga grep wajib lolos:

1. Edge bacon punya prerequisite:
   `build out/target/product/lynx/Project_Infinity-X-...zip: ... out/target/product/lynx/infinity_lynx-ota.zip`
2. Edge `otapackage` ada: `build otapackage: phony out/target/product/lynx/infinity_lynx-ota.zip`
3. Edge `boot.img` ada: `build out/target/product/lynx/boot.img: ... device/google/lynx-kernels/6.1/boot.img...`

Dan wrapper `out/combined-infinity_lynx.ninja` tetap mendefinisikan
`highmem_pool` + 3 subninja. Bila satu pun gagal, jangan lanjut ke ninja.

## Setelah itu

`scripts/run-ninja-only.sh` (`ninja -f out/combined-infinity_lynx.ninja -j2
bacon`, tmux `build-lynx`). Plan load ~24 menit dalam diam sebelum kompilasi
nyata — itu normal, bukan hang. Jangan pernah memakai
`out/build-infinity_lynx.ninja` langsung sebagai `-f` (pool `highmem_pool`
hanya didefinisikan di combined).
