# DOKUMEN LORE & KONSEP GAME: COOLING THE BEAST
**Kompetisi:** Grafika Gametastic 2026 (Gamecomm Indonesia)  
**Tema Resmi:** Isu Lingkungan (*Save the Earth*)  
**Format Pengumpulan:** Web Playable (itch.io) & PC Standalone  
**Game Engine:** Godot Engine 4.4.x Stable (GL Compatibility / Web Export)  
**Legalitas Aset:** 100% Non-AI Art (Domain Publik CC0 & Manipulasi Engine Prosedural)

---

## 1. IDENTITAS GIM & SINOPSIS EKSEKUTIF

* **Judul Gim:** *Cooling The Beast*
* **Genre:** *Top-Down Eco-Resource Management, Time-Pressure Strategy & Narrative Dilemma*
* **Durasi Putaran:** 3 Shift Progresif (~3 – 5 Menit Total Gameplay)
* **Tagline:** *"Ketika satu tetes air menentukan masa depan: kecerdasan buatan atau kehidupan di bumi?"*

### Sinopsis Singkat:
Di tahun 2049, perlombaan kecerdasan buatan global mencapai titik kulminasi yang mengkhawatirkan. Korporasi teknologi membangun fasilitas komputasi super raksasa di pedalaman untuk melatih model AI *DeepBeast-2.0T*. Namun, ada harga mahal yang disembunyikan dari dunia: mesin tersebut membutuhkan jutaan liter air tawar dingin setiap hari agar tidak terbakar. 

Pemain mengendalikan **AQUA-7**, unit robot logistik hidrolik otonom yang ditempatkan di sebuah pos perbatasan. Di sebelah barat berdiri fasilitas *Mega Server AI*, di sebelah timur terbentang *Agri-Dome* (sawah pangan terakhir warga lokal), dan di tengah-tengah hanya tersisa satu kolam air tanah alami. Ketika gelombang panas global melanda dan jatah pasokan air dipangkas habis, AQUA-7 dihadapkan pada dilema moral yang nyata: mengalirkan air untuk mendinginkan mesin AI demi kemajuan teknologi, atau menyiram tanaman padi demi menyelamatkan ratusan keluarga petani dari kelaparan.

---

## 2. BOBOT SEMESTA & LORE NARRATIVE (*STORY WORLD*)

### 2.1 Konteks Realitas Dunia Nyata (*The Real-World Inspiration*)
Gim ini dirancang bukan dari fiksi ilmiah hampa, melainkan bertumpu pada **fakta krisis ekologis abad ke-21**:
* Menurut riset data center global, pelatihan satu model bahasa AI berskala besar mengonsumsi hingga ratusan ribu hingga jutaan liter air tawar untuk sistem pendingin evaporatif (*evaporative cooling system*).
* Pembangunan fasilitas data center di wilayah agraris sering kali menyedot akuifer air tanah setempat, menyebabkan sumur-sumur warga mengering dan lahan pertanian mengalami gagal panen.
* *Cooling The Beast* mengonversi paradoks modern ini menjadi mekanika permainan langsung: **Setiap megawatt komputasi yang kita nikmati di layar digital dibayar dengan tetesan air dan masa depan bumi.**

### 2.2 Profil Tokoh Utama: Unit AQUA-7
* **Kode Unit:** *AQUA-7 (Autonomous Quenching & Utility Automaton - Model 7)*
* **Pencipta:** Konsorsium Gabungan Biosfer-Teknologi.
* **Peran:** Robot silinder bertenaga surya yang dilengkapi tangki air internal 120 Liter, nosel semprot ganda bertekanan tinggi (*dual-nozzle hydro-dispenser*), dan sensor telemetri termal presisi.
* **Dilema Karakter:** AQUA-7 diprogram dengan dua protokol yang awalnya selaras namun kini saling bertentangan secara fatal:
  1. *Protokol Korporat (Directive Alpha):* Menjaga integritas perangkat keras server AI di atas ambang batas kritis (90°C).
  2. *Protokol Ekologis (Directive Gaia):* Menjaga kelembapan tanah tanaman pangan warga di atas titik layu permanen (30%).

### 2.3 Geografi Semesta: Titik Pertemuan Tiga Sektor
Peta permainan menggambarkan kontras visual dan filosofis yang tajam dalam satu layar terhubung:
1. **Sektor Barat — The Silicon Monolith (AI Data Center):**
   * Ruangan berlantai pelat baja dingin, dilindungi dinding beton industri, panel telemetri osiloskop, tabung pendingin cryo-cyan, dan 4 klaster rak server berdaya tinggi.
   * Representasi dari: Ambisi manusia tanpa batas, industrialisasi teknologi tinggi, dan komputasi tanpa empati alam.
