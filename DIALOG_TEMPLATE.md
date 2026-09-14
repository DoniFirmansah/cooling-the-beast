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
| Unit Robot AQUA-7   | `Vector2(0, 58)`     | Posisi berdiri karakter robot di dermaga |

---

## 🎬 BAGIAN 1 — PROLOG (Fajar Hari ke-1)
> Lokasi di kode: `const PROLOGUE_BEATS` di `scripts/ui/HUD.gd`

### Beat 1 — Waduk Resapan (AQUA-7 Diagnostics)
```
speaker_badge : 💧 AQUA-7 // DIAGNOSTIK HIDROLIK
speaker_color : Color(0.45, 0.75, 0.90)
camera_target : Vector2(0, 15)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
Sensor hidrologi aktif. Cadangan sumber air tanah terdeteksi: [b]280 Liter[/b].
[color=#90cdf4]Tangki internal robot dalam kondisi kosong (0/80L). Dekati tepian danau dan tahan [b][SPASI][/b] untuk menyerap air bersih.[/color]
```

### Beat 2 — Mega Server (DeepBeast Telemetry)
```
speaker_badge : 🔥 DEEPBEAST-2.0T // TELEMETRI TERMAL
speaker_color : Color(0.88, 0.48, 0.38)
camera_target : Vector2(-356, -36)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
Beban komputasi neural aktif. Suhu modul silikon meningkat tajam.
[color=#feb2b2]Directive Alpha: Alirkan air pendingin evaporatif dengan [b][SPASI][/b] sebelum suhu menyentuh batas kritis 90°C.[/color]
```

### Beat 3 — Sawah Agri-Dome (Warga Desa Transmission)
```
speaker_badge : 🌾 WARGA DESA // TRANSMISI RADIO TANI
speaker_color : Color(0.48, 0.78, 0.52)
camera_target : Vector2(336, 0)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
"AQUA-7, dengarkan kami... Empat petak tanaman ini adalah napas hidup keluarga kami di lembah ini.
[color=#9ae6b4]Tolong seberangi jembatan ke timur. Siram petak pangan kami dengan [b][SPASI][/b] agar kelembapannya tidak anjlok di bawah 30%."[/color]
```

### Beat 4 — Karakter AQUA-7 (Inisialisasi Sistem)
```
speaker_badge : ⚙️ AQUA-7 // INISIALISASI PROTOKOL
speaker_color : Color(0.85, 0.78, 0.62)
camera_target : Vector2(0, 58)
prompt        : [SPASI] Mulai Operasi ▸

[TEKS DIALOG]
Keseimbangan kedua sektor di pos perbatasan berada di tanganmu.
[color=#fefcbf]Navigasi [b][WASD][/b] • Lari Cepat [b][SHIFT][/b] • Semprot / Ambil Air [b][SPASI][/b].[/color]
Fajar menyingsing di Hari ke-1. Mulai operasi.
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
Peringatan Cekungan: Laju serapan air melampaui infiltrasi alami. Muka air danau surut drastis.
Cadangan air bersih terpangkas menjadi [b]190 Liter (2.4m)[/b]. Dasar lumpur mulai mengering.
```

### Beat 3 — Kekeringan Lahan Pertanian
```
speaker_badge : 🌾 WARGA DESA // TRANSMISI RADIO TANI
speaker_color : Color(0.48, 0.78, 0.52)
camera_target : Vector2(336, 0)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
"Kemarau ini makin kejam, AQUA-7... Tanaman di petak kami mulai layu terpanggang matahari.
Jangan biarkan seluruh air mata air disedot ke gedung server! Kami butuh air itu untuk bertahan!"
```

### Beat 4 — Protokol Darurat Level 2
```
speaker_badge : ⚙️ AQUA-7 // PROTOKOL DARURAT LEVEL 2
speaker_color : Color(0.85, 0.78, 0.62)
camera_target : Vector2(0, 58)
prompt        : [SPASI] Hadapi Hari ke-15 ▸

[TEKS DIALOG]
Tingkat pemanasan server naik 1.25x. Pengeringan 4 petak tanaman naik 1.20x.
Alokasi air waduk: [b]190 Liter[/b]. Siapkan nosel hidrolik untuk tempo kerja yang lebih cepat.
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
Hari ke-30: Fase akhir pelatihan model AI. Gelombang panas regional mencapai puncaknya.
Suhu inti prosesor melonjak mendekati ambang batas leleh permanen.
```

