# Trik build dengan resource terbatas

Build ini jalan di mesin yang jauh di bawah spek anjuran AOSP: CPU
Core i3-10100F (4c/8t), RAM **8 GiB (7,7 GiB)**, SSD 120 GB untuk `/`,
HDD 500 GB untuk `/data`. AOSP GAPPS normalnya minta 16 GB+ RAM dan
ratusan GB disk. Semua trik di bawah sudah terbukti di rantai build
2026-11-01 s/d 2026-11-05 — bukan teori. Prinsipnya satu: **jangan
melawan mesin** (kurangi paralelisme, tambah swap, jangan hapus `out/`),
dan **tanpa jalan pintas** (tanpa file dummy, tanpa spoofing timestamp,
tanpa skip verifikasi).

## 1. Swap, ZRAM, dan tuning runtime

Swap permanen (fstab) di bilalz: `/swap.img` 4 GB + `/swapfile` 24 GB +
`/swapfile2` 63,2 GB = **~91 GiB**, ditambah ZRAM 6 GB (zstd, prioritas
100) saat runtime → **~97 GiB total**. Tanpa swap sebesar ini, Soong
bootstrap sudah mati OOM di menit-menit awal.

Tuning runtime (skrip `scripts/apply-tuning.sh`, butuh sudo, **hilang
saat reboot** — harus di-apply ulang tiap boot):

- `swappiness=100`, `vfs_cache_pressure=150`,
  `watermark_scale_factor=200`
- Matikan service rakus RAM yang tidak dibutuhkan build: `snapd`,
  `snapd.socket`, `packagekit`, `ModemManager`, `udisks2`

Catatan: tuning ini runtime-only. Setelah reboot apa pun, cek ulang
(`free -h`, `swapon`, `systemctl is-active`) sebelum mengulang build.

## 2. Kontrol job: -j2 normal, -j1 saat OOM

- Normal: `-j2`. Jangan tergoda menaikkan `-j` saat RAM sudah mepet:
  tahap linking dan kapt (annotation processing) rakus memori, dan OOM
  di tengah jalan membuang waktu jauh lebih banyak daripada yang
  dihemat paralelisme.
- Bila build mati karena memori: restart **`-j1` tanpa konfirmasi**,
  tanpa `make clean`, `out/` dipertahankan, direct ninja saja (aturan
  user 2026-11-01 15:25 WIB).
- Bila `-j1` gagal **di edge yang sama dengan error yang sama**, itu
  bukan soal paralelisme lagi — diagnosis lanjut (lihat §6).

## 3. Direct ninja — dan environment yang wajib disiapkan launcher

`mka` menjalankan `soong_build` tanpa syarat, sehingga edit apa pun
di `.bp`/`.mk` memicu analisis ulang Soong **~5–7 jam**. Karena itu
restart di sini memakai **direct ninja** pada plan hasil regenerasi
Kati-only (`scripts/run-kati-only.sh`, lihat `docs/04`), bukan `mka`.

Konsekuensinya: launcher direct ninja (`scripts/run-ninja-only.sh`)
**bypass `envsetup.sh` dan `soong_ui`**, sehingga environment yang
biasanya disiapkan mereka harus diekspor manual di launcher. Tiga
kegagalan beruntun membuktikan ini — semuanya bukan salah source:

| Yang hilang di launcher | Gejala | Fix |
| --- | --- | --- |
| `PATH` lengkap | `env: 'python': No such file or directory` (Ubuntu 22.04 tidak punya `/usr/bin/python`); lalu `java: not found` di metalava/antlr | Symlink `~/bin/python` → `/usr/bin/python3.10`; CPython **3.12.16** standalone di `~/python312` (mterp butuh sintaks f-string Python 3.12+, sistem hanya 3.10); JDK 21 prebuilt tree (`prebuilts/jdk/jdk21/linux-x86/bin`) untuk bare `java` |
| `LC_ALL=C` | `apkcerts doublecheck` gagal: kedua file apkcerts **5386 baris identik**, hanya urutan beda — Soong pakai urutan byte (Go), sisi Make pakai GNU sort di locale `en_US.UTF-8` | `export LC_ALL=C` di launcher + hapus 3 intermediate apkcerts `*.txt` (regenerable) agar ter-generate ulang |
| `OUT_DIR=out` | `gen_build_prop.py:291` crash `startswith(None)` di edge product-build.prop | `export OUT_DIR=out` di launcher |
| `JAVA_TOOL_OPTIONS` dengan `-Xmx` | `java.lang.OutOfMemoryError: Java heap space` di `turbine kapt Launcher3QuickStepLib` (~98,5%) — perintah java turbine tidak membawa `-Xmx`, heap default JVM (~1/4 RAM ≈ 1,9 GiB) tidak cukup | `export JAVA_TOOL_OPTIONS="-Xmx3072m -XX:+UseG1GC -XX:+UseStringDeduplication"` di launcher |

