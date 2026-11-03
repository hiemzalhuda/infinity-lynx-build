#!/bin/bash
# Terapkan semua patch sumber build HIEMZ ke tree hasil sync.
# Pemakaian: ./apply-patches.sh [root-tree]   (default: ~/infinityx)
# Idempotent: patch yang sudah terpasang dilewati, rename yang sudah
# dilakukan dilewati. TIDAK menyentuh kunci signing, kernel, atau out/.
set -e
TREE="${1:-$HOME/infinityx}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$TREE/build" ] || { echo "Bukan root tree Android: $TREE"; exit 1; }

# 1. GMS: hapus blok DeviceIntelligenceNetworkPrebuiltAstrea (duplikat modul,
#    perbaikan build #3). GAPPS tetap dipertahankan.
if git -C "$TREE/vendor/pixel/gms" apply --reverse --check \
    "$REPO/patches/vendor-pixel-gms-Android.bp.patch" >/dev/null 2>&1; then
  echo "GMS patch sudah terpasang, dilewati."
else
  git -C "$TREE/vendor/pixel/gms" apply \
    "$REPO/patches/vendor-pixel-gms-Android.bp.patch"
  echo "GMS patch terpasang."
fi

# 2. Device lynx: daftarkan infinity_lynx.mk di AndroidProducts.mk.
if git -C "$TREE/device/google/lynx" apply --reverse --check \
    "$REPO/patches/device-lynx-AndroidProducts.patch" >/dev/null 2>&1; then
  echo "AndroidProducts patch sudah terpasang, dilewati."
else
  git -C "$TREE/device/google/lynx" apply \
    "$REPO/patches/device-lynx-AndroidProducts.patch"
  echo "AndroidProducts patch terpasang."
fi

# 3. vendor/extras: nonaktifkan 4 overlay GlanceableHub duplikat (perbaikan
#    build #7). Isi .disabled identik dengan Android.bp asli — ini murni rename.
for d in GlanceableHubConfigOverlay GlanceableHubSettingsConfigOverlay \
         GlanceableHubSettingsConfigOverlay2022 GlanceableHubSysuiConfigOverlay; do
  dir="$TREE/vendor/extras/rro_overlays/$d"
  if [ -f "$dir/Android.bp.disabled" ]; then
    echo "$d sudah dinonaktifkan, dilewati."
  elif [ -f "$dir/Android.bp" ]; then
    mv "$dir/Android.bp" "$dir/Android.bp.disabled"
    echo "$d dinonaktifkan (Android.bp -> Android.bp.disabled)."
  else
    echo "PERINGATAN: $dir tidak punya Android.bp maupun .disabled — dilewati."
  fi
done

echo "Selesai. Lanjut: salin device/infinity_lynx.mk ke"
echo "  $TREE/device/google/lynx/infinity_lynx.mk"
echo "lalu siapkan kunci signing (docs/02-signing-keys.md) dan kernel"
echo "(docs/03-kernel-build.md) sebelum build."
