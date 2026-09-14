# 📜 DIALOG_TEMPLATE.md — Template Naskah Dialog & Teks Aqua-7
> **Dokumen ini adalah template resmi naskah dialog sinematik permainan.**
> Anda dapat memodifikasi dialog di sini lalu menyalinnya ke konstanta di `scripts/ui/HUD.gd`.

---

## 📐 Format Beat Dialog Sinematik

Setiap dialog cutscene diatur menggunakan struktur Dictionary berikut:
```gdscript
{
    "camera_target": Vector2(X, Y),   # Koordinat kamera membidik target
    "speaker_badge": "NAMA // STATUS",# Label pembicara di bilah atas
    "speaker_color": Color(R, G, B),  # Aksen warna tema pembicara
    "raw_text": "Teks dialog...",     # Teks ucapan (mendukung BBCode)
    "prompt": "[SPASI] Lanjut ▸"      # Petunjuk tombol maju
}
```

### Koordinat Kamera Utama:
| Sektor Target       | Posisi Vector2       | Keterangan |
|---------------------|----------------------|------------|
| Danau / Cekungan    | `Vector2(0, 15)`     | Danau mata air alami tengah |
| Sektor Barat        | `Vector2(-356, -36)` | Fasilitas data center DeepBeast |
| Sektor Timur        | `Vector2(336, 0)`    | Kawasan persawahan Agri-Dome |
| Unit Robot AQUA-7   | `Vector2(0, 65)`     | Posisi berdiri karakter robot |

---

## 🎬 BAGIAN 1 — PROLOG (Fajar Hari ke-1)
> Lokasi di kode: `const PROLOGUE_BEATS` di `scripts/ui/HUD.gd`

### Beat 1 — Danau Mata Air (AQUA-7 Diagnostics)
```
speaker_badge : 💧 AQUA-7 // DIAGNOSTIK HIDROLIK
speaker_color : Color(0.45, 0.75, 0.90)
camera_target : Vector2(0, 15)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
Sensor akuifer terhubung. Cekungan mata air alami terdeteksi pada volume awal [b]280 Liter[/b].
[color=#90cdf4]Sistem siap menyerap pasokan air. Dekati tepian danau dan tahan [b][SPASI][/b] untuk mengisi tangki 120L.[/color]
```

### Beat 2 — Mega Server (DeepBeast Telemetry)
```
speaker_badge : 🔥 DEEPBEAST-2.0T // TELEMETRI TERMAL
speaker_color : Color(0.88, 0.48, 0.38)
camera_target : Vector2(-356, -36)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
Beban komputasi klaster neural aktif. Suhu operasional inti silikon meningkat tajam.
[color=#feb2b2]Direktif Utama: Semprotkan pendingin dengan [b][SPASI][/b] sebelum suhu menyentuh batas bahaya 90°C.[/color]
```

### Beat 3 — Sawah Agri-Dome (Warga Desa Transmission)
```
speaker_badge : 🌾 WARGA DESA // TRANSMISI RADIO TANI
speaker_color : Color(0.48, 0.78, 0.52)
camera_target : Vector2(336, 0)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
"AQUA-7, dengarkan kami... Sawah ini adalah napas hidup keluarga kami di lembah ini.
[color=#9ae6b4]Tolong seberangi jembatan ke timur. Siram tanah kami dengan [b][SPASI][/b] agar kelembapan tidak anjlok di bawah 30%."[/color]
```

### Beat 4 — Karakter AQUA-7 (Inisialisasi Sistem)
```
speaker_badge : ⚙️ AQUA-7 // INISIALISASI PROTOKOL
speaker_color : Color(0.85, 0.78, 0.62)
camera_target : Vector2(0, 65)
prompt        : [SPASI] Start Game ▸

[TEKS DIALOG]
Keseimbangan dua sektor kini berada di bawah kendalimu.
[color=#fefcbf]Navigasi [b][WASD][/b] • Akselerasi [b][SHIFT][/b] • Semprot / Isi Air [b][SPASI][/b].[/color]
Fajar menyingsing di Hari ke-1. Selamat bertugas.
```

---