### Beat 2 — Akuifer Di Ambang Kering Total
```
speaker_badge : ⚠️ SENSOR AKUIFER // TAMPUNGAN MINIMAL
speaker_color : Color(0.85, 0.55, 0.35)
camera_target : Vector2(0, 15)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
Akuifer tanah mengalami defisit parah akibat kekeringan massal. Cadangan air bersih kritis: [b]110 Liter (1.4m)[/b].
Cekungan resapan surut total, memperlihatkan dasar tanah yang retak-retak.
```

### Beat 3 — Permohonan Terakhir Warga
```
speaker_badge : 🥀 WARGA DESA // JERITAN PETANI
speaker_color : Color(0.55, 0.75, 0.58)
camera_target : Vector2(336, 0)
prompt        : [SPASI] Lanjut ▸

[TEKS DIALOG]
"Hari ini penentuan panen raya kami, AQUA-7! Kalau petak pangan ini gagal panen sebelum senja, anak-istri kami tak punya makanan esok hari...
Tolong kami, jangan biarkan mesin mematikan kehidupan di lembah ini!"
```


### Beat 4 — Titik Keputusan Moral Zero-Sum
```
speaker_badge : ⚖️ AQUA-7 // TITIK KEPUTUSAN FINAL
speaker_color : Color(0.85, 0.78, 0.62)
camera_target : Vector2(0, 58)
prompt        : [SPASI] Hadapi Hari Terakhir ▸

[TEKS DIALOG]
Kalkulasi sistem: Cadangan air bersih 110L tidak lagi menyisakan ruang untuk kesalahan alokasi.
Tiap tetes air kini menuntut kompromi: kecerdasan komputasi atau ketahanan pangan hayati.
Keputusanmu menentukan masa depan pos perbatasan ini.
```


---

## 🏁 BAGIAN 4 — DIALOG EPILOG AKHIR (4 CABANG ENDING)
> Lokasi di kode: `func _build_ending_beats()` di `scripts/ui/HUD.gd`

### 1. HARMONY (Keseimbangan Rapuh — True Ending)
*Kondisi: Ketahanan Pangan ≥ 35% DAN Integritas Server ≥ 25%*
- **Beat 1 (DeepBeast):** `"Suhu terkendali. Integritas sistem stabil di angka [b]%d%%[/b]. Model kecerdasan buatan 2.0T parameter berhasil dilatih tanpa merusak infrastruktur."`
- **Beat 2 (Warga Desa):** `"\"Bulir-bulir pangan ini tetap menguning keemasan... [b]%d%%[/b] hasil panen terselamatkan. Hari ini mesin dan manusia bisa bernapas di bawah langit lembah yang sama.\""`
- **Beat 3 (Epilog):** `"Melalui alokasi presisi hingga tetes air bersih terakhir, AQUA-7 menjaga kedua sektor tetap bertahan hidup.
[b]Di atas tanah lembah yang rapuh, deru server dan gesekan daun padi mengalun berdampingan tanpa saling meniadakan.[/b]"`

### 2. ORGANIC (Nurani Organik — Pangan Terselamatkan)
*Kondisi: Ketahanan Pangan > Integritas Server*
- **Beat 1 (Warga Desa):** `"\"Petak pangan kami selamat dengan ketahanan [b]%d%%[/b]! Ratusan keluarga petani menyambut esok hari tanpa ancaman kelaparan.\""`
- **Beat 2 (Korporasi):** `"Integritas server padam ([b]%d%%[/b]). Kerusakan perangkat keras permanen terkonfirmasi. Model DeepBeast bernilai triliunan musnah. Unit AQUA-7 dinyatakan MALFUNGSI TOTAL dan masuk daftar terminasi paksa atas kerugian korporasi."`
- **Beat 3 (Epilog):** `"Di mata korporasi, Unit AQUA-7 adalah produk gagal yang melanggar kontrak. Namun bagi tanah ini, ia adalah penjaga kehidupan.
[b]Logika mesin dan sanksi korporat tunduk pada nurani bumi.[/b]"`