2. **Sektor Tengah — Central Spring Reservoir (Sumber Air Bersih):**
   * Danau mata air alami dengan dermaga kayu dan dinding batu penahan erosi. Ketinggian air merefleksikan volume air yang tersisa secara realistis (memperlihatkan palung dalam saat penuh dan dasar tanah retak saat kering total).
   * Representasi dari: Sumber daya alam yang terbatas (*finite natural resource*) dan garis hidup kedua sektor.
3. **Sektor Timur — The Green Haven (Agri-Dome Farmland):**
   * Lahan tanah gambut subur yang dikelilingi pagar kayu pedesaan, pohon pinus rindang, semak belukar, ayam petelur yang berkeliaran, dan 4 petak sawah padi.
   * Representasi dari: Ketahanan pangan tradisional, kehidupan biologis, dan hak hidup masyarakat lokal.

---

## 3. KONSEP DESAIN GIM & CORE GAMEPLAY LOOP

### 3.1 Loop Permainan Inti (*The 4-Step Core Loop*)
```
  ┌──────────────────────────────────────────────────────────┐
  │ 1. AMBIL AIR (Fetch Water)                               │
  │    Isi tangki ransel 120L di Danau Tengah (<0.75 detik)  │
  └─────────────────────────────┬────────────────────────────┘
                                │
                                ▼
  ┌──────────────────────────────────────────────────────────┐
  │ 2. SPRINT & EVALUASI PRIORITAS (Navigate & Prioritize)   │
  │    Ikuti Panah 360° Neon: Sektor Server vs Sektor Sawah  │
  └─────────────────────────────┬────────────────────────────┘
                                │
                                ▼
  ┌──────────────────────────────────────────────────────────┐
  │ 3. AKSI PENYIRAMAN AREA (Multi-Target Wide Spray)        │
  │    Dinginkan Server Panas ATAU Siram Tanaman Kering      │
  └─────────────────────────────┬────────────────────────────┘
                                │
                                ▼
  ┌──────────────────────────────────────────────────────────┐
  │ 4. PERTAHANKAN EQUILIBRIUM SAMPAI SHIFT BERAKHIR         │
  │    Selamatkan kedua sektor sebelum timer habis           │
  └──────────────────────────────────────────────────────────┘
```

### 3.2 Karakteristik & Penyetelan Mekanika (*Fine-Tuned Mechanics*)
Untuk menciptakan pengalaman bermain yang memuaskan (*satisfying game feel*) dan adil:
* **Pergerakan Gesit & Lari Cepat (Dash):**
  * Kecepatan dasar robot disetel ke **190 px/s**, dengan tombol `[SHIFT]` memberikan dorongan lari cepat hingga **313.5 px/s** (1.65x).
* **Kapasitas Tangki Ransel 120 Liter:**
  * Memberikan kuota yang cukup untuk menyiram beberapa objek sekaligus sebelum harus kembali mengambil air.
* **Refill Kilat (< 0.75 detik):**
  * Kecepatan penyedotan air danau sebesar **160 Liter/detik**. Cukup berhenti sesaat di dekat dermaga dan menahan `[SPASI]`, tangki ransel langsung terisi penuh.
* **Penyiraman Multi-Target Simultan (*Wide Spray*):**
  * Robot tidak perlu membidik piksel secara kaku. Saat berada di antara 2 rak server atau 2 petak sawah, semprotan air akan membasahi dan mendinginkan **semua objek dalam radius interaksi secara bersamaan**.
* **Toleransi Krisis yang Adil (*Fair Challenge*):**
  * Laju pemanasan server diturunkan ke `2.2°C/s` dan laju pengeringan sawah ke `1.8%/s`.
  * Daya pendinginan mencapai `75°C/s` dan penyiraman sawah `80%/s`, membuat tindakan pemain terasa berdampak instan dan memuaskan.
  * Tanaman yang mencapai 0% memiliki masa tenggang (*grace period*) selama **12 detik** sebelum mati permanen.

---

## 4. SISTEM PANAH OBJEKTIF TUTORIAL (360° DYNAMIC GUIDING ARROW)

Agar pemain pemula maupun dewan juri langsung memahami apa yang harus dilakukan tanpa kebingungan:

