# DTB hilang: bootloop walau semua gerbang lolos

## Gejala (2026-11-06)

ZIP lolos SEMUA gerbang verifikasi (`docs/05`) tapi tidak boot: logo Google
muncul ~1 detik lalu HP mati, berulang. Flash via OrangeFox v11 stable. HP
dipulihkan dengan flash RisingOS Revived 9 (basis sama: Lineage 24.0,
Android 17, kernel 6.1).

## Akar masalah

`device/google/lynx-kernels/6.1/` tidak berisi file `*.dtb` sama sekali.
Build memakai aturan di `build/make/core/Makefile`:

```
$(INSTALLED_DTBIMAGE_TARGET) : $(sort $(wildcard $(BOARD_PREBUILT_DTBIMAGE_DIR)/*.dtb))
    cat $^ > $@
```

dengan `BOARD_PREBUILT_DTBIMAGE_DIR := $(TARGET_KERNEL_DIR)` (=
`device/google/lynx-kernels/6.1`, lihat
`device/google/gs201/BoardConfig-common.mk`) dan
`BOARD_INCLUDE_DTB_IN_BOOTIMG := true`.

Karena direktori kernel tidak punya file `*.dtb`, wildcard-nya kosong dan
perintahnya menjadi `cat` tanpa input → `out/target/product/lynx/dtb.img`
berukuran **0 byte**. DTB kosong itu lalu ditempel ke
`vendor_kernel_boot.img` (mkbootimg `--dtb out/dtb.img`) dan ke recovery
image. Kernel mendapat device tree kosong → panic instan sebelum
console/init → persis gejala "logo 1 detik lalu mati".

Koreksi atas dugaan awal: DTB **tidak** ada di `boot.img` hasil
kernel-build (header v4, `dtb_size=0`; tidak ada magic DTB di file itu, di
kernel hasil decompress, maupun di
vendor_boot/init_boot/vendor_kernel_boot/vbmeta). Build kernel Bazel tidak
menghasilkan DTB standalone — DTB adalah output dist terpisah yang tidak
pernah disalin ke tree. Jadi DTB tidak bisa "diekstrak dari boot.img hasil
kernel-build"; harus diambil dari sumber lain.

## Perbaikan

1. Ambil DTB dari salah satu sumber (pilih satu):
   - **(A) Stock factory image** lynx dengan build yang sama dengan
     fingerprint build ini (CP3A.261005.002.A1, Oktober 2026) — ambil DTB
     dari `vendor_kernel_boot.img`-nya. Paling resmi; bonus: factory image
     jadi cadangan rollback.
   - **(B) Build DTB dari source kernel** — re-sync workspace kernel +
     build DTB dari source (paling murni, tapi ~19 GB sync + 1–2 jam).
   - **(C) DTB dari ROM lain yang boot** (dipakai 2026-11-06: RisingOS
     Revived 9, kernel 6.1 se-generasi) — ambil DTB dari
     `vendor_kernel_boot.img`-nya. DTB yang dipakai: 886.583 byte, magic
     `d00dfeed`, berisi 3 DTB tergabung (format multi-DTB standar Pixel),
     string menyebut `gs201`.
   - Untuk mengambil `vendor_kernel_boot.img` dari sebuah OTA ZIP
     (payload.bin), pakai `scripts/payload_extract.py` (Python murni,
     tanpa protobuf): `payload_extract.py <payload.bin> vendor_kernel_boot
     <out.img>`. Lalu ekstrak DTB dari image itu dengan `unpack_bootimg`.
2. Taruh DTB sebagai `device/google/lynx-kernels/6.1/lynx.dtb` (nama file
   bebas — Makefile meng-glob `*.dtb` di direktori itu). Verifikasi:
   magic `d00dfeed`, ukuran tidak 0.
3. **Regenerasi plan via Kati WAJIB** (`scripts/run-kati-only.sh`, tanpa
   Soong). Graph ninja lama dibuat saat `*.dtb` belum ada — edge
   `dtb.img`-nya berisi perintah `cat` kosong tanpa input, sehingga
   menambah file `.dtb` saja TIDAK akan memicu rebuild (ninja tidak punya
   input untuk dicek). Setelah regen, verifikasi edge `dtb.img` di plan
   baru mencantumkan `lynx.dtb` sebagai input.
4. Rebuild via direct ninja (`scripts/run-ninja-only.sh`, bacon, -j1) —
   tanpa Soong ulang, tanpa mka. Yang berubah: `dtb.img` →
   `vendor_kernel_boot.img` → recovery → otapackage/bacon.
5. Verifikasi ulang SEMUA gerbang (`docs/05`) **ditambah gerbang DTB
   baru**: `dtb.img` tidak 0 byte, dan `vendor_kernel_boot.img` baru
   berisi DTB (berbeda dari sebelumnya). Jangan pernah patch ZIP — rebuild
   dari source.

## Aturan untuk rebuild berikutnya

- Setelah salin hasil build kernel ke tree (`docs/03`), pastikan direktori
  kernel berisi file `*.dtb` — bukan hanya `.ko` + `dtbo.img` +
  `boot.img`.
- DTB biner **tidak** masuk repo ini (biner device; `.gitignore`). Ambil
  dari sumber di atas saat build.
- Bila `dtb.img` di `out/` berukuran 0 byte, JANGAN lanjut ke packaging —
  hentikan dan perbaiki sumber DTB dulu.
