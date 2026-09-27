# AI Coding Agent Handoff Document (v2.2 Phased Edition)
# Lunara — Flutter (100% Local-First, Evidence-Based & Smart Gap Handling)

Dokumen ini adalah cetak biru implementasi teknis untuk AI Coding Agent (seperti Antigravity, Cursor, Claude Code, atau Codex).

---

## 💡 Strategi Eksekusi: 1 Prompt Raksasa vs Prompt Per Fase?

> **Rekomendasi Utama: Gunakan Prompt Per Fase (Phased Execution).**

Jika Anda meminta AI membuat seluruh aplikasi 20+ file sekaligus dalam 1 prompt raksasa, AI sering mengalami **kelelahan konteks (*context exhaustion*)**, menghasilkan kode terpotong (*truncated code*), metode kosong (`// TODO: implement later`), atau inkonsistensi dependensi.

Dengan **Prompt Per Fase**, kita memandu AI mengeksekusi modul demi modul secara terarah, memastikan setiap fase dapat di-*run* dan diuji terlebih dahulu sebelum melanjutkan ke fase berikutnya.

Namun, dokumen ini menyediakan **KEDUA OPSI**:
- **Opsi A**: 7 Prompt Modular Per Fase *(Sangat Direkomendasikan)*
- **Opsi B**: 1 Master Prompt Lengkap

---

## 🚀 OPSI A: 7 Prompt Modular Per Fase (Siap Salin-Tempel)

---

### 📦 FASE 1: Fondasi Proyek, Database Lokal & Tema Material 3
> **Fokus**: Setup proyek Flutter bersih, konfigurasi Hive local storage, model data utama, dan palet warna terapeutik.

```markdown
Tolong kerjakan FASE 1 pengembangan aplikasi Flutter "Lunara" berdasarkan docs/PRD.md.

Tugas Fase 1:
1. Inisialisasi proyek Flutter (jika belum) dan setup dependensi di `pubspec.yaml`:
   - `hive_flutter`, `hive`, `path_provider` (untuk local database)
   - `flutter_riverpod` (atau `provider`) untuk state management
   - `intl` (date formatting)
   - `flutter_svg` / `google_fonts` (opsional untuk tipografi)
2. Setup Palet Tema Material 3 di `core/constants/app_colors.dart`:
   - Primary: Sage Green (#6B8E78 / #8FA998)
   - Background/Surface: Warm Cream (#FBF9F5)
   - Accent/Muted Pink: Dusty Rose (#D9A5B3)
   - Text/Card: Dark Slate (#2D3748)
3. Buat Hive Model & TypeAdapters di `core/database/models/`:
   - `AppConfigModel`: Menyimpan mode perspektif ("female_self" vs "male_helper"), nama pasangan, status biometrik aktif.
   - `CycleModel`: `cycleId`, `startDate`, `endDate`, `cycleLengthDays`, `isOutlier`.
   - `DailyEntryModel`: `entryId`, `cycleId`, `entryDate`, `flowIntensity`, `mood`, `symptoms`, `notes`.
   - `TriageRecordModel`: `triageId`, `date`, `daysDelayed`, `probableCause`, `recommendations`, `isRedFlag`.
4. Buat `LocalDbService` untuk inisialisasi Hive Box dan CRUD dasar.
5. Setup file `main.dart` agar menginisialisasi Hive dan menjalankan `runApp` dengan tema Material 3.

Pastikan kode bebas error linter (`flutter analyze` bersih) dan siap dijalankan.
```

---

### ⚙️ FASE 2: Cycle Engine & Smart Gap Handling Algorithm
> **Fokus**: Algoritma kalkulasi siklus, penyaringan data bolong (> 45 hari), dan input riwayat masa lalu (*backfill*).