Pelajaran umum: **bila direct ninja gagal dengan "tool tidak ditemukan"
atau error environment, audit environment launcher dulu** — jangan
menyalahkan source. Dan jangan pernah percaya `tmux -e` untuk
menyalurkan PATH; verifikasi environment proses lewat
`/proc/<pid>/environ`.

Nilai `JAVA_TOOL_OPTIONS` yang sama (`-Xmx3072m -XX:+UseG1GC
-XX:+UseStringDeduplication`) awalnya disiapkan sebagai kandidat
untuk jalur `mka` — tapi justru terbukti dibutuhkan di direct ninja
setelah kegagalan heap #9 (lihat §6), dan sejak 2026-11-05 sudah
menjadi baris tetap di `scripts/run-ninja-only.sh`. Tiga baris
kandidat `mka` lainnya (`GOGC=30`, `GOMEMLIMIT=4500MiB`,
`METALAVA_DUMP_ARGV=false`) tetap belum pernah dipakai.

## 4. Plan-load itu sunyi — jangan panik, jangan dibunuh

Plan Ninja hasil regenerasi Kati-only berukuran **~1,6 GB**. Saat
ninja start, log **0 byte selama ~24–36 menit** karena plan sedang
di-parse ke RAM; swap bisa naik sampai ~8–9 GiB di fase ini. Itu
normal, bukan hang. Membunuh proses di fase ini hanya mengulang
plan-load dari nol.

## 5. Membaca counter ninja: [n/m] bukan progres kompilasi murni

`m` di `[n/m]` adalah jumlah edge yang harus **diverifikasi** ninja
di invocation ini — bukan jumlah yang harus dikompilasi ulang.
Karena `out/` dipertahankan, sebagian besar edge lolos re-check
(output sudah ada dan lebih baru dari inputnya) tanpa dikompilasi.
Bukti dari rantai build ini:

- Run 23:46 WIB mulai di `[63/40371]`, penyebutnya menyusut sendiri
  sampai `33829` saat run itu mati — sisa kerja beneran saat mati
  hanya **~494 edge** (`33829 - 33335`).
- Run `-j1` mulai di `[38/40354]`, lalu `[2360/40337]` dalam ~8 menit
  — kecepatan segitu di `-j1` tidak mungkin kalau semuanya kompilasi
  beneran; itu re-check.

Jadi "ngulang dari 40000" adalah salah baca: yang 40 ribuan itu
mayoritas numpang lewat cepat; kerja benerannya tinggal ratusan edge
terakhir. Counter yang melambat menandakan fase re-check habis dan
kompilasi beneran dimulai.

## 6. Dua macam OOM — perlakuannya sama di awal, beda di akhir

- **OOM kernel**: proses di-`Killed`, exit 137, `dmesg` memuat
  `Out of memory`/`oom-killer`. (Catatan: di bilalz `dmesg` sering
  tidak bisa dibaca user biasa — `Operation not permitted` — laporkan
  apa adanya.)
- **OOM heap JVM**: `java.lang.OutOfMemoryError: Java heap space`
  di dalam satu aksi Java — terbukti 2026-11-05 04:14 WIB di
  `turbine kapt Launcher3QuickStepLib` pada 98,5% (`[33335/33829]`),
  padahal RAM sistem tidak habis.

Keduanya: restart `-j1` dulu. Kalau `-j1` gagal di edge yang sama
dengan heap error yang sama, itu sinyal **heap cap JVM** (bukan
paralelisme) — berhenti dan lapor, jangan blind rerun.

