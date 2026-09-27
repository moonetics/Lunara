import '../constants/medical_constants.dart';

/// Data Masukan Kuesioner Triage Medis
class TriageInput {
  final int daysDelayed;
  final bool hasPregnancyRisk;
  final bool pregnancyTestTaken;
  final String pregnancyTestResult; // 'negative', 'positive', 'not_tested'
  final int stressLevel; // 1 (Rendah) s/d 5 (Sangat Tinggi)
  final bool drasticDietOrWeightChange;
  final bool intenseExercise;
  final bool emergencyContraceptive;
  final bool severePelvicPain;

  const TriageInput({
    required this.daysDelayed,
    this.hasPregnancyRisk = false,
    this.pregnancyTestTaken = false,
    this.pregnancyTestResult = 'not_tested',
    this.stressLevel = 1,
    this.drasticDietOrWeightChange = false,
    this.intenseExercise = false,
    this.emergencyContraceptive = false,
    this.severePelvicPain = false,
  });
}

/// Faktor Kemungkinan Klinis Biologis
class TriageFactor {
  final String title;
  final String biologicalMechanism;
  final String recommendation;
  final String citation;

  const TriageFactor({
    required this.title,
    required this.biologicalMechanism,
    required this.recommendation,
    required this.citation,
  });
}

/// Hasil Lengkap Evaluasi Triage Medis Lunara
class TriageEvaluationResult {
  final List<TriageFactor> factors;
  final List<String> generalLifestyleAdvice;
  final String partnerGuidance;
  final bool isRedFlag;
  final String? redFlagWarning;

  const TriageEvaluationResult({
    required this.factors,
    required this.generalLifestyleAdvice,
    required this.partnerGuidance,
    this.isRedFlag = false,
    this.redFlagWarning,
  });
}

/// Mesin Triage Medis Deterministik Lunara
/// Berdasarkan ACOG Bulletin 219, Speroff Bab 11, Guyton & Hall Bab 82, dan WHO
class TriageEngine {
  TriageEngine._();