## ⏩ BAGIAN 2 — TRANSISI SHIFT 1 → 2 (Hari ke-15)
> Lokasi di kode: `const SHIFT_1_TO_2_BEATS` di `scripts/ui/HUD.gd`

### Beat 1 — Akselerasi Neural (Satelit)
```
speaker_badge : 📡 TELEMETRI SATELIT // HARI KE-15
speaker_color : Color(0.45, 0.75, 0.90)
camera_target : Vector2(-356, -36)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
Dua pekan komputasi penuh telah berlalu. Pelatihan neural DeepBeast memasuki fase akselerasi masif.
Panas pelepasan termal meningkat tajam melintasi seluruh modul sirkuit.
```

### Beat 2 — Cekungan Mata Air Surut
```
speaker_badge : 💧 SENSOR HIDROLOGI // AKUIFER MENYUSUT
speaker_color : Color(0.85, 0.68, 0.40)
camera_target : Vector2(0, 15)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
Peringatan Cekungan: Laju serapan air melampaui infiltrasi alami. Muka air danau surut hingga 25%.
Cadangan air bersih terpangkas menjadi [b]190 Liter (2.4m)[/b]. Dasar lumpur mulai mengering.
```

### Beat 3 — Kekeringan Lahan Pertanian
```
speaker_badge : 🌾 WARGA DESA // TRANSMISI RADIO TANI
speaker_color : Color(0.48, 0.78, 0.52)
camera_target : Vector2(336, 0)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
"Kemarau ini makin kejam, AQUA-7... Daun-daun padi kami mulai menguning terpanggang matahari.
Jangan biarkan seluruh air mata air disedot ke gedung server! Kami butuh air itu untuk bertahan!"
```

### Beat 4 — Protokol Darurat Level 2
```
speaker_badge : ⚙️ AQUA-7 // PROTOKOL DARURAT LEVEL 2
speaker_color : Color(0.85, 0.78, 0.62)
camera_target : Vector2(0, 65)
prompt        : [SPASI] Hadapi Hari ke-15 ▸

[TEKS DIALOG]
Tingkat pemanasan server naik 1.15x. Pengeringan lahan sawah naik 1.10x.
Alokasi air danau: [b]190 Liter[/b]. Siapkan nosel hidrolik untuk ritme kerja yang lebih cepat.
```

---

## ⏩ BAGIAN 3 — TRANSISI SHIFT 2 → 3 (Hari ke-30 // Puncak Krisis)
> Lokasi di kode: `const SHIFT_2_TO_3_BEATS` di `scripts/ui/HUD.gd`

### Beat 1 — Krisis Termal DeepBeast
```
speaker_badge : 🚨 ALARM TERMAL // STATUS KRITIS
speaker_color : Color(0.88, 0.40, 0.35)
camera_target : Vector2(-356, -36)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
Memasuki Hari ke-30. Gelombang panas regional mencapai titik kulminasi ekstrem.
Suhu inti komputasi DeepBeast melonjak liar menuju ambang kegagalan struktural permanen.
```

### Beat 2 — Mata Air Di Ambang Kering Total
```
speaker_badge : ⚠️ SENSOR AKUIFER // TAMPUNGAN MINIMAL
speaker_color : Color(0.85, 0.55, 0.35)
camera_target : Vector2(0, 15)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
Suplai pipa hulu terputus akibat kekeringan regional. Cadangan danau berada pada level kritis: [b]110 Liter (1.4m)[/b].
Palung utama telah mengering, menyingkap rekahan tanah tandus di dasar cekungan.
```

### Beat 3 — Permohonan Terakhir Warga
```
speaker_badge : 🥀 WARGA DESA // JERITAN PETANI
speaker_color : Color(0.55, 0.75, 0.58)
camera_target : Vector2(336, 0)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
"Hari ini adalah penentuan panen raya kami, AQUA-7! Jika sawah ini mati sebelum senja, ratusan keluarga kami tak punya makanan esok hari...
Tolong, jangan biarkan mesin membunuh kehidupan!"
```

