#!/bin/bash
# Kati-only plan regeneration (replica of soong_ui runKatiBuild, WITHOUT Soong).
# Rev 2: export OUT_DIR + TMPDIR (soong_ui ensures OUT_DIR in ckati env; missing it
# failed attempt 1 with 'unknown variable: OUT_DIR' at config.mk:34).
# Stale plan backup already in /data/kati-backup-20261103; restores it on failure.
cd ~/infinityx || exit 1
source build/envsetup.sh >/dev/null 2>&1
lunch infinity_lynx-user >/dev/null 2>&1 || exit 1
export BUILD_USERNAME=hiemz
export OUT_DIR=out
export TMPDIR=/tmp
export BUILD_DATETIME_FILE=out/build_date.txt
export ANDROID_JAVA_HOME=prebuilts/jdk/jdk21/linux-x86
export PATH=/data/infinityx/prebuilts/jdk/jdk21/linux-x86/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
unset SOONG_USE_PARTIAL_COMPILE BUILD_HOSTNAME BUILD_NUMBER
export HAS_BUILD_NUMBER=false
LOG="kati-only-$(date +%Y%m%d-%H%M).log"
rm -f out/build-infinity_lynx.ninja
./prebuilts/build-tools/linux-x86/bin/ckati --ninja --ninja_dir=out --ninja_suffix=-infinity_lynx --no_ninja_prelude --use_ninja_phony_output --regen --ignore_optional_include=out/%.P --detect_android_echo --color_warnings --gen_all_targets --use_find_emulator --werror_find_emulator --no_builtin_rules --werror_suffix_rules --werror_real_to_phony --top_level_phony --werror_phony_looks_real --werror_writable --kati_stats --writable out/ --werror_implicit_rules --werror_overriding_commands -f build/make/core/main.mk SOONG_MAKEVARS_MK=out/soong/make_vars-infinity_lynx.mk SOONG_ANDROID_MK=out/soong/Android-infinity_lynx.mk TARGET_DEVICE_DIR=device/google/lynx/lynx KATI_PACKAGE_MK_DIR=out/soong/kati_packaging-infinity_lynx 2>&1 | tee "$LOG"
CKATI_EXIT=${PIPESTATUS[0]}
echo "CKATI_EXIT=$CKATI_EXIT" | tee -a "$LOG"
if [ "$CKATI_EXIT" -ne 0 ] || [ ! -f out/build-infinity_lynx.ninja ]; then
  cp /data/kati-backup-20261103/build-infinity_lynx.ninja out/build-infinity_lynx.ninja 2>/dev/null
  echo "RESTORED stale plan from backup" | tee -a "$LOG"
fi