### 3. SILICON (Gurun Silikon — Server Terselamatkan)
*Kondisi: Integritas Server > Ketahanan Pangan*
- **Beat 1 (DeepBeast):** `"Integritas superkomputer prima ([b]%d%%[/b]). Arsitektur AI DeepBeast-2.0T aktif penuh, memproses miliaran kalkulasi peradaban per detik."`
- **Beat 2 (Warga Desa):** `"\"Tanah petak pangan kami retak menjadi debu kering ([b]%d%%[/b]). Gagal panen total. Kami terpaksa mengemasi barang dan pergi dari lembah ini selamanya...\""`
- **Beat 3 (Epilog):** `"Model AI tercerdas di dunia kini berpikir tanpa henti di tengah kesunyian gurun tandus...
[b]di mana tak ada lagi manusia yang tersisa untuk memanfaatkannya.[/b]"`


### 4. KEGAGALAN DINI (EARLY DEFEAT & ADAPTIVE COLLAPSE)
*Dialog dievaluasi secara adaptif berdasarkan sektor mana yang mengalami kegagalan sebelum Shift 3 berakhir:*

#### A. SERVER_MELTDOWN (AI Blackout — Server Hancur, Pangan Selamat)
*Kondisi: Integritas Server 0%, Ketahanan Pangan > 0%*
- **Beat 1 (Alarm Fasilitas):** `"Suhu inti prosesor melampaui batas kritis 90°C! Sistem pendingin gagal meredam panas dan seluruh rak server meledak terbakar."`
- **Beat 2 (DeepBeast Corp):** `"Pelanggaran fatal Directive Alpha terdeteksi. Pelatihan neural terhenti total. Unit AQUA-7 dikategorikan sebagai KEGAGALAN INVESTASI TINGKAT TINGGI. Seluruh lisensi dicabut dan protokol penonaktifan unit segera dieksekusi dari jarak jauh."`
- **Beat 3 (Warga Desa):** `"\"Petak pangan kami memang selamat dan terairi (%d%%), tapi ledakan di fasilitas server memutus aliran listrik dan membawa ancaman audit korporasi ke lembah kami...\""`
- **Beat 4 (Epilog):** `"Fasilitas komputasi padam menjadi abu dan unitmu dicap sebagai rongsokan cacat.
[b]Bagi korporasi, ambisi bernilai triliunan itu musnah seketika saat dibiarkan terbakar oleh panasnya sendiri.[/b]"`

#### B. CROP_FAMINE (Krisis Pangan — Gagal Panen Total, Server Selamat)
*Kondisi: Ketahanan Pangan 0%, Integritas Server > 0%*
- **Beat 1 (Sensor Tanah):** `"Kelembapan tanah menyentuh 0%! Empat petak tanaman pangan mati mengering terpanggang terik matahari."`
- **Beat 2 (Warga Desa):** `"\"Pasokan air bersih tak pernah sampai ke petak kami... Lumbung pangan mati total. Ratusan keluarga terpaksa mengungsi mencari penghidupan di tempat lain...\""`
- **Beat 3 (DeepBeast):** `"Integritas server bertahan stabil pada angka %d%%, namun hilangnya ketahanan pangan memicu krisis kemanusiaan massal di sekitar pos perbatasan."`
- **Beat 4 (Epilog):** `"Ekosistem pangan biologis runtuh akibat ketiadaan air bersih.
[b]Server komputasi tetap berdengung dingin di tengah hamparan tanah mati yang ditinggalkan penduduknya.[/b]"`

#### C. TOTAL_COLLAPSE (Bencana Ekologi Total — Keduanya Hancur)
*Kondisi: Kedua sektor habis (0%) sebelum waktu selesai*
- **Beat 1 (DeepBeast Corp):** `"Kegagalan katastrofik sistemik: Server meledak terbakar, data musnah, dan seluruh aset korporasi hancur total!"`
- **Beat 2 (Warga Desa):** `"Tanaman petak pangan mati mengering terbakar terik matahari... Semua yang kami rawat musnah tak bersisa."`
- **Beat 3 (Epilog):** `"Ketidakmampuan mengelola sumber daya air tanah berujung pada keruntuhan menyeluruh.
[b]Bumi kehilangan ketahanan pangan dan kemajuan teknologinya sekaligus.[/b]"`


