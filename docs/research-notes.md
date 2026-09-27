# Research Notes & Clinical Knowledge Base
# SiklusKita (LunaCare)

Dokumen ini mendokumentasikan riset literatur medis resmi, benchmark kompetitor di pasar, serta pola interaksi UX yang menjadi dasar pengembangan aplikasi SiklusKita.

---

## 1. Basis Pengetahuan Medis Resmi (Clinical Gold Standards)

Aplikasi ini mendasarkan seluruh algoritma kalkulasi siklus, analisis keterlambatan, dan rekomendasi gaya hidup pada empat sumber literatur standar emas ginekologi:

### 1. Speroff's Clinical Gynecologic Endocrinology and Infertility (9th Edition)
- **Topik Kunci**: *Amenorrhea & Neuroendocrinology of the Menstrual Cycle* (Bab 11 & 12).
- **Mekanisme Fisiologis**:
  - Penekanan sekresi pulsatil hormon GnRH (*Gonadotropin-Releasing Hormone*) oleh nukleus arkuata di hipotalamus akibat aktivasi poros Hipotalamus-Pituitari-Adrenal (HPA) saat stres psikologis/fisik.
  - Penurunan frekuensi pulsa GnRH mencegah lonjakan LH (*Luteinizing Hormone surge*), sehingga sel telur tidak terlepas dari folikel De Graaf (anovulasi) dan siklus memanjang secara signifikan.

### 2. Guyton and Hall Textbook of Medical Physiology (14th Edition)
- **Topik Kunci**: *Female Physiology Before Pregnancy and Female Hormones* (Unit XIV, Bab 82).
- **Mekanisme Fisiologis**:
  - Pembagian 4 fase siklus ovarium dan endometrium:
    1. **Fase Menstruasi (Hari 1–5)**: *Progesterone withdrawal bleeding* akibat regresi korpus luteum.
    2. **Fase Folikular (Hari 6–13)**: Dominasi estrogen, perbaikan dinding endometrium, energi tubuh meningkat.
    3. **Fase Ovulasi (Hari 14–15)**: Lonjakan LH, pelepasan oosit, suhu basal naik sedikit ($0.3–0.5^\circ\text{C}$).
    4. **Fase Luteal (Hari 16–28)**: Dominasi progesteron; jika tidak terjadi fertilisasi, progesteron turun drastis menjelang hari ke-28, memicu gejala PMS (*Premenstrual Syndrome*).

### 3. ACOG (American College of Obstetricians and Gynecologists)
- **Rujukan**: *Practice Bulletin No. 219 - Screening and Management of Abnormal Uterine Bleeding* & *Committee Opinion No. 651 - Menstruation in Girls and Adolescents*.
- **Parameter Klinis**:
  - Durasi siklus normal: **21 hingga 35 hari**.
  - Durasi perdarahan normal: **2 hingga 7 hari**.
  - Volume perdarahan normal: **$30–80\text{ mL}$** per siklus.
  - Definisi klinis keterlambatan: Jika $>38$ hari (oligomenorrhea) atau tidak haid $\ge 3$ bulan berturut-turut pada wanita yang sebelumnya memiliki siklus teratur (amenore sekunder).

### 4. World Health Organization (WHO) Reproductive Health Library
- **Topik Kunci**: Efek kontrasepsi darurat (*levonorgestrel/ulipristal acetate*) dan variasi siklus iatrogenik.
- **Wawasan**: Penggunaan pil kontrasepsi darurat dalam siklus aktif dapat memajukan atau menunda haid berikutnya hingga $7$ hari tanpa menandakan patologi struktural.

---

## 2. Benchmark Kompetitor & Analisis Kesenjangan Pasar

| Aplikasi | Kelebihan | Kelemahan / Gap | Peluang SiklusKita |
|---|---|---|---|
| **Flo Health** | UI visual kaya, basis pengguna masif. | Sebagian besar fitur analitik terkunci paywall mahal; mode partner sangat terbatas; data rentan isu privasi komersial. | 100% gratis & privat, sinkronisasi partner mendalam dengan tips empati harian. |
| **Clue Period Tracker** | Pendekatan berbasis sains, UI gender-neutral. | Tidak ada fokus mendalam pada peran pendamping pasangan pria; navigasi logging agak padat. | Hadirkan dashboard khusus pria (*Partner View*) yang ramah instruksi. |
| **Stardust** | Privasi kuat (enkripsi lokal), tema estetik. | Kurang analitik proaktif ketika telat (hanya menampilkan hitungan mundur biasa). | Triage otomatis keterlambatan bertingkat + referensi buku teks transparan. |

---

## 3. Matriks Triage Klinis "Kenapa Telat" (Decision Tree Rules)

```text
[Input Pengguna: Haid Terlambat >= 3 Hari]
   │
   ├── Pertanyaan 1: Apakah ada hubungan intim tanpa proteksi?
   │     ├── YA ──> [Triage Result: Suspek Kehamilan Awal]
   │     │            • Rekomendasi: Tes kehamilan mandiri (Test Pack) urine pagi pertama.
   │     │            • Dasar Medis: Kadar hCG urine terdeteksi akurat sejak hari pertama telat haid (ACOG).
   │     └── TIDAK ──> (Lanjut ke Pertanyaan 2)
   │
   ├── Pertanyaan 2: Apakah mengalami stres berat, insomnia, atau beban emosi tinggi?
   │     ├── YA ──> [Triage Result: Supresi Poros HPA & Penundaan Ovulasi]
   │     │            • Rekomendasi: Relaksasi aktif, tidur cukup 7-8 jam, asupan magnesium & vit B6.
   │     │            • Dasar Medis: Speroff Bab 11 (Kortisol menekan pelepasan pulsa GnRH).
   │     └── TIDAK ──> (Lanjut ke Pertanyaan 3)
   │
   ├── Pertanyaan 3: Apakah ada diet drastis / penurunan BB mendadak / olahraga berat?
   │     ├── YA ──> [Triage Result: Functional Hypothalamic Amenorrhea (FHA)]
   │     │            • Rekomendasi: Perbaiki asupan karbohidrat & kalori, kurangi intensitas olahraga.
   │     │            • Dasar Medis: ACOG Bulletin 219 (Penurunan leptin menghambat siklus reproduksi).
   │     └── TIDAK ──> (Lanjut ke Pertanyaan 4)
   │
   ├── Pertanyaan 4: Apakah mengonsumsi kontrasepsi darurat atau obat kortikosteroid?
   │     ├── YA ──> [Triage Result: Variasi Siklus Akibat Fluktuasi Hormonal Eksogen]
   │     │            • Rekomendasi: Observasi selama 7-10 hari ke depan.
   │     └── TIDAK ──> (Lanjut ke Evaluasi Red Flags)
   │
   └── Evaluasi Red Flag: Apakah ada nyeri panggul hebat unilateral atau telat > 90 hari?
         ├── YA ──> [ALERT MERAH: RUJUK KE DOKTER SP.OG SEGERA]
         └── TIDAK ──> [Triage Result: Variasi Fisiologis Ringan (Observasi 3-5 Hari)]
```
