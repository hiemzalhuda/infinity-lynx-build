# rro_overlays/ (duplikat GlanceableHub — sudah diselesaikan)

## Masalah (build #7, 2026-11-02)

Kati gagal duplikat modul: 4 modul overlay GlanceableHub didefinisikan dua
kali — di `device/google/gs201/overlay/` dan di
`vendor/extras/rro_overlays/`:

- `GlanceableHubConfigOverlay`
- `GlanceableHubSettingsConfigOverlay`
- `GlanceableHubSettingsConfigOverlay2022`
- `GlanceableHubSysuiConfigOverlay`

Perbandingan isi: Config, 2022, dan Sysui **identik** di kedua sisi;
Settings **berbeda** (salinan extras menambah 2 bool) — definisi gs201 yang
dipertahankan.

## Perbaikan (diterapkan 2026-11-02, diabadikan di patches/)

Keempat direktori di sisi `vendor/extras` dinonaktifkan dengan me-rename
`Android.bp` menjadi `Android.bp.disabled` (Kati hanya membaca `Android.bp`).
Isi file `.disabled` **identik** dengan isi `Android.bp` asli di HEAD upstream
(diverifikasi per direktori) — jadi perbaikan ini murni rename, bukan edit isi.

Jangan me-rename ulang ke arah sebaliknya, dan jangan menghapus direktori
gs201. Skrip `../../patches/apply-patches.sh` melakukan rename ini secara
idempotent pada tree baru.
