/// Konstanta Medis & Rujukan Klinis Standar Emas Lunara
/// Berdasarkan ACOG, Speroff, Guyton & Hall, serta WHO.
class MedicalConstants {
  MedicalConstants._();

  // Ambang Fisiologis Siklus (Hari)
  static const int normalMinCycleLength = 21;
  static const int normalMaxCycleLength = 35;
  static const int baselineDefaultCycleLength = 28;
  static const int baselinePeriodDuration = 5;

  // Ambang Filter Jeda Bolong (Outlier)
  static const int outlierGapThreshold = 45; // Jeda > 45 hari dianggap data bolong

  // Ambang Deteksi Keterlambatan
  static const int earlyDelayThreshold = 3;       // H+3: Triage proaktif muncul
  static const int significantDelayThreshold = 7; // H+7: Keterlambatan klinis bermakna
  static const int redFlagAmenorrheaThreshold = 90; // H+90: Amenore sekunder (Wajib Sp.OG)

  // Rujukan Literatur Medis Resmi
  static const String pogiCitation =
      'POGI (Perkumpulan Obstetri dan Ginekologi Indonesia) Konsensus Nasional Gangguan Haid & Dismenore.';
  static const String acogBulletinCitation =
      'ACOG (American College of Obstetricians and Gynecologists) Practice Bulletin No. 219: Screening and Management of Abnormal Uterine Bleeding.';
  static const String niceGuidelinesCitation =
      'NICE (National Institute for Health and Care Excellence) Clinical Guideline NG88: Premenstrual Syndrome (PMS & PMDD).';
  static const String speroffCitation =
      "Speroff's Clinical Gynecologic Endocrinology and Infertility (9th Ed), Chapter 11: Chronic Anovulation and the Amenorrheas.";
  static const String guytonHallCitation =
      'Guyton and Hall Textbook of Medical Physiology (14th Ed), Chapter 82: Female Physiology Before Pregnancy and Female Hormones.';
  static const String whoCitation =
      'WHO (World Health Organization) Selected Practice Recommendations for Contraceptive Use.';

  // Teks Disclaimer Medis
  static const String medicalDisclaimer =
      'Lunara adalah alat bantu pemantauan mandiri dan edukasi berbasis literatur kedokteran resmi. Analisis ini bukan merupakan diagnosis medis final atau pengganti pemeriksaan dokter spesialis obstetri & ginekologi (Sp.OG).';
}
