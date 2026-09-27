# Arsitektur Lengkap Lunara: Dari Konsep Awal Hingga Aplikasi Final

Dokumen ini mendokumentasikan secara komprehensif seluruh arsitektur sistem, evolusi pembentukan, lapisan teknis, alur data (*data flows*), dan landasan medis aplikasi **Lunara**.

---

## 1. Visi & Filosofi Rekayasa Produk

Lunara dirancang sebagai instrumen kesehatan reproduksi wanita yang menggabungkan presisi medis klinis dengan privasi mutlak dan empati humanis:

1. **Privasi Penuh (*Zero-Knowledge & Offline-First*)**:
   Data siklus haid, suasana hati, dan keintiman adalah data medis paling sensitif. Seluruh data diproses dan disimpan 100% di ruang penyimpanan lokal perangkat (Hive NoSQL). Tidak ada akun pengguna, tidak ada *tracking* pihak ketiga, dan tidak ada server *cloud* eksternal.
2. **Deterministik Medis Berbasis Bukti (*Evidence-Based Determinism*)**:
   Tidak menggunakan tebakan acak atau model AI yang berisiko halusinasi klinis. Seluruh rumus fisiologis, masa subur, skor keteraturan, dan pohon keputusan medis diturunkan langsung dari literatur baku:
   * **POGI (Perkumpulan Obstetri & Ginekologi Indonesia)**: Konsensus nasional tata laksana gangguan haid, dismenore, dan rujukan klinis dokter spesialis kandungan Indonesia.
   * **ACOG Practice Bulletin No. 219 & WHO**: Standar keteraturan siklus dan variabilitas fisiologis normal.
   * **NICE Clinical Guidelines NG88 (UK)**: Diagnosis dan manajemen *Premenstrual Syndrome (PMS)* dan *Premenstrual Dysphoric Disorder (PMDD)*.
   * **Guyton & Hall Fisiologi Kedokteran (Bab 82)**: Model 4 fase hormonal dan dinamika ovulasi.
   * **Speroff Clinical Gynecologic Endocrinology (Bab 11)**: Penilaian amenore sekunder dan poros HPO/HPA.
3. **Dual-Perspective & Dual-Goal**:
   * *Perspektif:* Ruang pribadi wanita (*Female Self*) dan mode pendamping pasangan (*Male Helper*).
   * *Tujuan:* Pemantauan kesehatan umum (*Health Tracking*) dan pencegahan kehamilan alami (*Natural Contraception / FABM*).

---

## 2. Peta Evolusi Pembentukan (Genesis Timeline)

```mermaid
timeline
    title Kronologi Pembentukan & Evolusi Fitur Lunara
    Fase 1 : Fondasi Database NoSQL (Hive)
           : Model Cycle, DailyEntry, AppConfig, TriageRecord
           : Manual TypeAdapters (Zero Build Runner Dependency)
    Fase 2 : Pure Dart Clinical Engines
           : CycleEngine (4 Fase Hormon & Gap Tolerance)
           : CycleAnalyticsEngine (ACOG Bulletin 219)
           : TriageEngine (Pohon Keputusan Telat Haid)
    Fase 3 : Desain Sistem & Dual-Perspective
           : Palet Terapeutik WCAG (Rose, Sage, Amethyst, Amber)
           : Mode Pria Peka (Partner Care Tips & Empathy Cards)
    Fase 4 : Fitur Medis Khusus & Tanda Bahaya (Red Flags)
           : Kuesioner Triage Medis H+3
           : Deteksi Darurat Sp.OG (Ektopik & Amenore 90 Hari)
           : Pustaka Pereda Nyeri Dismenore Non-Obat
    Fase 5 : Keamanan, Notifikasi, & Dokumen Dokter
           : Kunci Biometrik (PIN/Sidik Jari timeout 30 detik)
           : Notifikasi Pengingat Lokal Offline
           : Ekspor Laporan PDF Medis Dokter Sp.OG (%PDF Header)
    Fase 6 : Redesain Siklus Fleksibel (Flexible Logging)
           : Pencatatan Lintas Bulan (Cross-Month)
           : Toleransi Jeda Lupa Catat (Outlier Gap > 45 Hari)
           : Zero-State Handling Bersih
    Fase 7 : Glosarium Awam-Medis, FABM, & Daily Insights
           : Kamus Istilah Medis Awam (Dual-Label + Modal ℹ️)
           : Mode Pencegahan Kehamilan Alami (FABM)
           : Kartu Tips Fisiologis Harian (Nutrisi, Energi, Istirahat)
```