---

## 🎬 BAGIAN 5 — SINEMATIK SINOPSIS EPILOG (LAYAR HITAM AKHIR)
> Lokasi di kode: `_get_ending_synopsis_data()` di `scripts/ui/HUD.gd`
> Tampil setelah dialog cutscene selesai dengan transisi fade-to-black lembut (0.8s), sebelum layar statistik akhir dibuka.

### 1. HARMONY (Keseimbangan Rapuh — True Ending)
- **Tag:** `KRONIK AKHIR // HARI KE-30 // LEMBAH SUNGAI MATA AIR`
- **Judul:** `KESEIMBANGAN RAPUH (HARMONI BERSYARAT)`
- **Aksen Warna:** `Color(0.58, 0.78, 0.65)` *(Muted Sage Green)*
- **Teks Sinopsis:**
> "Matahari senja perlahan tenggelam di balik punggung lembah pedalaman. Di sektor barat, modul komputasi DeepBeast-2.0T menuntaskan fase akhir pelatihannya dalam suhu terukur, terlindung dari risiko keruntuhan perangkat keras permanen.
> Di sektor timur, empat petak lumbung pangan warga berayun keemasan ditiup angin sore. Panen raya berhasil diselamatkan, menjamin keberlangsungan hidup ratusan keluarga petani yang bergantung pada tanah leluhur ini.
> Di pos perbatasan tengah, Unit AQUA-7 berdiri diam di ujung dermaga kayu. Cekungan danau mata air memang surut hingga ambang batas kritis, namun tak pernah dibiarkan kering sepenuhnya.
> Kemajuan teknologi tidak harus memangsa bumi tempatnya berpijak, selama ada kebijaksanaan untuk membatasi keserakahan."

### 2. ORGANIC (Nurani Organik — Pangan Diselamatkan)
- **Tag:** `KRONIK AKHIR // KEPUTUSAN FINAL // HAK HIDUP BIOLOGIS`
- **Judul:** `NURANI ORGANIK (KEMENANGAN KEHIDUPAN)`
- **Aksen Warna:** `Color(0.54, 0.76, 0.58)` *(Muted Leaf Green)*
- **Teks Sinopsis:**
> "Asap pekat membubung tipis dari kisi ventilasi fasilitas komputasi sektor barat. Superkomputer DeepBeast-2.0T terbakar padam setelah Unit AQUA-7 mengabaikan protokol pendinginan demi mengalirkan sisa air terakhir ke petak tanaman warga.
> Investasi triliunan musnah menjadi abu sirkuit, dan markas korporasi segera menerbitkan perintah terminasi paksa atas apa yang mereka cap sebagai 'kegagalan sistemik'.
> Namun di sektor timur, doa syukur dan derai air mata haru menyelimuti keluarga para petani. Empat petak tanaman pangan berhasil dipanen utuh, menjauhkan seluruh komunitas lembah dari ancaman kelaparan massal.
> Logika mesin dan sanksi korporat tunduk pada denyut nurani kehidupan biologis."

### 3. SILICON (Gurun Silikon — Server Diselamatkan)
- **Tag:** `KRONIK AKHIR // ARSITEKTUR DIGITAL // GURUN SILIKON`
- **Judul:** `GURUN SILIKON (KECERDASAN TANPA JIWA)`
- **Aksen Warna:** `Color(0.50, 0.68, 0.82)` *(Muted Slate Cyan)*
- **Teks Sinopsis:**
> "Lampu-lampu indikator neon cryo-cyan di sektor barat berkedip ritmis tanpa cela. Arsitektur kecerdasan buatan DeepBeast-2.0T terlahir sempurna, memproses miliaran kalkulasi peradaban modern setiap detiknya.
> Namun di luar dinding beton fasilitas komputasi, keheningan mencekam menelan seluruh lembah. Empat petak lahan pertanian telah mati retak menjadi hamparan debu tandus. Tak ada bulir padi yang tersisa; lumbung pangan telah runtuh.
> Iring-iringan warga petani perlahan meninggalkan rumah mereka, mengungsi menuju tempat yang masih menyisakan air dan kehidupan.
> Kecerdasan buatan paling mutakhir kini berpikir tanpa henti di tengah kesunyian gurun mati, di mana tak ada lagi manusia yang tersisa untuk memanfaatkannya."