```markdown
Tolong kerjakan FASE 2 aplikasi Lunara: Implementasi Cycle Engine & Gap Handling sesuai docs/PRD.md Bagian 6 dan docs/research-notes.md.

Tugas Fase 2:
1. Buat service `core/services/cycle_engine.dart`:
   - Method `calculateAverageCycleLength(List<CycleModel> pastCycles)`:
     * Menyaring hanya siklus fisiologis valid ($21 \le \text{hari} \le 45$).
     * Mengabaikan jeda bolong ($>45$ hari) dari pembagi rata-rata.
     * Default baseline 28.0 hari jika data riwayat masih kosong.
   - Method `getCurrentPhase(DateTime lastPeriodDate, double avgCycleLength)`:
     * Menghitung fase saat ini: Menstruasi (H1-H5), Folikular (H6-H13), Ovulasi (H14-H15), Luteal/PMS (H16-akhir).
   - Method `calculateNextPeriodDate(DateTime lastPeriodDate, double avgCycleLength)`.
   - Method `calculateDelayDays(DateTime expectedDate)`: Mengembalikan jumlah hari telat jika hari ini > tanggal estimasi.
2. Buat Unit Test di `test/cycle_engine_test.dart` untuk menguji:
   - Skenario siklus normal teratur (28 hari).
   - Skenario data bolong (Januari ke Maret dengan jeda 61 hari berhasil diabaikan).
3. Buat State Management (`CycleNotifier` / `CycleController`) untuk mengelola daftar siklus aktif dan riwayat lampau.

Pastikan seluruh unit test lulus (`flutter test`).
```

---

### 📱 FASE 3: Onboarding Perspektif & Dashboard Utama (Dual-Perspective)
> **Fokus**: Antarmuka pemilihan peran ("Saya Wanita" / "Saya Membantu"), Quick-Log 3-detik, dan Partner Care Widget.

```markdown
Tolong kerjakan FASE 3 aplikasi Lunara: Onboarding & Dashboard Utama sesuai docs/PRD.md Bagian 4 & 7.

Tugas Fase 3:
1. Layar Onboarding (`features/onboarding/onboarding_screen.dart`):
   - Pilihan interaktif 2 mode: "Saya Mencatat untuk Diri Sendiri" (Wanita) ATAU "Saya Membantu Mencatatkan Pasangan" (Pria).
   - Form input ramah: Tanggal mulai haid terakhir + opsi input riwayat bulan lalu yang masih diingat (Historical Backfill).
   - Simpan ke `AppConfigModel` dan navigasi ke Dashboard.
2. Dashboard Utama (`features/dashboard/dashboard_screen.dart`):
   - Bagian Atas: Lingkaran visual status siklus (Cycle Wheel / Progress Ring), nama fase hari ini, dan hitungan mundur haid berikutnya.
   - Banner Proaktif: Jika terlambat $\ge 3$ hari, munculkan tombol mencolok *"Cek Kemungkinan Penyebab Medis"*.
   - Mode Pria Spesifik: Tampilkan widget `PartnerCareWidget` berisi panduan tindakan harian (Do's & Don'ts) yang relevan dengan fase siklus pasangannya hari ini.
3. Bottom Sheet Quick-Log 3-Detik (`features/quick_log/quick_log_sheet.dart`):
   - Pilihan 1-tap: Status Darah (Spotting, Ringan, Sedang, Banyak, Selesai).
   - Pilihan 1-tap: Mood (Senang, Tenang, Lelah, Cemas, Sensitif).
   - Pilihan 1-tap: Gejala Fisik (Kram Perut, Pusing, Kembung, Pegal Pinggang).
   - Tombol "Simpan" langsung memperbarui database lokal secara instan.

Pastikan UI halus, responsif, dan tombol nyaman disentuh (minimal 48x48 dp).
```

---

### 🩺 FASE 4: Smart Delay Triage & Clinical Evidence Cards
> **Fokus**: Kuesioner evaluasi keterlambatan 1 menit, aturan deterministik ACOG/Speroff, kartu sitasi medis, dan alert Red Flag.

```markdown
Tolong kerjakan FASE 4 aplikasi Lunara: Modul Triage Keterlambatan Siklus & Sitasi Medis sesuai docs/PRD.md Bagian 5 & 8 serta docs/research-notes.md.

Tugas Fase 4:
1. Buat `core/services/triage_engine.dart`:
   - Algoritma pohon keputusan klinis deterministik berdasarkan input 5 pertanyaan:
     1. Aktivitas seksual & tes kehamilan (hCG)
     2. Tingkat stres 2 minggu terakhir (relasi dengan kortisol & GnRH)
     3. Diet drastis / penurunan berat badan (relasi dengan leptin & FHA)
     4. Aktivitas fisik berlebih
     5. Obat / kontrasepsi darurat
   - Evaluasi tanda bahaya (Red Flag): Nyeri akut hebat atau keterlambatan $>90$ hari.
2. Layar Kuesioner Triage (`features/triage_delay/triage_questionnaire_screen.dart`):
   - 5 pertanyaan interaktif satu per satu atau dalam form ringkas yang selesai dalam 1 menit.
3. Layar Hasil Evaluasi (`features/triage_delay/triage_result_screen.dart`):
   - Ringkasan faktor kemungkinan biologis dalam bahasa awam yang menenangkan.
   - Komponen `MedicalCitationCard`: Badge "Dasar Medis" yang dapat diketuk untuk membuka kutipan asli buku teks kedokteran (ACOG Bulletin 219, Speroff Bab 11, Guyton Bab 82).
   - Banner Merah Red Flag jika terdeteksi indikasi bahaya, berisi anjuran tegas untuk segera periksa ke dokter Sp.OG.

Pastikan tidak ada diagnosa mengikat, melainkan evaluasi kemungkinan biologis yang mendidik.
```

