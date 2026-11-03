# Gerbang verifikasi (wajib lolos semua sebelum dipakai harian)

Gerbang ini **tidak** dicek oleh job pemantau build — dicek terpisah setelah
ZIP jadi. Satu gerbang gagal = perbaiki di source, build ulang, verifikasi
ulang. Jangan pernah patch ZIP.

## Gerbang myJAPFA

1. **Sertifikat OTA = kunci privat sendiri, bukan testkey.** Periksa bundle
   sertifikat OTA: harus berisi sertifikat sendiri, bukan testkey AOSP.
2. **Build tags = `release-keys`.** Artinya varian `user` (bukan `userdebug`).
   KernelSU tetap bisa jalan di varian `user`.
3. **Fingerprint = stock Pixel 7a.** Nilai yang dipakai product file:
   `google/lynx/lynx:17/CP3A.261005.002.A1/16269273:user/release-keys`
   (factory image stock Android 17 Oktober 2026). Tidak boleh fallback ke
   fingerprint generic system.
4. **Prop lineage kosong.** Grep di tree lynx harus kosong, dan runtime
   `ro.lineage.device` harus kosong.
5. **Play Integrity BASIC / DEVICE / STRONG lolos** (pasca-flash, dengan
   lapisan TrickyStore + PIF — spoofing bawaan Infinity-X tidak ditemukan
   lewat grep di `vendor_infinity` cabang 17, jadi lapisan ini tetap wajib
   apa pun hasil grepnya).
6. **myJAPFA terbuka** dan bisa dipakai normal.

## Gerbang isi ZIP

- ZIP berisi boot, vendor_boot, vbmeta, dan image partisi yang lengkap dan
  waras (system, vendor, product, system_ext, odm, vendor_dlkm, super.img).
- Ukuran ZIP wajar (~1–2 GB). ZIP kosong/rusak = gagal.

## Sebelum flash (jalan kembali)

- Backup data ponsel dulu.
- Stock factory image siap di komputer untuk pemulihan fastboot.
- Boot pertama bisa 10–15 menit — jangan force-reboot di tengah boot pertama.
- Pengujian bertahap: Play Integrity dulu, lalu myJAPFA, baru pemakaian harian.
- Bootloader tetap unlocked (disadari dan diterima).
