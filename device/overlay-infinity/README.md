# overlay-infinity/ (slot gaya Pyrtles)

Repo device Pyrtles punya direktori `overlay-infinity/` berisi overlay khusus
Infinity-X untuk tree Android 16-nya.

Build Android 17 ini **tidak punya** overlay Infinity khusus: overlay yang
dipakai berasal dari tree Lineage (`device/google/gs201/overlay/` dan
`device/google/lynx/`), dan duplikat overlay GlanceableHub diselesaikan di sisi
`vendor/extras` (lihat `../rro_overlays/README.md` dan
`../../patches/apply-patches.sh`).

Slot ini dipertahankan supaya susunan repo sejajar dengan repo Pyrtles, dan
supaya ada tempat yang jelas bila suatu hari overlay Infinity khusus
benar-benar ditambahkan — jangan mengarang isi overlay ke sini tanpa sumber
yang jelas.