---

### 🔒 FASE 5: Kunci Biometrik & Notifikasi Pengingat Lokal
> **Fokus**: Keamanan privasi aplikasi menggunakan fingerprint/PIN Android (`local_auth`) dan alarm pengingat offline (`flutter_local_notifications`).

```markdown
Tolong kerjakan FASE 5 aplikasi Lunara: Fitur Keamanan Biometrik & Notifikasi Lokal Offline sesuai docs/PRD.md (FR-012 & FR-013).

Tugas Fase 5:
1. Tambahkan dependensi di `pubspec.yaml`:
   - `local_auth` (untuk Fingerprint / Face Unlock / PIN Android)
   - `flutter_local_notifications` (untuk notifikasi offline terjadwal)
   - `timezone` (untuk penjadwalan alarm waktu lokal)
2. Konfigurasi Android Native:
   - Tambahkan permission biometrik di `AndroidManifest.xml` (`USE_BIOMETRIC` & `USE_FINGERPRINT`).
   - Tambahkan permission alarm di `AndroidManifest.xml` (`SCHEDULE_EXACT_ALARM` & `POST_NOTIFICATIONS`).
3. Buat Service Biometrik (`core/services/biometric_service.dart`):
   - Cek ketersediaan sensor biometrik di perangkat.
   - Method `authenticate()` dengan dialog lokal bawaan Android.
   - Pintu gerbang di `main.dart` / Splash Screen: Jika biometrik diaktifkan pengguna di Pengaturan, wajib verifikasi sebelum menampilkan Dashboard.
4. Buat Service Notifikasi (`core/services/notification_service.dart`):
   - Inisialisasi channel notifikasi Android.
   - Jadwalkan pengingat otomatis:
     * H-2 sebelum tanggal estimasi haid berikutnya ("Hai, perkiraan haidmu 2 hari lagi...").
     * Pengingat saat masuk fase Luteal / PMS untuk mode pria pendamping.
     * Pengingat lembut saat siklus terdeteksi terlambat.
5. Tambahkan sakelar toggle di Layar Pengaturan untuk mengaktifkan/menonaktifkan Biometrik dan Notifikasi.

Uji fungsi biometrik dan pastikan aplikasi tidak freeze saat prompt muncul.
```

---

### 📄 FASE 6: Ekspor PDF Rekam Medis & Pustaka Solusi Mandiri Pereda Nyeri
> **Fokus**: Pembuatan dokumen PDF 1 lembar untuk dokter kandungan (`pdf`, `printing`) dan modul edukasi pereda kram tanpa obat berbasis ACOG.

```markdown
Tolong kerjakan FASE 6 aplikasi Lunara: Ekspor Ringkasan PDF untuk Dokter & Pustaka Solusi Nyeri sesuai docs/PRD.md (FR-014 & FR-015).

Tugas Fase 6:
1. Tambahkan dependensi di `pubspec.yaml`:
   - `pdf` dan `printing`
2. Buat Layar Pustaka Solusi Mandiri (`features/pain_relief/pain_relief_screen.dart`):
   - Penjelasan biologis kram haid (zat prostaglandin F2-alpha di rahim - Guyton & Hall).
   - 4 Solusi Non-Obat Terbukti Klinis:
     1. Terapi Hangat Lokal ($40^\circ\text{C}$ kompres perut bawah setara efektivitas pereda nyeri).
     2. Asupan Magnesium & B6 (relaksasi tonus otot uterus).
     3. Teh Jahe & Hidrasi (menghambat biosintesis prostaglandin).
     4. Pose Peregangan Yoga Ringan (Child's Pose & Cat-Cow).
3. Buat Service Pembuat PDF (`core/services/pdf_export_service.dart`):
   - Menghasilkan dokumen PDF 1 halaman berdesain bersih & profesional:
     * Header: "Ringkasan Riwayat Siklus Menstruasi - Pasien Lunara"
     * Data Kunci: Tanggal HPHT terakhir, rata-rata panjang siklus, jumlah siklus tercatat.
     * Tabel Riwayat 6 Bulan Terakhir: Tanggal mulai, durasi perdarahan, intensitas darah, dan keluhan utama (kram, sakit kepala, dll.).
     * Catatan untuk Dokter Sp.OG.
   - Integrasikan dengan tombol "Cetak / Bagikan PDF" menggunakan widget `Printing.sharePdf`.

Pastikan tampilan PDF rapi dan tata letak tidak terpotong saat diekspor.
```