1. **Panah Mengambang di Dunia (*In-World Orbital Arrow*):**
   * Mengorbit mulus di sekeliling badan robot AQUA-7 pada radius 46 px, selalu menunjuk dengan akurasi 360° ke arah target paling mendesak di peta.
   * **Hierarki Kode Warna Panah:**
     * 💧 **Cyan Neon (`#00e5ff`):** Aktif saat tangki robot menipis (< 20L), memandu kembali ke danau air bersih.
     * 🔥 **Merah Membara (`#ff4530`):** Berdenyut cepat saat ada Server Rack yang mengalami panas kritis (≥ 75°C).
     * 🥀 **Kuning Emas Amber (`#ffcc00`):** Berdenyut saat ada petak sawah yang mengalami kekeringan parah (≤ 30%).
     * ❄️ / 🌱 **Biru Es / Hijau Zamrud:** Mode pemeliharaan rutin saat kondisi kedua sektor stabil.
   * **Lingkaran Interaksi (*Action Pulse Ring*):** Saat robot sudah berada di dekat target (< 55 px), panah berubah menjadi cincin hijau berdenyut tanda tombol `[SPASI]` siap dieksekusi.

2. **Panel Status Objektif HUD (*Top Objective Tracker*):**
   * Terletak tepat di bagian tengah atas antarmuka layar.
   * Menampilkan arah panah kompas (`◄`, `▲`, `▼`, `►`), ikon tugas, teks instruksi dinamis (contoh: `SERVER OVERHEAT! (84°C)`), estimasi jarak meter (`18m`), dan petunjuk tombol aksi.
   * Dilengkapi bilah panduan kontrol ramah pemula di bagian bawah layar:  
     `◄ SEKTOR SERVER AI | [WASD] Gerak • Tahan [SHIFT] Lari Cepat • [SPASI] Siram / Ambil Air | SEKTOR SAWAH PANGAN ►`


---

## 5. STRUKTUR 3 SHIFT: ESKALASI KRISIS & PARADOKS ZERO-SUM

Permainan terbagi ke dalam 3 babak kerja (*shift*) berturut-turut yang menggambarkan degradasi lingkungan secara progresif:

### Shift 1: Protokol Standar (Tahun 2049)
* **Status Lingkungan:** Langit cerah, rumput hijau segar, udara sejuk.
* **Cadangan Danau:** Melimpah (**280 Liter**).
* **Kondisi Beban:** AI beroperasi pada beban dasar (*idle training*).
* **Fungsi Desain:** Fase tutorial bagi pemain untuk membiasakan diri dengan siklus mengambil air, berlari melintasi jembatan, dan menyiram tanaman serta server.

### Shift 2: Beban Komputasi Masif (Global Heat Wave)
* **Status Lingkungan:** Langit mulai menguning hangat, rumput sawah mengering kecokelatan.
* **Cadangan Danau:** Terpangkas ke **190 Liter**.
* **Kondisi Beban:** Pelatihan model AI 2.0T parameter diaktifkan secara global. Pemanasan server melonjak 1.15x dan pengeringan sawah naik 1.10x.
* **Laporan Satelit Intermission:** *"Krisis Ekstrem: Gelombang panas melanda. Sumber air bersih anjlok ke level merah! Kuota Shift 3 dipangkas darurat HANYA 110L! Air sangat terbatas untuk kedua sektor."*

### Shift 3: Dilema Pengorbanan (Zero-Sum Survival)
* **Status Lingkungan:** Langit memerah membara, partikel bara api dan abu berterbangan di udara, tanah gambut retak.
* **Cadangan Danau:** Krisis kritis (**110 Liter**).
* **Kondisi Beban:** Pemanasan server naik 1.45x, pengeringan sawah 1.35x.
* **Fungsi Desain:** **Zero-Sum Game murni.** Air 110 Liter tidak lagi cukup untuk mempertahankan kedua sektor secara sempurna. Pemain dipaksa menghitung setiap tetes air atau mengambil keputusan moral: sektor mana yang harus dikorbankan?

---

## 6. CABANG MORAL & MATRIKS AKHIR PERMAINAN (*ENDINGS*)

Hasil akhir permainan ditentukan sepenuhnya oleh rekam jejak keputusan pemain di akhir Shift 3:

