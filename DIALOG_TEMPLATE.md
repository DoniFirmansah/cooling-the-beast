# 📜 DIALOG_TEMPLATE.md — Template Naskah Dialog & Teks Aqua-7
> **Edit file ini untuk mengubah semua dialog tanpa menyentuh kode GDScript.**
> Setelah selesai, salin teks ke konstanta di `scripts/ui/HUD.gd`.

---

## 📐 Format Beat Dialog

```gdscript
{
    "camera_target": Vector2(X, Y),   # Kamera bergerak ke sini
    "speaker_badge": "NAMA // LABEL", # Nama speaker di atas dialog
    "speaker_color": Color(R, G, B),  # Warna nama (0.0–1.0)
    "raw_text": "Teks...",            # Isi dialog (BBCode: [b], [color=#hex])
    "prompt": "[SPASI] Teks Tombol"   # Teks pada tombol lanjut
}
```

### Koordinat Kamera Penting
| Lokasi              | Vector2              |
|---------------------|----------------------|
| Danau / Reservoir   | `Vector2(0, 15)`     |
| Mega Server (Barat) | `Vector2(-356, -36)` |
| Sawah Warga (Timur) | `Vector2(336, 0)`    |
| Robot AQUA-7        | `Vector2(0, 65)`     |

### BBCode yang Didukung
- Tebal: `[b]teks[/b]`
- Warna: `[color=#ff5555]teks[/color]`
- Baris baru: `\n`

---

## 🎬 BAGIAN 1 — PROLOG (Shift 1 Dimulai)
> Lokasi di kode: `const PROLOGUE_BEATS` di `scripts/ui/HUD.gd`

### Beat 1 — Danau & Tutorial Isi Air
```
speaker_badge : 💧 🤖 AQUA-7 // PROTOKOL INTERNAL
speaker_color : Color(0.15, 0.90, 1.0)
camera_target : Vector2(0, 15)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG — edit di sini]
Inisialisasi sistem hidrolik selesai. Sumber air bersih terdeteksi [b]280 Liter[/b].
[color=#66e5ff][b][TUTORIAL]:[/b] Berjalanlah ke tepi danau lalu tahan [b][SPASI][/b] untuk menyedot air bersih ke dalam tangki 120L robot.[/color]
```

### Beat 2 — Server & Tutorial Siram Server
```
speaker_badge : 🔥 🖥️ DEEPBEAST-2.0T // DIRECTIVE ALPHA
speaker_color : Color(1.0, 0.35, 0.25)
camera_target : Vector2(-356, -36)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG — edit di sini]
Peringatan Panas: 4 klaster rak server AI beroperasi pada daya komputasi tinggi.
[color=#ff8a80][b][TUTORIAL]:[/b] Dekati rak server lalu semprot pendingin dengan [b][SPASI][/b]. Jangan biarkan suhu menyentuh 90°C atau chip rusak permanen![/color]
```

### Beat 3 — Sawah & Tutorial Siram Tanaman
```
speaker_badge : 🌱 🌾 PAK MARNO // KETUA TANI AGRI-DOME
speaker_color : Color(0.40, 0.95, 0.45)
camera_target : Vector2(336, 0)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG — edit di sini]
AQUA-7, dengarkan kami! Sawah ini adalah tumpuan pangan ratusan keluarga warga.
[color=#8ce99a][b][TUTORIAL]:[/b] Lari melintasi jembatan ke timur. Semprot petak sawah dengan [b][SPASI][/b] agar kelembapan tanah tetap hijau di atas 30%![/color]
```

### Beat 4 — Ringkasan Kontrol & Mulai Operasi
```
speaker_badge : ⚡ ⚙️ STATUS OPERASIONAL // HARI KE-1
speaker_color : Color(1.0, 0.85, 0.30)
camera_target : Vector2(0, 65)
prompt        : [SPASI] Mulai Operasi 🚀

[TEKS DIALOG — edit di sini]
[color=#ffe066][b][KONTROL]:[/b] [b][WASD][/b] Gerak • Tahan [b][SHIFT][/b] Lari Cepat • [b][SPASI][/b] Siram / Ambil Air.[/color]
Air melimpah 280L. Waktu 06:00 dimulai. Selamat bertugas, Unit AQUA-7!
```
---

## ⏩ BAGIAN 2 — TRANSISI SHIFT 1 → 2
> Dialog Cutscene → `const SHIFT_1_TO_2_BEATS` di `scripts/ui/HUD.gd`
> Teks Layar Gelap diambil otomatis dari `GameManager.gd`

### Teks Layar Gelap
```
time_skip : TIMELINES[monthly][2][time_jump]  → +14 HARI BERLALU
day_label : TIMELINES[monthly][2][day_label]  → HARI KE-15
desc_line : baris pertama SHIFT_CONFIG[1][next_desc]
```