---

## 3. Diagram Arsitektur Berlapis (Layered Architecture Diagram)

Arsitektur Lunara mengadopsi pola *Clean Layered Architecture* dengan pemisahan tanggung jawab yang ketat:

```mermaid
flowchart TD
    subgraph UI_Layer ["Lapisan Presentasi (Presentation Layer)"]
        DASH["DashboardScreen<br/>(Ring Siklus, Tips Fisiologis, Banner FABM)"]
        TREND["CycleInsightsScreen<br/>(Statistik 6 Bulan, Skor ACOG, Grafik)"]
        LOG["QuickLogSheet<br/>(Input 1-Tap Gejala, Mood, Keintiman)"]
        TRIAGE["TriageQuestionnaireScreen<br/>(Diagnosis Telat Haid)"]
        PAIN["PainReliefScreen<br/>(Pustaka Terapi Dismenore)"]
        SET["SettingsScreen<br/>(Preferensi, Mode Pasangan, Biometrik)"]
        MODAL["MedicalTermBottomSheet<br/>(Kamus Istilah Medis Awam)"]
    end

    subgraph State_Layer ["Lapisan Manajemen Status (State Layer - Riverpod)"]
        NOTIFIER["CycleNotifier<br/>(State Controller)"]
        STATE["CycleState<br/>(Imutabel Snapshot: Active, Past, Average)"]
    end

    subgraph Domain_Layer ["Lapisan Medis & Domain (Pure Clinical Engines)"]
        CE["CycleEngine<br/>• 4 Fase Hormonal<br/>• Jendela Ovulasi<br/>• Analisis Konsepsi"]
        CAE["CycleAnalyticsEngine<br/>• Skor Keteraturan ACOG<br/>• Variabilitas Fisiologis<br/>• Analisis Gejala & Mood"]
        TE["TriageEngine<br/>• Evaluasi Faktor Telat Haid<br/>• Red Flag Ektopik & Kista<br/>• Panduan Gaya Hidup"]
        MTR["MedicalTermRegistry<br/>• 9 Glosarium Klinis<br/>• Padanan Bahasa Awam"]
    end

    subgraph Data_Layer ["Lapisan Data & Infrastruktur (Data Layer - Local Only)"]
        DB["LocalDbService (Hive Engine)"]
        BOX_C[("Box: cycles")]
        BOX_E[("Box: daily_entries")]
        BOX_T[("Box: triage_records")]
        BOX_A[("Box: app_config")]
        
        SRV_BIO["BiometricService (LocalAuth)"]
        SRV_NOTIF["NotificationService (LocalNotif)"]
        SRV_PDF["PdfExportService (PDF Generator)"]
        SRV_BACKUP["BackupService (JSON Engine)"]
    end

    %% Hubungan antar layer
    DASH --> NOTIFIER
    TREND --> NOTIFIER
    LOG --> NOTIFIER
    
    NOTIFIER --> STATE
    NOTIFIER --> DB
    
    STATE --> CE
    STATE --> CAE
    TRIAGE --> TE
    DASH --> MTR
    TREND --> MTR
    
    CE --> DASH
    CAE --> TREND
    TE --> TRIAGE
    MTR --> MODAL
    
    DB --- BOX_C
    DB --- BOX_E
    DB --- BOX_T
    DB --- BOX_A
    
    SET --> SRV_BIO
    SET --> SRV_BACKUP
    TREND --> SRV_PDF
    NOTIFIER --> SRV_NOTIF
```

