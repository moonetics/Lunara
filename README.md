<div align="center">

<img src="assets/images/logo_with_text.png" alt="Lunara Logo" width="300"/>

# Lunara
### Local-First Period & Health Companion

[![Flutter](https://img.shields.io/badge/Flutter-3.31+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Local-First](https://img.shields.io/badge/Architecture-100%25_Local--First-4CAF50?style=for-the-badge&logo=hive&logoColor=white)](https://pub.dev/packages/hive)
[![Medical](https://img.shields.io/badge/Evidence--Based-ACOG%20219%20%7C%20POGI%20%7C%20FIGO-E91E63?style=for-the-badge)](https://www.acog.org)
[![Tests](https://img.shields.io/badge/Tests-76%20Passing-brightgreen?style=for-the-badge)](https://github.com/moonetics/Lunara)

<p align="center">
  <b>Aplikasi pelacak menstruasi, kesuburan, dan kesehatan reproduksi modern berlandaskan sains kedokteran dengan privasi 100% offline (Local-First).</b>
</p>

</div>

---

## 🌟 Mengapa Lunara Berbeda?

Sebagian besar aplikasi pelacak siklus komersial mengunggah data intim pengguna ke server *cloud* pihak ketiga untuk keperluan monetisasi dan iklan. **Lunara dibangun dengan filosofi yang sepenuhnya bertolak belakang:**

1. **🔒 Privasi Mutlak (Zero-Cloud)**: Seluruh data medis, riwayat siklus, gejala, dan catatan keintiman disimpan secara lokal 100% di perangkat Anda menggunakan Hive NoSQL database. Tidak ada akun, tidak ada pelacakan analitik pihak ketiga, dan tidak ada kebocoran data.
2. **🧬 Evidence-Based & Klinis**: Algoritma tidak menebak-nebak, melainkan diimplementasikan secara deterministik mengacu pada literatur ginekologi resmi:
   - **ACOG Practice Bulletin No. 219** (Standar variasi fisiologis siklus normal 21–35 hari).
   - **Wilcox et al., NEJM (1995)** (Distribusi kurva probabilitas konsepsi harian jendela subur 6-hari).
   - **FIGO Menstrual Disorders Committee** (Klasifikasi etiologi perdarahan uterus).
   - **Konsensus POGI** (Perkumpulan Obstetri dan Ginekologi Indonesia).
   - **NICE Guidelines NG88** (Tatalaksana non-farmakologi sindrom pramenstruasi/PMS).
3. **🎨 Estetika Blush Rose & Cashmere Cream**: Antarmuka dirancang dengan empati, kehangatan, serta mematuhi standar aksesibilitas WCAG 2.1 AA/AAA (target sentuh minimum 48×48 dp dan tombol aksi utama 52 dp).

---

## ✨ Fitur Utama

### 🎯 1. Tiga Mode Pelacakan Cerdas (*Goal-Oriented Modes*)
Pengguna dapat berganti fokus pelacakan kapan saja melalui Pengaturan, dengan pembaruan tampilan visual secara instan (*real-time reactive*):
- **🌸 Pantau Kesehatan (General Health)**: Memetakan 4 fase hormonal (Menstruasi, Folikular, Ovulasi, Luteal) beserta wawasan fisiologis harian dan nutrisi.
- **👶 Program Hamil (Promil)**: Menyorot **Hari Emas Konsepsi (`⭐`)** pada H-2 s/d hari ovulasi berdasarkan studi Wilcox NEJM (probabilitas ~34–36%) dengan ritme hubungan intim selang-seling 1–2 hari sekali (ASRM) untuk kualitas sperma optimal.
- **🛡️ Tunda Hamil Alami (KB Alami / FABM)**: Menerapkan *Fertility Awareness-Based Method* yang menandai zona aman pasca-ovulasi dengan **Perisai Hijau (`🛡️`)** (risiko konsepsi 0%) dan memberikan edukasi kontrasepsi darurat 72 jam jika terjadi hubungan tanpa pengaman di masa subur.

### 📅 2. Kalender 4-Fase Dinamis & Interaktif
- **Perhitungan Ovulasi Dinamis**: Menggunakan rumus $Luteal_{fixed} = 14$ hari ($CycleLength - 14$) sehingga siklus panjang (misal 38 hari) tetap akurat dipetakan pada hari ke-24, bukan dipukul rata pada hari ke-14.
- **Smart Gap Detection**: Jeda pencatatan $>45$ hari dideteksi sebagai data terlewat (bukan siklus raksasa tunggal), menjaga rata-rata prediksi tetap bersih.
- **Decision-First Date Sheet**: Saat tanggal diklik, aplikasi langsung menjawab pertanyaan esensial: *"Apakah hari ini waktu yang tepat/aman untuk berhubungan intim?"* lengkap dengan estimasi peluang konsepsi dan panduan higienitas.

### 📑 3. Ekspor Rekam Medis Sp.OG (Standar A4 1 Halaman)
- **Kop Dokumen Resmi**: Format elegan yang siap ditunjukkan kepada Dokter Spesialis Obstetri & Ginekologi (Sp.OG) atau Bidan.
- **Penyajian Klinis Siklus Berjalan (Ongoing Cycle)**: Jika pasien baru mulai haid 1–2 hari, sistem mencatatnya sebagai `Sedang Berjalan` dan `Hari ke-N (Sedang Haid)` alih-alih siklus selesai, mencegah salah diagnosa perdarahan abnormal/oligomenorrhea serta tidak merusak rata-rata riwayat pasien.
- **Saklar Privasi Catatan Keintiman**: Memberikan kebebasan penuh pada pasien untuk menyertakan atau menyembunyikan riwayat aktivitas seksual 90 hari sebelum mencetak dokumen. Penomoran subjudul dokumen otomatis berurutan rapi.
- **Catatan Kaki Ilmiah Resmi**: Memuat sitasi resmi ACOG Bulletin 219 dan FIGO yang menjelaskan toleransi variasi fisiologis normal ($\le 9$ hari).

### 📊 4. Grafik Statistik & Tren Siklus (Clinical Insights)
- **Variabilitas Siklus 6 Bulan**: Visualisasi fluktuasi panjang siklus dengan bar chart kustom (bebas bloat library pihak ketiga).
- **Distribusi Gejala & Korelasi Nyeri**: Memetakan keluhan fisik dominan dan korelasi prostaglandin $PGF_{2\alpha}$.
- **Pustaka Pereda Nyeri Non-Farmakologi**: Panduan mandiri relaksasi, kompres hangat, magnesium, dan latihan pernapasan berbasis klinis.

### 🔐 5. Keamanan Biometrik & Notifikasi Lokal
- **Kunci Sidik Jari / Face Unlock**: Terintegrasi via `local_auth` dengan *grace period* 30 detik di latar belakang.
- **Pengingat Pintar 100% Offline**: Menggunakan `flutter_local_notifications` tanpa membutuhkan koneksi internet. Jadwal otomatis untuk H-2 haid, fase PMS, dan evaluasi keterlambatan.
- **Cadangan Data Offline (JSON)**: Ekspor dan pulihkan seluruh riwayat siklus dengan file terstruktur tanpa ketergantungan server cloud.

---

## 🏗️ Arsitektur & Teknologi

```
lib/
├── core/
│   ├── database/
│   │   ├── local_db_service.dart       # Hive service & configNotifier
│   │   └── models/                     # TypeAdapter: Cycle, Config, DailyEntry, Triage
│   ├── services/
│   │   ├── cycle_analytics_engine.dart # Engine analisis variabilitas ACOG
│   │   ├── cycle_engine.dart           # Perhitungan fase fisiologis & ovulasi
│   │   ├── notification_service.dart   # Notifikasi lokal terjadwal
│   │   ├── pdf_export_service.dart     # Generator laporan PDF rekam medis Sp.OG
│   │   └── triage_engine.dart          # Algoritma triage keterlambatan haid
│   └── theme/
│       ├── app_colors.dart             # Blush Rose, Sage Mint, Amethyst, Golden Amber
│       └── app_typography.dart         # Google Fonts Outfit
└── features/
    ├── calendar/                       # Grid kalender 4-fase & visual status
    ├── dashboard/                      # Ring fase hari ini, kartu fokus & quick-log
    ├── insights/                       # Grafik variabilitas siklus & rekam gejala
    ├── onboarding/                     # Setup awal fleksibel & profil
    ├── pain_relief/                    # Pustaka terapi pereda nyeri haid
    ├── pdf_export/                     # Dialog privasi & preview PDF A4
    ├── settings/                       # Pemilihan mode, biometrik & backup
    └── triage_delay/                   # Kuisioner mandiri keterlambatan siklus
```

### Tech Stack
- **Framework**: Flutter (v3.31+ / Material 3)
- **Language**: Dart (Sound Null Safety)
- **Local Storage**: [Hive](https://pub.dev/packages/hive) & [Hive Flutter](https://pub.dev/packages/hive_flutter)
- **PDF Engine**: [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)
- **Biometric Security**: [local_auth](https://pub.dev/packages/local_auth)
- **Local Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Typography**: [Google Fonts (Outfit)](https://pub.dev/packages/google_fonts)
- **State Management**: Reactive `ValueNotifier` & Pragmatic State Architecture

---

## 🚀 Memulai (Getting Started)

### Prasyarat
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.31.0 atau lebih baru)
- Android Studio / VS Code dengan ekstensi Flutter & Dart
- Perangkat Android fisik atau Emulator (Android 8.0+ / API 26+)

### Langkah Instalasi
1. **Clone repositori**:
   ```bash
   git clone https://github.com/moonetics/Lunara.git
   cd Lunara
   ```

2. **Unduh dependensi**:
   ```bash
   flutter pub get
   ```

3. **Jalankan pengujian (Unit & Widget Tests)**:
   ```bash
   flutter test
   ```
   *Seluruh 76 automated tests harus berstatus lulus 100%.*

4. **Jalankan aplikasi di perangkat**:
   ```bash
   flutter run
   ```

5. **Build APK Produksi**:
   ```bash
   flutter build apk --release
   ```

---

## 🧪 Pengujian & Kualitas Kode

Lunara memiliki cakupan uji otomatis yang ketat mencakup engine siklus, keteraturan ACOG, reaktivitas konfigurasi antar-layar, aksesibilitas target sentuh, serta integritas PDF:

```bash
flutter analyze   # 0 issues found (Strict linting)
flutter test      # 76 tests passing
```

| Modul Pengujian | Deskripsi |
|---|---|
| `reactive_config_and_pdf_privacy_test.dart` | Uji reaktivitas real-time `configNotifier`, saklar privasi keintiman PDF, penyajian siklus ongoing, dan catatan kaki ACOG 219. |
| `flexible_cycle_redesign_test.dart` | Uji pencatatan haid dinamis start/stop, input retroaktif lintas bulan, dan smart gap $>45$ hari. |
| `intimacy_recommendation_and_calendar_test.dart` | Uji probabilitas konsepsi harian Wilcox NEJM dan rekomendasi pengaman. |
| `ui_hierarchy_and_accessibility_test.dart` | Verifikasi standar aksesibilitas WCAG (target sentuh $\ge 48\times 48$ dp, tombol $\ge 52$ dp). |
| `triage_engine_test.dart` | Evaluasi red flags klinis dan variasi keterlambatan fisiologis. |

---

## 📚 Landasan Medis & Rujukan Ilmiah

- **ACOG Practice Bulletin No. 219**: *Diagnosis of Abnormal Uterine Bleeding in Reproductive-Aged Women*. American College of Obstetricians and Gynecologists.
- **Wilcox, A. J., Weinberg, C. R., & Baird, D. D. (1995)**: *Timing of sexual intercourse in relation to ovulation — effects on the probability of conception, study of the day-specific probabilities*. New England Journal of Medicine, 333(23), 1517–1521.
- **ASRM (American Society for Reproductive Medicine)**: *Optimizing natural fertility: a committee opinion*. Fertility and Sterility.
- **Konsensus POGI**: *Panduan Tata Laksana Perdarahan Uterus Abnormal dan Kesehatan Reproduksi*. Perkumpulan Obstetri dan Ginekologi Indonesia.
- **NICE Guideline NG88**: *Premenstrual syndrome: diagnosis and management*. National Institute for Health and Care Excellence.
- **Guyton and Hall Textbook of Medical Physiology**: *Female Reproductive Physiology Before Pregnancy and Female Hormones*.

---

## 📄 Disclaimer Medis

> **PENTING**: Lunara adalah alat bantu pemantauan mandiri dan pendukung gaya hidup sehat yang tidak menggantikan diagnosis medis profesional, saran dokter, maupun pemeriksaan klinis langsung. Jika Anda mengalami nyeri panggul hebat akut, perdarahan abnormal berkepanjangan, atau tanda bahaya (*red flags*), segera konsultasikan dengan Dokter Spesialis Obstetri dan Ginekologi (Sp.OG) atau fasilitas layanan kesehatan terdekat.

---

<div align="center">
  Dibuat dengan penuh dedikasi dan cinta untuk kesehatan reproduksi wanita.
  <br/>
  <b>© 2026 Lunara. 100% Local-First.</b>
</div>
