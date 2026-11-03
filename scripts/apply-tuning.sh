#!/bin/bash
# Re-apply post-reboot RAM tuning (runtime-only, same as 2026-11-02).
# Safe while ninja compiles: ZRAM/sysctl/daemon stops do not disturb running processes.
modprobe zram num_devices=1 2>/dev/null || true
DS=$(cat /sys/block/zram0/disksize 2>/dev/null || echo 0)
if [ "$DS" = "0" ] && [ -e /sys/block/zram0 ]; then
  echo zstd > /sys/block/zram0/comp_algorithm 2>/dev/null || true
  echo 6442450944 > /sys/block/zram0/disksize
  mkswap /dev/zram0 >/dev/null 2>&1
  swapon -p 100 /dev/zram0
fi
sysctl -w vm.swappiness=100 vm.vfs_cache_pressure=150 vm.watermark_scale_factor=200
systemctl stop snapd snapd.socket packagekit ModemManager udisks2 2>/dev/null || true
echo "=== VERIFY ==="
free -h | head -2
swapon --show
sysctl vm.swappiness vm.vfs_cache_pressure vm.watermark_scale_factor
for u in snapd packagekit ModemManager udisks2; do echo "$u: $(systemctl is-active $u 2>/dev/null)"; done
lsmod | grep -c zram || true