---

## 4. Alur Kerja & Siklus Hidup Data (Data Flow Lifecycle)

### Alur 1: Pencatatan Siklus Normal & Kalkulasi Fisiologis
Alur ketika pengguna mencatat haid, menyelesaikan haid, dan melihat status fase tubuh:

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant UI as DashboardScreen
    participant Notifier as CycleNotifier
    participant DB as LocalDbService (Hive)
    participant Engine as CycleEngine
    
    User->>UI: Tekan Tombol "Mulai Haid"
    UI->>Notifier: startNewCycle(startDate)
    Notifier->>DB: Simpan CycleModel (isOngoing = true)
    Notifier->>DB: Perbarui riwayat siklus sebelumnya
    Notifier->>Engine: Hitung ulang averageCycleLength (Outlier Filtered)
    Notifier->>UI: Emisi CycleState Baru
    UI->>Engine: calculatePhase(activeCycle, avgLength)
    Engine-->>UI: CyclePhaseInfo (Fase Menstruasi, Tema Deep Berry Rose)
    UI-->>User: Cincin Siklus menampilkan status "Sedang Menstruasi"
```

---

### Alur 2: Evaluasi Keterlambatan Haid & Skrining Triage Klinis
Alur ketika siklus pengguna terlambat melewati tanggal estimasi normal:

```mermaid
flowchart TD
    START([Siklus Melewati Hari Estimasi]) --> CHECK_DELAY{Terlambat Berapa Hari?}
    
    CHECK_DELAY -->|1 - 2 Hari| EARLY[Variasi Fisiologis Ringan Normal]
    CHECK_DELAY -->|>= 3 Hari| PROACTIVE_BANNER[Muncul Banner Keterlambatan Proaktif]
    
    PROACTIVE_BANNER --> USER_ACTION[Pengguna Membuka Kuesioner Triage]
    USER_ACTION --> INPUT[Input: Nyeri Panggul Hebat?, Riwayat Hubungan?, Tes Pack?, Stres?, Diet?]
    
    INPUT --> TRIAGE_EVAL[TriageEngine.evaluate]
    
    TRIAGE_EVAL --> COND_PAIN{Nyeri Panggul Mendadak?}
    COND_PAIN -->|Ya| RED_FLAG_PAIN[RED FLAG: Waspada Kehamilan Ektopik / Torsi Ovarium -> Rujuk Sp.OG Darurat]
    
    COND_PAIN -->|Tidak| COND_90{Telat >= 90 Hari?}
    COND_90 -->|Ya| RED_FLAG_90[RED FLAG: Amenore Sekunder Kronis -> Rujuk Sp.OG]
    
    COND_90 -->|Tidak| COND_PREG{Ada Risiko Hubungan & Belum Tes?}
    COND_PREG -->|Ya| ADVICE_TEST[Rekomendasi Tes Pack Urine Pagi Hari]
    
    COND_PREG -->|Tidak| COND_STRESS{Skor Stres >= 4 atau Diet Ketat?}
    COND_STRESS -->|Ya| ADVICE_LIFESTYLE[Edukasi Penekanan Poros HPA / FHA Speroff Bab 11]
    COND_STRESS -->|Tidak| ADVICE_NORMAL[Variasi Fisiologis Normal Guyton & Hall]