| Kode Ending | Judul Ending | Syarat Kondisi Pemain | Pesan Filosofis & Narasi Penutup |
| :---: | :--- | :--- | :--- |
| **`HARMONY`** | **ENDING 1/3: KESEIMBANGAN RAPUH (TRUE ENDING)** | Ketahanan Pangan $\ge 35\%$ **DAN** Integritas Server $\ge 25\%$ | Melalui kalkulasi presisi mikroliter, Unit AQUA-7 berhasil mempertahankan kedua sektor di tepi jurang kehancuran. Manusia dan kecerdasan buatan bertahan hidup berdampingan. **Bukti bahwa kemajuan teknologi masa depan tidak harus membunuh bumi tempatnya berpijak.** |
| **`ORGANIC`** | **ENDING 2/3: NURANI ORGANIK (PANGAN DISELAMATKAN)** | Ketahanan Pangan $>$ Integritas Server | Unit AQUA-7 melanggar direktif korporasi komputasi demi mengalirkan sisa air terakhir ke sawah warga. Model AI gagal dilatih dan data center terbakar, namun ratusan keluarga petani selamat dari kelaparan. **Logika mesin tunduk pada nurani kehidupan.** |
| **`SILICON`** | **ENDING 3/3: GURUN SILIKON (SERVER DISELAMATKAN)** | Integritas Server $>$ Ketahanan Pangan | Unit AQUA-7 mematuhi direktif korporasi AI global. Mega server berhasil didinginkan, namun sawah warga mati menjadi debu tandus. **AI tercerdas di dunia kini berpikir di atas bumi yang mati kelaparan.** |
| **`TOTAL_COLLAPSE`** | **BENCANA EKOLOGI TOTAL (EARLY DEFEAT)** | Server hancur ($0\%$) ATAU Sawah mati ($0\%$) sebelum Shift 3 | Ketidakmampuan mengelola sumber daya menyebabkan keruntuhan total ekosistem dan fasilitas komputasi. **Bumi kehilangan pangan dan teknologinya sekaligus.** |


---

## 7. KONSOL CHEAT & ALAT PENGUJIAN PENGEMBANG (*DEV CONSOLE*)

Guna memudahkan pengujian seluruh variasi shift, balancing, dan pencapaian ending oleh pengembang maupun dewan juri lomba, gim dilengkapi menu rahasia di layar jeda:

* **Cara Mengakses:** Tekan tombol **`[ESC]`** saat bermain untuk membuka menu jeda, atau gunakan tombol pintas keyboard langsung:
  * **`[F1]` — Kebal Durabilitas (God Mode):** Integritas server dan pangan terkunci 100%, laju panas dan kering menjadi 0, serta air tangki tak terbatas.
  * **`[F2]` — Kecepatan Waktu (Speed Multiplier):** Mengubah siklus waktu shift antara `1X (Normal 60s)`, `5X (Cepat 12s)`, hingga `10X (Ultra Cepat 6s)`.
  * **`[F3]` — Selesaikan Shift Seketika:** Memajukan timer sisa shift ke 0.2 detik agar putaran shift langsung tuntas dengan sukses.
  * **`[F4]` — Lompat ke Shift 1 (2049):** Memuat ulang kondisi awal dengan danau 280L.
  * **`[F5]` — Lompat ke Shift 2 (Beban AI):** Menguji kondisi gelombang panas dengan danau 190L.
  * **`[F6]` — Lompat ke Shift 3 (Krisis Air):** Menguji langsung klimaks zero-sum dan validasi ketiga variasi ending.

---

## 8. KEPATUHAN REGULASI & DAFTAR ASET LEGAL (100% NON-AI)

Sesuai aturan mutlak panitia Grafika Gametastic 2026:

1. **Bebas Generator Difusi AI:** Seluruh tekstur, sprite, dan visual dibuat dengan tangan murni atau bersumber dari pustaka berlisensi domain publik:
   * **Tile Tanah & Dinding Bangunan:** Kenney CC0 Roguelike/Industrial Pack & 32x32 Pixel Art CC0.
   * **Properti Interior Cyberpunk:** Spritesheet *pixel-cyberpunk-interior* CC0 (tabung pendingin, monitor telemetri, panel gardu daya, kabel lantai, pemadam api).
   * **Properti Pertanian:** Aset 2D CC0 Public Domain (bibit padi, tanaman layu, pagar pembatas, tanaman hias, ayam animasi).
   * **Visual FX & Shader:** Godot CanvasItem Shaders prosedural (denyut emisi LED, outline siluet saat tertutup dinding, partikel uap dan percikan air murni CPU Particles).
2. **Format Audio Kompatibel Web:**
   * **BGM:** Musik latar loop berformat `.ogg` berlatensi rendah.
   * **SFX:** Efek suara interaksi tombol, pengisian air, siraman, dan alarm bahaya berformat `.wav` dan `.ogg` legal bebas royalti.

---

## 9. KESIMPULAN & PESAN KARYA BAGI DEWAN JURI

*Cooling The Beast* mendemonstrasikan bahwa tema lingkungan hidup (*Save the Earth*) tidak harus selalu disajikan dalam bentuk memungut sampah konvensional. Gim ini mengangkat isu **konsumsi air raksasa industri kecerdasan buatan** yang sangat relevan dengan zaman sekarang, membungkusnya dalam mekanika manajemen sumber daya yang adil, responsif, dan kaya secara emosional.

Pemain diajak untuk merasakan sendiri ketegangan menjadi penjaga perbatasan antara alam dan teknologi, di mana setiap liter air memiliki bobot nyata bagi keberlangsungan bumi.

