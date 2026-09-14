# Panduan Penempatan Aset Grafis (Raw PNG) - "Aqua-7: Machine and Earth"

Silakan letakkan file gambar PNG (spritesheet atau loose PNG) ke sub-folder di bawah ini:

## 1. `assets/characters/`
- **Isi:** Sprite karakter teknisi/operator (tampak atas / top-down).
- **Format:** PNG transparan (bisa spritesheet kisi 16x16, 32x32, atau file terpisah `idle.png`, `walk_down.png`, dll).

## 2. `assets/environment/server_room/`
- **Isi:** Objek rak server AI, ubin lantai metal/industri, konsol komputer, kabel lantai.
- **Format:** PNG transparan (objek rak server sebaiknya memiliki dasar kaki yang jelas untuk Y-sorting).

## 3. `assets/environment/farmland/`
- **Isi:** Ubin tanah sawah/irigasi, tanaman padi/hijau (fase subur vs fase kering/layu), pagar pembatas.
- **Format:** PNG transparan.

## 4. `assets/environment/pipes/`
- **Isi:** Ubin pipa (lurus, belokan, sambungan T), katup/valve putar, tangki air/hidran penampungan.
- **Format:** PNG transparan.

## 5. `assets/ui/`
- **Isi:** Ikon tetesan air (water tank capacity), ikon suhu/termometer, ikon padi/lumbung, frame bar, tombol UI.
- **Format:** PNG transparan.