---

### 🚀 FASE 7: Kalender Interaktif, Backup JSON & APK Release Build
> **Fokus**: Tampilan kalender riwayat lengkap dengan penanda gap, fitur backup/restore JSON lokal, audit akhir, dan build APK.

```markdown
Tolong kerjakan FASE 7 aplikasi Lunara: Kalender Lengkap, Backup Lokal & Persiapan Rilis APK sesuai docs/PRD.md.

Tugas Fase 7:
1. Kalender Siklus Bulanan (`features/calendar/calendar_screen.dart`):
   - Kalender visual bulanan dengan pewarnaan fase: Merah muda (Haid), Ungu lembut (Masa Subur/Ovulasi), Kuning tenang (Luteal/PMS).
   - Penanda Visual Jeda Bolong: Garis putus-putus pada bulan yang terlewat dicatat dengan opsi tombol *"Tambah Data Bulan Ini"*.
   - Fitur edit retroaktif: Kemampuan mengubah atau menghapus data tanggal haid lampau.
2. Cadangkan & Pulihkan Data Lokal (`core/services/backup_service.dart`):
   - Tombol "Cadangkan Data": Menghasilkan string file JSON berisi seluruh data siklus lokal untuk disimpan/dikirim via share sheet.
   - Tombol "Pulihkan Data": Mengimpor file JSON cadangan kembali ke Hive database.
3. Audit Akhir & Release Build:
   - Jalankan `flutter analyze` dan pastikan 0 error / warning.
   - Pastikan seluruh fitur bekerja 100% tanpa internet (mode pesawat).
   - Build file APK release Android: `flutter build apk --release`.
   - Laporkan lokasi file APK yang dihasilkan agar siap dipasang di ponsel pengguna dan pasangannya.
```

---

## ⚡ OPSI B: Master Kickoff Prompt (1 Single Prompt)

Jika Anda ingin menjalankan AI agent dalam 1 instruksi menyeluruh sekaligus:

```markdown
Halo! Tolong buatkan aplikasi Flutter Android "Lunara" berbasis 100% Local-First (tanpa backend/cloud/Firebase) secara lengkap dan siap pakai berdasarkan seluruh spesifikasi di `docs/PRD.md`, `docs/decision-log.md`, dan `docs/research-notes.md`.

Daftar Modul yang Wajib Ada:
1. Arsitektur Bersih Local-First (Hive Storage + Riverpod/Provider + Material 3 Sage Green).
2. Onboarding Dual-Perspective (Mode Wanita Mandiri vs Mode Pria Membantu Pasangan).
3. Cycle Engine dengan Smart Gap Handling (Mengabaikan jeda bolong > 45 hari dari rumus rata-rata siklus).
4. Quick-Log 3-Detik di dashboard (Status darah, mood, gejala).
5. Partner Care Widget (Panduan tindakan Do's & Don'ts harian untuk pria).
6. Smart Delay Triage (Kuesioner 1 menit saat telat >= 3 hari + Badge rujukan buku ACOG/Speroff/Guyton + Alert Red Flag ke Sp.OG).
7. Kunci Privasi Aplikasi dengan Biometrik Fingerprint / PIN (`local_auth`).
8. Notifikasi Pengingat Lokal Offline Android (`flutter_local_notifications`).
9. Pustaka Solusi Mandiri Pereda Nyeri & Kram (Evidence-based remedies).
10. Ekspor PDF Rekam Medis Siklus 1 Halaman untuk Dokter Sp.OG (`pdf`, `printing`).
11. Kalender Bulanan dengan penanda data bolong & Backup/Restore data lokal .JSON.

Tolong mulai dengan `/plan` arsitektur file lengkap terlebih dahulu sebelum menulis implementasi kodenya.
```
