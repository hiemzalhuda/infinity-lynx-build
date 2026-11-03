# sepolicy/ (slot gaya Pyrtles)

Repo device Pyrtles punya direktori `sepolicy/` berisi kebijakan SELinux
khusus tree Android 16-nya.

Build Android 17 ini **tidak punya** sepolicy khusus: kebijakan yang dipakai
adalah sepolicy bawaan tree Lineage (gs201/lynx) apa adanya, dan sejauh build
#1–#12 tidak ada kegagalan yang berasal dari sepolicy.

Slot ini dipertahankan supaya susunan repo sejajar dengan repo Pyrtles, dan
supaya ada tempat yang jelas bila suatu hari sepolicy khusus benar-benar
dibutuhkan — jangan mengarang aturan sepolicy ke sini tanpa sumber yang jelas.
