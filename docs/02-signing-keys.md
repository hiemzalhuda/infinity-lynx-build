# Kunci signing (prosedur — bukan nilai kunci)

## Kenapa kunci ini penting

`PRODUCT_DEFAULT_DEV_CERTIFICATE` di `device/infinity_lynx.mk` menunjuk ke
`vendor/infinity/security/`. Direktori itu **menggantikan** sertifikat default
AOSP: setiap nama sertifikat yang direferensikan graph Ninja harus ada di
sana, dan yang hilang baru ketahuan saat penjadwalan Ninja (bukan saat Soong).
Dua build gagal karena ini: #10 (`sdk_sandbox`) dan #11 (`bluetooth`).

## Set lengkap (9 pasang)

Yang direferensikan graph Ninja, dienumerasi dari
`out/build-infinity_lynx.ninja` (2026-11-03): **bluetooth, media,
networkstack, nfc, platform, releasekey, sdk_sandbox, shared, testkey**.

Catatan: label `testkey` di sini hanya nama modul — materinya adalah kunci
privat baru yang digenerate sendiri, bukan testkey AOSP. `cts_uicc_2021`
tidak direferensikan — jangan generate tanpa alasan.

## Lokasi

- Di tree: `vendor/infinity/security/` (dipakai build).
- Backup: `~/.android-certs/` (salinan kedua di mesin yang sama).
- **Backup offline yang aman WAJIB dilakukan secepatnya.** Kalau kunci hilang,
  OTA berikutnya tidak bisa ditandatangani dengan kunci yang sama dan semua
  perangkat harus clean flash. Kunci tidak pernah masuk repo, file chat, log,
  atau layanan file-sharing.

## Cara generate (direct openssl — jangan pakai make_key)

`development/tools/make_key` terbukti bermasalah di SSH non-interaktif:
menggantung di stdin, tarian FIFO-nya bisa deadlock permanen, dan selalu
exit 1 walau sukses. Pakai langkah openssl langsung per kunci (OpenSSL 3.0.2
di bilalz — urutan argumen `genrsa` wajib numbits terakhir):

```sh
# di direktori temp berizin 700, hapus setelah selesai
openssl genrsa -f4 -out <nama>.key 2048
openssl req -new -x509 -sha256 -key <nama>.key -out <nama>.x509.pem \
  -days 10000 -subj "/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com"
openssl pkcs8 -in <nama>.key -topk8 -outform DER -out <nama>.pk8 -nocrypt
```

Hasil per kunci: `<nama>.pk8` + `<nama>.x509.pem`, disalin ke kedua lokasi
di atas. Permisi: kunci privat 600, sertifikat 644.

## Bila Ninja gagal karena sertifikat hilang

Jangan perbaiki satu per satu. Enumerasi **semua** nama sertifikat dari
`out/build-infinity_lynx.ninja`, lengkapi semua yang hilang, baru restart
(Ninja hanya melaporkan file hilang yang pertama).