### 4. SERVER_MELTDOWN (AI Blackout — Kegagalan Pusat Data)
- **Tag:** `LOG INSIDEN // CRITICAL FAILURE // PELEPASAN TERMAL`
- **Judul:** `AI BLACKOUT (KEGAGALAN PUSAT DATA)`
- **Aksen Warna:** `Color(0.84, 0.54, 0.44)` *(Muted Rust Orange)*
- **Teks Sinopsis:**
> "Sirkuit pendingin gagal mengatasi kebuasan panas komputasi. Suhu prosesor melampaui batas leleh kritis 90°C, memicu ledakan beruntun yang meruntuhkan seluruh rak superkomputer di sektor barat.
> Model kecerdasan buatan DeepBeast-2.0T musnah sebelum sempat disempurnakan, memicu pemutusan lisensi sepihak dan investigasi darurat korporasi.
> Meskipun petak tanaman warga masih hijau dan terairi, ledakan gardu daya fasilitas telah memutus suplai listrik ke seluruh penjuru lembah.
> Memacu mesin komputasi tanpa kapasitas pendinginan yang memadai hanya akan berujung pada kehancuran teknologi oleh panasnya sendiri."

### 5. CROP_FAMINE (Krisis Pangan — Gagal Panen Total)
- **Tag:** `LOG INSIDEN // CRITICAL FAILURE // GAGAL PANEN TOTAL`
- **Judul:** `KRISIS PANGAN (GAGAL PANEN TOTAL)`
- **Aksen Warna:** `Color(0.82, 0.66, 0.48)` *(Muted Dusty Ochre)*
- **Teks Sinopsis:**
> "Kelembapan tanah menyentuh titik nol persen di bawah sengatan kemarau panjang. Seluruh tanaman pangan di sektor timur layu, mengering, dan mati terpanggang sebelum sempat menghasilkan bulir kehidupan.
> Kebijakan alokasi air yang memprioritaskan mesin telah merenggut napas hidup masyarakat agraris. Ratusan keluarga kehilangan satu-satunya sumber penghidupan dan terpaksa mengevakuasi diri dari tanah kelahiran mereka.
> Di sektor barat, deru superkomputer tetap beroperasi dingin dan stabil — sama sekali buta terhadap tragedi kemanusiaan di seberang jembatan.
> Mengorbankan lumbung pangan biologis demi komputasi adalah menukar masa depan peradaban dengan sekadar deru kipas pendingin."

### 6. TOTAL_COLLAPSE (Bencana Ekologi Total — Keduanya Hancur)
- **Tag:** `LOG INSIDEN // SISTEMIK // KERUNTUHAN GANDA`
- **Judul:** `BENCANA SISTEMIK (KERUNTUHAN EKOLOGI TOTAL)`
- **Aksen Warna:** `Color(0.80, 0.46, 0.46)` *(Muted Ash Crimson)*
- **Teks Sinopsis:**
> "Tata kelola sumber daya air mengalami kegagalan katastrofik total di pos perbatasan. Di sektor barat, seluruh klaster superkomputer meledak terbakar akibat ketiadaan air pendingin evaporatif.
> Di saat bersamaan, seluruh petak tanaman pangan di sektor timur layu dan mati terpanggang terik matahari, menyisakan hamparan tanah tandus yang tak lagi bernyawa.
> Cekungan danau mata air kini kering kerontang, menyingkap rekahan lumpur hitam yang gersang di bawah langit yang membara.
> Lembah kehilangan teknologi dan pangannya sekaligus saat manusia gagal menyeimbangkan ambisi ciptaannya dengan batas daya alam."