```

---

### Alur 3: Mode Pencegahan Kehamilan Alami (Metode FABM)
Alur penentuan status risiko konsepsi saat mode pencegahan alami aktif:

```mermaid
flowchart TD
    START_FABM[Pengguna Mengaktifkan Mode FABM di Pengaturan] --> SAVE_CONFIG[AppConfigModel.appGoal = natural_contraception]
    SAVE_CONFIG --> DASHBOARD_LOAD[DashboardScreen Membaca Status Siklus]
    
    DASHBOARD_LOAD --> CHECK_ACTIVE{Ada Siklus Aktif?}
    CHECK_ACTIVE -->|Tidak| ZERO_STATE[Tampilkan Status: Siap Catat Siklus]
    CHECK_ACTIVE -->|Ya| CHECK_BLEEDING{Sedang Perdarahan Haid?}
    
    CHECK_BLEEDING -->|Ya| MENSTRUAL_SAFE[Status: 🩸 Menstruasi — Risiko Konsepsi Minimal]
    CHECK_BLEEDING -->|Tidak| CALC_WINDOW[CycleEngine.isDateInFertileWindow<br/>Target: Hari Ini | Ovulasi: Siklus - 14 Hari]
    
    CALC_WINDOW --> CHECK_FERTILE{Hari Ini Berada di H-5 s/d H+1 Ovulasi?}
    
    CHECK_FERTILE -->|Ya| HIGH_RISK[Badge: ⚠️ Zona Subur — Risiko Tinggi<br/>Warna: Amethyst / Oranye<br/>Aksi: Hindari penetrasi tanpa proteksi / gunakan kondom]
    
    CHECK_FERTILE -->|Tidak| LOW_RISK[Badge: 🛡️ Fase Rendah Risiko<br/>Warna: Sage Mint Herbal<br/>Aksi: Peluang pembuahan minimal menurut kalender]
```

---

### Alur 4: Ekspor Dokumen Medis PDF Dokter Sp.OG
Alur pembuatan rekam medis cetak satu halaman untuk konsultasi klinis:

```mermaid
sequenceDiagram
    autonumber
    actor User as Pasien / Pengguna
    participant UI as PatientInfoDialog
    participant ExportService as PdfExportService
    participant PDF as Dart PDF Engine
    participant OS as Platform Sharing / Preview
    
    User->>UI: Tap Ikon PDF di Layar Tren Siklus
    UI-->>User: Tampilkan Modal Input (Nama Pasien & Usia)
    User->>UI: Submit Data Pasien
    UI->>ExportService: generateMedicalReport(patientName, age, cycles, config)
    ExportService->>PDF: Susun Header Formal Klinis Lunara
    ExportService->>PDF: Render Tabel Metrik (Rata-rata, Variabilitas ACOG)
    ExportService->>PDF: Render Riwayat 6 Siklus Terakhir & Catatan Gejala
    ExportService->>PDF: Bubuhkan Catatan Disclaimer Medis ACOG 219
    PDF-->>ExportService: Uint8List (Header Valid %PDF-)
    ExportService-->>OS: Tampilkan Layar Pratinjau & Tombol Bagikan/Cetak