### Beat S1→2 Beat 1 — Laporan Satelit
```
speaker_badge : 📡 TELEMETRI SATELIT // +14 HARI BERLALU
speaker_color : Color(0.15, 0.90, 1.0)
camera_target : Vector2(-356, -36)
[TEKS DIALOG]
[b]HARI KE-1 SELESAI.[/b] +14 Hari berlalu (Memasuki 15 Agustus 2049).
Batch pelatihan model AI DeepBeast 2.0T telah berjalan penuh selama 2 pekan!
```

### Beat S1→2 Beat 2 — Danau Surut
```
speaker_badge : 💧 SENSOR HIDROLOGI // DANAU SURUT
speaker_color : Color(1.0, 0.75, 0.25)
camera_target : Vector2(0, 15)
[TEKS DIALOG]
Sistem pendingin AI menyedot air tanah. Cadangan danau [b]anjlok ke 190 Liter![/b]
Garis air surut 25% dan dasar lumpur mulai retak.
```

### Beat S1→2 Beat 3 — Pak Marno
```
speaker_badge : 🌾 PAK MARNO // LAPORAN KEKERINGAN
speaker_color : Color(0.40, 0.95, 0.45)
camera_target : Vector2(336, 0)
[TEKS DIALOG]
Gelombang panas membakar daun padi kami! Jangan biarkan air disedot hanya untuk mesin AI!
```

### Beat S1→2 Beat 4 — Briefing Hari ke-15
```
speaker_badge : ⚡ ⚙️ OPERASI HARI KE-15 // BEBAN MASIF
speaker_color : Color(1.0, 0.85, 0.30)
camera_target : Vector2(0, 65)
prompt        : [SPASI] Masuk Hari ke-15 🚀
[TEKS DIALOG]
Pemanasan server naik 1.15x dan pengeringan sawah naik 1.10x. Cadangan dipangkas ke 190L!
```

---

## ⏩ BAGIAN 3 — TRANSISI SHIFT 2 → 3
> Dialog Cutscene → `const SHIFT_2_TO_3_BEATS` di `scripts/ui/HUD.gd`

### Teks Layar Gelap
```
time_skip : TIMELINES[monthly][3][time_jump]  → +15 HARI BERLALU
day_label : TIMELINES[monthly][3][day_label]  → HARI KE-30
desc_line : baris pertama SHIFT_CONFIG[2][next_desc]
```

### Beat S2→3 Beat 1 — Alarm Kritis
```
speaker_badge : 🚨 ALARM KRITIS // DIRECTIVE ALPHA
speaker_color : Color(1.0, 0.25, 0.25)
camera_target : Vector2(-356, -36)
[TEKS DIALOG]
[b]HARI KE-15 SELESAI.[/b] Gelombang panas mencapai rekor suhu tertinggi!
Seluruh klaster superkomputer di ambang meltdown permanen!
```

### Beat S2→3 Beat 2 — Danau Kritis
```
speaker_badge : 💧 SENSOR HIDROLOGI // LEVEL KRITIS
speaker_color : Color(1.0, 0.45, 0.20)
camera_target : Vector2(0, 15)
[TEKS DIALOG]
Pipa suplai air regional putus. Hanya tersisa [b]110 Liter darurat[/b] di dasar danau!
Ini sumber air TERAKHIR untuk kedua sektor. Pilih dengan bijak!
```

### Beat S2→3 Beat 3 — Jeritan Warga
```
speaker_badge : 🌾 PAK MARNO // JERITAN TERAKHIR
speaker_color : Color(0.50, 0.85, 0.55)
camera_target : Vector2(336, 0)
[TEKS DIALOG]
Kalau sawah ini mati, anak-anak kami kelaparan! Ingat bahwa mesin hanyalah alat. Kehidupan adalah yang utama!
```

### Beat S2→3 Beat 4 — Ultimatum DeepBeast
```
speaker_badge : 🔥 🖥️ DEEPBEAST-2.0T // ULTIMATUM
speaker_color : Color(1.0, 0.25, 0.25)
camera_target : Vector2(-356, -36)
[TEKS DIALOG]
[b]DIREKTIF KORPORASI ALPHA-OMEGA:[/b] Prioritaskan pendinginan data center!
[color=#ff8a80]Keputusanmu adalah keputusan peradaban.[/color]
```

