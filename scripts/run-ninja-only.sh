#!/bin/bash
export PATH="$HOME/python312/bin:$HOME/bin:$HOME/infinityx/prebuilts/jdk/jdk21/linux-x86/bin:$PATH"
# Direct ninja on the Kati-regenerated plan (NO Soong, NO mka).
# Plan verified 2026-11-03 16:01 WIB: bacon edge has OTA input, otapackage + boot.img edges exist.
cd ~/infinityx || exit 1
LOG="build-lynx-$(date +%Y%m%d-%H%M).log"
echo "Log: $LOG"
./prebuilts/build-tools/linux-x86/bin/ninja -f out/combined-infinity_lynx.ninja -j2 bacon 2>&1 | tee "$LOG"
echo "DIRECT_NINJA_EXIT=${PIPESTATUS[0]}" | tee -a "$LOG"