### Beat 4 — Titik Keputusan Moral Zero-Sum
```
speaker_badge : ⚖️ AQUA-7 // TITIK KEPUTUSAN FINAL
speaker_color : Color(0.85, 0.78, 0.62)
camera_target : Vector2(0, 65)
prompt        : [SPASI] Hadapi Hari Terakhir ▸

[TEKS DIALOG]
Kalkulasi sistem: Sisa air 110L tidak lagi memiliki toleransi kesalahan.
Setiap liter air yang dialirkan adalah pilihan mutlak antara kecerdasan silikon atau kelangsungan pangan biologis.
Keputusanmu akan menentukan akhir dari lembah ini.
```

---

## 🏁 BAGIAN 4 — DIALOG EPILOG AKHIR (4 CABANG ENDING)
> Lokasi di kode: `func _build_ending_beats()` di `scripts/ui/HUD.gd`

### 1. HARMONY (Keseimbangan Rapuh — True Ending)
*Kondisi: Ketahanan Pangan ≥ 35% DAN Integritas Server ≥ 25%*
- **Beat 1 (DeepBeast):** `"Telemetri stabil pada integritas [b]%d%%[/b]. Model kecerdasan buatan 2.0T parameter berhasil dilatih dengan efisiensi energi terukur."`
- **Beat 2 (Warga Desa):** `"Air mata kami menetes melihat bulir padi ini, AQUA-7... [b]%d%%[/b] tanaman berhasil dipanen. Kamu membuktikan teknologi dan manusia bisa saling menjaga!"`
- **Beat 3 (Epilog):** `"Di tepi jurang kepunahan, Unit AQUA-7 menemukan satu celah sempit harmoni.
Sebuah bukti abadi: [b]Kemajuan teknologi tidak harus mematikan bumi tempatnya berpijak.[/b]"`

### 2. ORGANIC (Nurani Organik — Sawah Terselamatkan)
*Kondisi: Ketahanan Pangan > Integritas Server*
- **Beat 1 (Warga Desa):** `"Sawah pangan warga terselamatkan pada [b]%d%%[/b]! Ratusan keluarga petani menyambut masa depan tanpa ancaman kelaparan."`
- **Beat 2 (DeepBeast):** `"Daya server padam total ([b]%d%%[/b]). Kerusakan termal permanen terkonfirmasi. Korporasi kehilangan aset komputasi, namun nurani kehidupan dimenangkan."`
- **Beat 3 (Epilog):** `"Unit AQUA-7 mengesampingkan algoritma korporasi demi mengalirkan sisa air terakhir kepada kehidupan.
[b]Logika mesin tunduk pada nurani bumi.[/b]"`

### 3. SILICON (Gurun Silikon — Server Terselamatkan)
*Kondisi: Integritas Server > Ketahanan Pangan*
- **Beat 1 (DeepBeast):** `"Integritas superkomputer prima ([b]%d%%[/b]). Arsitektur neural 2.0T terlahir sempurna, memproses miliaran data peradaban per detik."`
- **Beat 2 (Warga Desa):** `"Tanah pertanian mati retak menjadi abu ([b]%d%%[/b]). Tak ada lagi padi yang tersisa. Kami terpaksa meninggalkan lembah ini selamanya..."`
- **Beat 3 (Epilog):** `"Kecerdasan buatan paling mutakhir di dunia kini berpikir tanpa henti di tengah kesunyian gurun abu...
[b]di mana tak ada lagi manusia yang tersisa untuk menikmatinya.[/b]"`

### 4. TOTAL_COLLAPSE (Bencana Ekologi Total — Keduanya Hancur)
*Kondisi: Kedua sektor habis (0%) sebelum waktu selesai*
- **Beat 1 (DeepBeast):** `"Alarm kegagalan katastrofik: Seluruh rak server meledak terbakar dalam kepulan asap hitam!"`
- **Beat 2 (Warga Desa):** `"Tanaman sawah puso dan kering terbakar terik matahari... Semua yang kami perjuangkan musnah tak bersisa."`
- **Beat 3 (Epilog):** `"Kelalaian dalam mengelola sumber daya berujung pada keruntuhan total ekosistem.
[b]Peradaban kehilangan teknologi dan pangannya sekaligus.[/b]"`