### Beat S2→3 Beat 5 — Momen Keputusan
```
speaker_badge : ⚡ ⚙️ UNIT AQUA-7 // TITIK KEPUTUSAN FINAL
speaker_color : Color(1.0, 0.85, 0.30)
camera_target : Vector2(0, 65)
prompt        : [SPASI] Masuki Hari ke-30 — FINAL 🚀
[TEKS DIALOG]
110 Liter tersisa. Dua sektor menunggu. Satu keputusan untuk selamanya.
[color=#ffe066]Ini bukan tentang algoritma. Ini tentang [b]KEBENARAN[/b].[/color]
```

---

## 🏁 BAGIAN 4 — EPILOG ENDING
> Lokasi: `func _build_ending_beats()` di `scripts/ui/HUD.gd`
> `{s_integ}` = server integrity akhir %, `{f_sec}` = food security akhir %

### ENDING HARMONY (f_sec ≥ 35% AND s_integ ≥ 25%)
```
Beat 1: 🖥️ DEEPBEAST-2.0T  | Vector2(-356,-36)
  Integritas server terjaga pada [b]{s_integ}%[/b]. Model AI 2.0T berhasil dilatih!
Beat 2: 🌾 PAK MARNO        | Vector2(336, 0)
  Ketahanan pangan [b]{f_sec}%[/b]! Panen raya berhasil! Manusia dan mesin berdampingan!
Beat 3: ✨ EPILOG             | Vector2(0, 65)
  [b]Kemajuan teknologi tidak harus membunuh bumi tempatnya berpijak.[/b]
```

### ENDING ORGANIC (f_sec > s_integ)
```
Beat 1: 🌾 PAK MARNO        | Vector2(336, 0)
  Sawah pangan warga terselamatkan ([b]{f_sec}%[/b])!
Beat 2: 🖥️ DEEPBEAST-2.0T  | Vector2(-356,-36)
  Data center padam. Server rusak ([b]{s_integ}%[/b]).
Beat 3: 🌱 EPILOG             | Vector2(0, 65)
  [b]Logika mesin tunduk pada nurani kehidupan.[/b]
```

### ENDING SILICON (selain HARMONY dan ORGANIC)
```
Beat 1: 🖥️ DEEPBEAST-2.0T  | Vector2(-356,-36)
  Integritas superkomputer prima ([b]{s_integ}%[/b])!
Beat 2: 🥀 TANAH TANDUS      | Vector2(336, 0)
  Tanaman mati kering ([b]{f_sec}%[/b]). Para petani mengungsi.
Beat 3: 🤖 EPILOG             | Vector2(0, 65)
  [b]AI berpikir di atas tanah tandus... tak ada lagi manusia yang menikmatinya.[/b]
```

### ENDING TOTAL_COLLAPSE (early failure / keduanya 0)
```
Beat 1: ☠️ KEGAGALAN SISTEM | Vector2(-356,-36)
  Data center terbakar! Semua rak server hancur!
Beat 2: ☠️ TANAH MATI        | Vector2(336, 0)
  Tanaman pangan puso dan mati kekeringan.
Beat 3: ☠️ EPILOG             | Vector2(0, 65)
  [b]Peradaban kehilangan teknologi dan pangannya sekaligus.[/b]
```

---

## 🖥️ BAGIAN 5 — TEKS UI (Edit di GameManager.gd)

| Field              | Lokasi di kode                          | Default                                   |
|--------------------|-----------------------------------------|-------------------------------------------|
| Shift 1 judul      | SHIFT_CONFIG[1][title]                  | HARI 1: PROTOKOL STANDAR (2049)           |
| Shift 1 laporan    | SHIFT_CONFIG[1][next_desc]              | Teks laporan akhir hari 1                 |
| Shift 2 judul      | SHIFT_CONFIG[2][title]                  | HARI 15: BEBAN KOMPUTASI MASIF            |
| Shift 2 laporan    | SHIFT_CONFIG[2][next_desc]              | Teks laporan akhir hari 15                |
| Shift 3 judul      | SHIFT_CONFIG[3][title]                  | HARI 30: DILEMA PENGORBANAN (ZERO-SUM)    |
| Time jump 1→2      | TIMELINES[monthly][2][time_jump]        | +14 HARI BERLALU (2 MINGGU KEMUDIAN)      |
| Day label 1→2      | TIMELINES[monthly][2][day_label]        | HARI KE-15                                |
| Time jump 2→3      | TIMELINES[monthly][3][time_jump]        | +15 HARI BERLALU (TOTAL 1 BULAN)          |
| Day label 2→3      | TIMELINES[monthly][3][day_label]        | HARI KE-30                                |

---

## 📌 Cara Menerapkan Perubahan
1. Edit teks pada `[TEKS DIALOG]` di file ini.
2. Buka `scripts/ui/HUD.gd`, temukan konstanta yang sesuai.
3. Ganti nilai `raw_text` dengan teks baru.
4. Validasi: `godot --headless --path . --quit-after 60`