  static TriageEvaluationResult evaluate(TriageInput input) {
    final factors = <TriageFactor>[];
    final advice = <String>[];
    bool isRedFlag = false;
    String? redFlagWarning;

    // 1. EVALUASI RED FLAGS (TANDA BAHAYA GAWAT DARURAT)
    if (input.severePelvicPain) {
      isRedFlag = true;
      redFlagWarning =
          'PERINGATAN KLINIS: Nyeri panggul tajam atau hebat yang muncul mendadak berisiko terkait kehamilan ektopik (kehamilan di luar kandungan), kista ovarium terpuntir, atau radang panggul akut. Sangat disarankan untuk segera memeriksakan diri ke IGD atau dokter spesialis obstetri & ginekologi (Sp.OG).';
    } else if (input.daysDelayed >= MedicalConstants.redFlagAmenorrheaThreshold) {
      isRedFlag = true;
      redFlagWarning =
          'PERINGATAN KLINIS: Menstruasi terlambat lebih dari 90 hari memenuhi kriteria klinis amenore sekunder (ACOG Bulletin 219). Diperlukan pemeriksaan fisik USG transvaginal dan profil hormon secara langsung oleh dokter Sp.OG.';
    }

    // 2. EVALUASI KEMUNGKINAN KEHAMILAN
    if (input.hasPregnancyRisk) {
      if (input.pregnancyTestResult == 'positive') {
        factors.add(const TriageFactor(
          title: 'Indikasi Kehamilan Awal (hCG Positif)',
          biologicalMechanism:
              'Hasil tes urine menunjukkan deteksi hormon Human Chorionic Gonadotropin (hCG) yang disekresi oleh trofoblas setelah implantasi embrio.',
          recommendation:
              'Jadwalkan konsultasi antenatal care pertama dengan dokter Sp.OG untuk konfirmasi kantung kehamilan via USG.',
          citation: 'ACOG Practice Bulletin: Early Pregnancy Diagnostic & Care Guidelines.',
        ));
      } else if (!input.pregnancyTestTaken || input.pregnancyTestResult == 'not_tested') {
        factors.add(const TriageFactor(
          title: 'Kemungkinan Kehamilan Belum Terverifikasi',
          biologicalMechanism:
              'Aktivitas seksual tanpa kontrasepsi dalam siklus aktif adalah kemungkinan utama keterlambatan haid pada usia reproduktif.',
          recommendation:
              'Gunakan alat tes kehamilan mandiri (Test Pack) menggunakan urine pagi hari pertama (konsentrasi hormon hCG tertinggi).',
          citation: 'ACOG Patient FAQ 005: When and How to Take a Home Pregnancy Test.',
        ));
        advice.add('Lakukan tes kehamilan urine pagi pertama untuk hasil paling akurat.');
      }
    }

    // 3. EVALUASI STRES AKUT / BEBAN EMOSIONAL (Poros HPA & Penekanan GnRH)
    if (input.stressLevel >= 4) {
      factors.add(const TriageFactor(
        title: 'Penekanan Hormon Ovulasi Akibat Stres (Poros HPA)',
        biologicalMechanism:
            'Beban pikiran tinggi dan insomnia memicu pelepasan hormon kortisol dan CRH secara berlebih. Hormon ini menekan sekresi pulsatil hormon GnRH di hipotalamus, sehingga lonjakan hormon LH terhambat dan ovulasi mundur.',
        recommendation:
            'Tidur cukup 7–8 jam, kurangi beban kerja berlebih sementara waktu, dan konsumsi asupan penenang saraf alami (teh chamomile atau makanan kaya magnesium).',
        citation: MedicalConstants.speroffCitation,
      ));
      advice.add('Prioritaskan tidur berkualitas minimal 7 jam dan hindari pemicu stres berlebih.');
      advice.add('Konsumsi makanan kaya magnesium (pisang, cokelat hitam) untuk relaksasi otot dan saraf.');
    }

    // 4. EVALUASI DEFISIT ENERGI / PERUBAHAN DIET DRASTIS
    if (input.drasticDietOrWeightChange) {
      factors.add(const TriageFactor(
        title: 'Defisit Energi & Fluktuasi Leptin (Functional Hypothalamic Amenorrhea)',
        biologicalMechanism:
            'Defisit kalori ekstrem atau penurunan berat badan mendadak menurunkan kadar hormon leptin. Otak membaca tubuh berada dalam mode bertahan hidup (*survival*), sehingga fungsi reproduksi dihemat sementara.',
        recommendation:
            'Pastikan kecukupan asupan karbohidrat kompleks dan lemak sehat untuk mengembalikan sinyal energi metabolik ke hipotalamus.',
        citation: MedicalConstants.acogBulletinCitation,
      ));
      advice.add('Hindari diet defisit kalori ekstrem; penuhi asupan lemak sehat dan karbohidrat kompleks.');
    }

    // 5. EVALUASI AKTIVITAS FISIK / OLAHRAGA BERLEBIH
    if (input.intenseExercise) {
      factors.add(const TriageFactor(
        title: 'Stres Fisik Metabolik Akibat Olahraga Intens',
        biologicalMechanism:
            'Latihan fisik dengan intensitas tinggi tanpa kompensasi kalori yang cukup mengganggu ritme pulsasi hormon gonadotropin di otak.',
        recommendation:
            'Turunkan intensitas latihan fisik dan ganti sementara dengan peregangan ringan atau jalan santai selama masa tunggu haid.',
        citation: 'ACOG Committee Opinion No. 651: Menstruation in Athletes & Active Women.',
      ));
    }

    // 6. EVALUASI KONTRASEPSI DARURAT ATAU OBAT
    if (input.emergencyContraceptive) {
      factors.add(const TriageFactor(
        title: 'Pergeseran Waktu Ovulasi Akibat Kontrasepsi Darurat',
        biologicalMechanism:
            'Pil kontrasepsi darurat mengandung progestin dosis tinggi (*levonorgestrel/ulipristal*) yang bekerja menunda pelepasan sel telur. Hal ini lazim menggeser siklus menstruasi berikutnya maju atau mundur hingga 7–10 hari.',
        recommendation:
            'Observasi selama 7–10 hari ke depan. Keterlambatan ini adalah respons fisiologis obat yang umum dan bersifat sementara.',
        citation: MedicalConstants.whoCitation,
      ));
      advice.add('Pergeseran siklus wajar setelah konsumsi kontrasepsi darurat, lakukan observasi santai.');
    }

    // 7. JIKA TIDAK ADA FAKTOR SPESIFIK & TELAT RINGAN (VARIASI FISIOLOGIS)
    if (factors.isEmpty) {
      factors.add(const TriageFactor(
        title: 'Variasi Fisiologis Siklus Normal',
        biologicalMechanism:
            'Pergeseran siklus 2 hingga 4 hari antar bulan adalah fenomena biologis normal yang dipengaruhi oleh kelelahan ringan, fluktuasi cuaca, atau ritme sirkadian.',
        recommendation:
            'Lakukan observasi tenang selama 3–5 hari ke depan dan jaga hidrasi tubuh.',
        citation: MedicalConstants.guytonHallCitation,
      ));
      advice.add('Jaga hidrasi dengan minum minimal 2 liter air putih hangat setiap hari.');
    }

    // PANDUAN UNTUK PASANGAN PRIA
    String partnerGuidance;
    if (isRedFlag) {
      partnerGuidance =
          'Pasanganmu sedang mengalami gejala tidak biasa. Temani dia segera ke dokter atau fasilitas kesehatan tanpa membuatnya cemas.';
    } else if (input.stressLevel >= 4) {
      partnerGuidance =
          'Tingkat stresnya sedang tinggi dan ini alasan utama tubuhnya menunda haid. Jangan banyak bertanya yang memicu beban pikiran; tawarkan pijatan ringan di pundak dan buatkan minuman hangat.';
    } else if (input.hasPregnancyRisk && !input.pregnancyTestTaken) {
      partnerGuidance =
          'Beli alat tes kehamilan secara bijak dan dampingi dia dengan lembut saat melakukan tes di pagi hari tanpa menghakimi.';
    } else {
      partnerGuidance =
          'Tetap tenang dan dengarkan kabarnya. Ketenangan sikapmu adalah obat pereda stres terbaik untuk mengembalikan ritme hormonnya.';
    }

    return TriageEvaluationResult(
      factors: factors,
      generalLifestyleAdvice: advice,
      partnerGuidance: partnerGuidance,
      isRedFlag: isRedFlag,
      redFlagWarning: redFlagWarning,
    );
  }
}
