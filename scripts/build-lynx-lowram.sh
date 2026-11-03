#!/bin/bash
# Build Infinity-X v4.0 (Android 17) untuk Pixel 7a (lynx) di mesin 8 GB RAM.
# Dipakai SETELAH setup-lowram-build.sh jalan dan repo sync selesai.
# Inti trik hemat RAM: job paralel dibatasi -j2 (default nproc bisa membunuh build
# karena OOM). Kalau tetap OOM, jalankan ulang dengan -j1 — jangan 'make clean'.
set -e

cd ~/infinityx 2>/dev/null || { echo "Folder ~/infinityx tidak ditemukan. Sync dulu (lihat panduan-build-hemat-ram.md)."; exit 1; }
[ -f build/envsetup.sh ] || { echo "build/envsetup.sh tidak ditemukan — repo sync belum selesai?"; exit 1; }

echo "=== Cek RAM & swap sebelum build ==="
free -h
SWAP_MB=$(free -m | awk '/^Swap:/ {print $2}')
if [ "$SWAP_MB" -lt 8192 ]; then
  echo "PERINGATAN: swap aktif hanya ${SWAP_MB} MB. Jalankan setup-lowram-build.sh dulu (target >= 16 GB)."
fi
echo ""

JOBS="${JOBS:-2}"
echo "=== Build dengan -j${JOBS} (ubah: JOBS=1 ./build-lynx-lowram.sh) ==="
set +e  # lunch kernel sync boleh gagal, kernel prebuilt
source build/envsetup.sh
lunch infinity_lynx-user
set -e  # kembali ke set -e setelah lunch

LOG="build-lynx-$(date +%Y%m%d-%H%M).log"
echo "Log: $LOG"
set +e
mka -j"$JOBS" bacon 2>&1 | tee "$LOG"
STATUS=${PIPESTATUS[0]}
set -e

if [ "$STATUS" -eq 0 ]; then
  echo ""
  echo "BUILD SUKSES. ZIP ada di out/target/product/lynx/"
else
  echo ""
  echo "BUILD GAGAL (lihat $LOG, cari 'error:' / 'Killed' = tanda OOM)."
  echo "Jangan 'make clean'. Coba lagi dengan job lebih kecil:"
  echo "  JOBS=1 ./build-lynx-lowram.sh"
fi
exit "$STATUS"
