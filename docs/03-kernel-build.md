# Kernel dari source (gs-6.1)

## Akar masalah (build #12)

`device/google/lynx-kernels/6.1/` lokal hanya berisi 8 file config — nol
`.ko`, tanpa `boot.img`, tanpa `dtbo`. Graph Ninja mereferensikan 262 file
`.ko` unik + `dtbo.img` di direktori itu. Upstream
(`LineageOS/android_device_google_lynx-kernels`, lineage-24.0, commit yang
sama) identik: repo itu config-only **by design**. Tree mengharapkan biner
kernel prebuilt diletakkan di direktori itu (`device/google/lynx/device-lynx.mk`
mengatur `TARGET_KERNEL_DIR`, `BoardConfig-common.mk` mengatur
`KERNEL_MODULE_DIR` dan `BOARD_PREBUILT_BOOTIMAGE` dari wildcard `boot.img`).

Langkah sync kernel yang gagal di build #1 lalu dilewati dengan
`SKIP_KERNEL_SYNC=true` adalah penyebab tidak langsung #12 — jangan ulangi
jalan pintas itu.

## Prosedur (yang sudah terbukti 2026-11-03)

1. Workspace kernel **di luar tree ROM**: `/data/kernel-gs61`.
2. Manifest: `LineageOS/android_kernel_google_gs-6.1_manifest`, cabang
   `lineage-24.0`, tag GKI `android14-6.1-2026-03_r24`. Sync sampai selesai
   (acuan: selesai 13:36 WIB, ~19 GiB).
3. Build dengan Bazel (tmux `kernel-build`; acuan: 529/529, ~28 menit,
   exit 0). Dist di `/data/kernel-gs61/out/lynx/dist/` (~844 MiB).
4. Salin ke tree: semua `.ko` (329 file) + `dtbo.img` + `boot.img` (53 MiB)
   ke `device/google/lynx-kernels/6.1/`.
5. **Jangan sentuh** file `.bp`, `.mk`, atau product file, jangan make clean,
   jangan sentuh `out/` selama langkah ini.

## Verifikasi (wajib, acuan 15:11 WIB 2026-11-03)

- 262/262 `.ko` yang direferensikan graph ada, 0 hilang.
- `dtbo.img` ada.
- 0 file `.ko` berukuran nol.
- `gzvm.ko` terverifikasi ELF 64-bit ARM aarch64 asli (bukan dummy).

Pertahankan workspace `/data/kernel-gs61` + dist untuk rebuild kernel
berikutnya. **Jangan pernah membuat `.ko`/dtbo dummy** — modul dummy bisa
lolos build lalu merusak boot atau fungsi perangkat secara diam-diam.