Terbukti 2026-11-05 ~10:43 WIB: run `-j1` mati di
`[33401/33971]` (~98,3%) di edge turbine kapt yang sama dengan
heap error yang sama — padahal `-j2` sudah gagal di sana 04:14 WIB.
Perintah java turbine-nya memang tanpa `-Xmx` (cek ekor log:
`prebuilts/jdk/jdk21/linux-x86/bin/java -XX:OnError=...
-XX:CICompilerCount=6 ... -jar .../turbine.jar`), jadi heap default
JVM (~1,9 GiB) yang membatasi, bukan jumlah job. Fix: export
`JAVA_TOOL_OPTIONS="-Xmx3072m -XX:+UseG1GC
-XX:+UseStringDeduplication"` di launcher (JVM membaca variabel ini
saat start; karena command line tidak membawa `-Xmx` sendiri,
nilai ini yang dipakai) lalu direct ninja lagi. Kalau edge yang
sama gagal lagi dengan heap error yang sama di `-Xmx3072m`,
naikkan ke `-Xmx4096m` — RAM 7,7 GiB masih muat untuk satu JVM
sebesar itu di `-j1`.

## 7. Disk: yang boleh dihapus, yang tidak boleh, dan trik reserve

Pantau `df` tiap cek. Ambang peringatan: `/` < 5 GiB,
`/data` < 15 GiB. Jangan menjalankan `du` seluruh tree saat build
jalan (butuh ~110 detik, sering timeout, membebani I/O) — pakai `df`
dan `ls` pada file target saja.

**Boleh dihapus (dengan persetujuan user per item):**

- Workspace build kernel (`/data/kernel-gs61`, 23 GiB) **setelah**
  semua `.ko` + `boot.img` + `dtbo.img` tersalin ke tree dan
  terverifikasi (262/262 referensi ada).
- Backup plan Kati basi (1,6 GiB) setelah regenerasi berhasil.
- Log build lama (~28 MB — kecil, hampir tidak menolong).

**Tidak boleh dihapus:** `out/`, `.repo`, `.ko` di dalam tree, kunci
signing, source tree. Menghapus salah satunya = build ulang dari nol
atau kehilangan kemampuan OTA.

**ccache jangan dihapus saat build jalan.** Di bilalz `~/.ccache`
9,8 GB (akuntansi ccache 10,45 dari 40,00 GB, hit rate ~27%) dan
**aktif dipakai** build yang sedang jalan. Menghapusnya memperlambat
sisa build dan memaksa kompilasi ulang saat retry. Prune setelah
build selesai kalau mau.

**Trik reserved blocks (terbukti 2026-11-05):** ext4 menahan 5%
default untuk root — di `/data` 458 GB itu **~23,3 GiB** yang tidak
bisa dipakai user biasa. `tune2fs -m 1 /dev/sda1` (online, tanpa
hentikan build, tanpa unmount) membebaskan **~18 GiB seketika**
(5% → 1%: 6.104.819 → 1.220.963 blok; `/data` bebas naik
~4,25 GiB → ~22,88 GiB). Butuh sudo. Sebagai penunjang, perintah
perawatan (tune2fs, mount/umount, dmesg, dumpe2fs, journalctl,
apt-get clean/autoclean) bisa diberi NOPASSWD terbatas lewat file
`/etc/sudoers.d/` yang divalidasi `visudo -c` dulu — terbatas,
bukan NOPASSWD untuk semua perintah.

**Opsi USB** kalau reserve tidak cukup: hentikan build, pindahkan
folder produk (`out/target/product/lynx`) ke drive USB 3.0 berformat
**ext4** (NTFS/exFAT bermasalah dengan permission dan symlink build
Android — harus diformat ulang, isinya hilang), symlink balik, lalu
resume. Pakai HDD/SSD enclosure USB 3.0; flashdisk kecil lambat dan
gampang tidur. Trik symlink file final yang belum dibuat (system.img,
super.img, target-files, OTA) ke USB tanpa hentikan build itu ada,
tapi rapuh — step yang hapus-buat ulang file akan menghilangkan
symlinknya — tidak direkomendasikan sebagai rencana utama.

## 8. Aturan keras yang tidak boleh dilanggar demi hemat resource

- Tanpa file dummy (`.ko`, `.pem`, atau apa pun), tanpa spoofing
  timestamp — keduanya pernah diusulkan pihak luar dan ditolak.
- Restart ROM = direct ninja saja; tanpa Soong ulang, tanpa `mka`
  diam-diam (instruksi user 2026-11-03 12:43 WIB).
- Bila Ninja gagal karena file hilang: enumerasi **semua** referensi
  dari graph Ninja dulu, lengkapi semuanya, baru restart — Ninja
  hanya melaporkan file hilang yang pertama.
- Bila build gagal karena disk penuh: laporkan sekali, berhenti
  untuk keputusan user — jangan menghapus apa pun tanpa persetujuan
  per item. Kegagalan disk masih bisa di-resume (hapus output
  parsial step yang gagal, lanjut ninja), bukan build ulang dari nol.