```

---

## 5. Peta Struktur Folder & Modul Codebase

```text
lib/
├── core/
│   ├── constants/
│   │   └── medical_constants.dart       # Ambang batas klinis (21-35h, jeda 45h, telat 3h, 90h)
│   ├── database/
│   │   ├── local_db_service.dart        # Pengelola singleton kotak penyimpanan Hive
│   │   └── models/
│   │       ├── app_config_model.dart    # Konfigurasi mode, biometrik, & tujuan FABM
│   │       ├── cycle_model.dart         # Entitas siklus, tanggal selesai, & jeda bolong
│   │       ├── daily_entry_model.dart   # Entitas log harian (gejala, mood, keintiman)
│   │       └── triage_record_model.dart # Riwayat hasil skrining telat haid
│   ├── services/
│   │   ├── backup_service.dart          # Ekspor & impor cadangan format JSON lokal
│   │   ├── biometric_service.dart       # Pengunci keamanan biometrik (PIN/Fingerprint)
│   │   ├── cycle_analytics_engine.dart  # Mesin statistik keteraturan ACOG Bulletin 219
│   │   ├── cycle_engine.dart            # Mesin fisiologi 4 fase Guyton & Hall & ovulasi
│   │   ├── notification_service.dart    # Penjadwal notifikasi pengingat lokal offline
│   │   ├── pdf_export_service.dart      # Generator berkas PDF laporan dokter Sp.OG
│   │   ├── sound_service.dart           # Pemutar nada denting santai sambutan
│   │   └── triage_engine.dart           # Pohon keputusan klinis keterlambatan siklus
│   ├── theme/
│   │   ├── app_colors.dart              # Palet warna terapeutik bersertifikasi kontras
│   │   ├── app_theme.dart               # Konfigurasi tema Material 3 global
│   │   └── app_typography.dart          # Skala tipografi Plus Jakarta Sans
│   └── widgets/
│       └── medical_term_bottom_sheet.dart # Kamus glosarium medis awam interaktif (ℹ️)
│
├── features/
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── cycle_insights_screen.dart # Layar statistik & tren siklus ACOG
│   │       └── dashboard_screen.dart      # Dasbor utama, cincin siklus, & tips harian
│   ├── onboarding/
│   │   └── presentation/
│   │       └── onboarding_screen.dart     # Pengenalan awal & pemilihan perspektif
│   ├── pain_relief/
│   │   └── presentation/
│   │       └── pain_relief_screen.dart    # Pustaka 4 terapi pereda dismenore non-obat
│   ├── pdf_export/
│   │   └── presentation/
│   │       ├── patient_info_dialog.dart   # Dialog masukan nama pasien cetak PDF
│   │       └── pdf_preview_screen.dart    # Layar pratinjau dokumen PDF laporan dokter
│   ├── quick_log/
│   │   └── presentation/
│   │       └── quick_log_sheet.dart       # Lembar input cepat gejala harian
│   ├── settings/
│   │   └── presentation/
│   │       ├── legal_info_sheets.dart     # Lembar kebijakan privasi & ketentuan medis
│   │       └── settings_screen.dart       # Layar konfigurasi fitur, FABM, & data
│   ├── tracker/
│   │   └── state/
│   │       ├── cycle_notifier.dart        # Pengelola mutasi status siklus (Riverpod)
│   │       └── cycle_state.dart           # Immutabel snapshot data siklus
│   └── triage_delay/
│       └── presentation/
│           └── triage_questionnaire_screen.dart # Kuesioner interaktif evaluasi telat haid
│
└── main.dart                            # Titik masuk utama aplikasi (Inisialisasi Hive)
```

---

## 6. Jaminan Mutu & Rangkaian Pengujian (*Quality Assurance*)

Aplikasi diproteksi dengan rangkaian pengujian otomatis (*automated tests*) yang memverifikasi setiap lapisan logika:

| Berkas Pengujian | Area yang Diuji | Standar Medis / Fungsional |
| :--- | :--- | :--- |
| `cycle_engine_test.dart` | 4 fase siklus, perkiraan tanggal haid, deteksi jeda bolong (*outlier gap* > 45h). | Guyton & Hall Bab 82 |
| `cycle_analytics_test.dart` | Klasifikasi keteraturan siklus (*very regular, regular, moderate, irregular*). | ACOG Bulletin No. 219 |
| `triage_engine_test.dart` | Deteksi bahaya ektopik (*severe pelvic pain*), amenore 90 hari, evaluasi stres & diet. | Speroff Bab 11 & ACOG |
| `flexible_cycle_redesign_test.dart` | Pencatatan fleksibel, haid lintas bulan, analisis konsepsi retroaktif, dan isolasi log. | Validasi Kalender Nyata |
| `phase5_security_notification_test.dart` | Batas timeout kunci biometrik (30 detik) dan tanggal evaluasi notifikasi H+3. | Keamanan & Penjadwalan |
| `phase6_7_release_test.dart` | Keabsahan Magic Bytes PDF (`%PDF-`) dan integritas skema cadangan JSON. | ISO 32000-1 (PDF Spec) |
| `medical_glossary_and_goal_test.dart` | Kelengkapan 9 kamus istilah medis awam dan serialisasi tujuan FABM. | Desain Sistem & Kamus |

**Tingkat Kelulusan Pengujian:** **50 / 50 Tests Passed (100% Green)**.
