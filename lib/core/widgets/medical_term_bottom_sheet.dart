import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Model Data Penjelasan Istilah Medis Awam
class MedicalTermData {
  final String key;
  final String commonTitle;
  final String medicalTerm;
  final String plainExplanation;
  final String biologicalMechanism;
  final List<String> practicalTips;
  final String whenToSeeDoctor;
  final IconData icon;
  final Color themeColor;
  final Color lightColor;

  const MedicalTermData({
    required this.key,
    required this.commonTitle,
    required this.medicalTerm,
    required this.plainExplanation,
    required this.biologicalMechanism,
    required this.practicalTips,
    required this.whenToSeeDoctor,
    required this.icon,
    required this.themeColor,
    required this.lightColor,
  });
}

/// Kamus Istilah Medis & Fisiologi Lunara
class MedicalTermRegistry {
  MedicalTermRegistry._();

  static const Map<String, MedicalTermData> terms = {
    'hpo_axis': MedicalTermData(
      key: 'hpo_axis',
      commonTitle: 'Keseimbangan Hormon Otak-Indung Telur',
      medicalTerm: 'Poros Hipotalamus-Hipofisis-Ovarium (HPO Axis)',
      plainExplanation:
          'Jalur komunikasi dua arah antara otak (hipotalamus & kelenjar pituitari) dengan indung telur (ovarium) yang mengatur siklus haid dan pelepasan sel telur secara teratur.',
      biologicalMechanism:
          'Otak melepaskan hormon sinyal (GnRH, FSH, & LH) untuk merangsang ovarium memproduksi estrogen dan progesteron. Gangguan tidur atau stres berat dapat menunda sinyal ini.',
      practicalTips: [
        'Jaga kualitas tidur minimal 7–8 jam per malam.',
        'Kelola beban pikiran dengan relaksasi atau jalan santai.',
        'Pertahankan asupan kalori dan nutrisi seimbang.',
      ],
      whenToSeeDoctor:
          'Jika haid terlambat lebih dari 3 bulan berturut-turut tanpa adanya kehamilan.',
      icon: Icons.sync_alt_rounded,
      themeColor: AppColors.phaseFollicular,
      lightColor: AppColors.phaseFollicularLight,
    ),
    'dysmenorrhea': MedicalTermData(
      key: 'dysmenorrhea',
      commonTitle: 'Kram Perut Haid',
      medicalTerm: 'Dismenore Primer',
      plainExplanation:
          'Rasa nyeri atau kram berdenyut di perut bagian bawah yang muncul sesaat sebelum atau selama hari-hari pertama haid.',
      biologicalMechanism:
          'Tubuh memproduksi zat alami prostaglandin untuk membuat otot rahim berkontraksi mengeluarkan lapisan darah haid. Makin tinggi prostaglandin, makin kuat rasa kram.',
      practicalTips: [
        'Tempelkan botol air hangat atau kompres panas di perut bawah.',
        'Konsumsi makanan kaya magnesium (bayam, cokelat hitam, kacang almond).',
        'Lakukan peregangan ringan seperti gerakan child\'s pose.',
      ],
      whenToSeeDoctor:
          'Jika nyeri sangat hebat hingga tidak bisa bangun dari tempat tidur atau tidak mereda dengan pereda nyeri.',
      icon: Icons.healing_rounded,
      themeColor: AppColors.phaseMenstrual,
      lightColor: AppColors.phaseMenstrualLight,
    ),
    'menorrhagia': MedicalTermData(
      key: 'menorrhagia',
      commonTitle: 'Perdarahan Haid Sangat Deras',
      medicalTerm: 'Menoragia (Heavy Menstrual Bleeding)',
      plainExplanation:
          'Keluarnya darah haid dalam jumlah yang jauh lebih banyak dari biasanya atau durasi haid yang berlangsung lebih dari 7–8 hari.',
      biologicalMechanism:
          'Sering kali disebabkan oleh fluktuasi hormon estrogen-progesteron yang membuat lapisan endometrium terlalu tebal, atau adanya polip/miom rahim.',
      practicalTips: [
        'Perbanyak konsumsi makanan sumber zat besi (daging tanpa lemak, hati, bayam).',
        'Cukupi kebutuhan cairan tubuh untuk menghindari lemas atau dehidrasi.',
        'Catat frekuensi ganti pembalut per hari di aplikasi Lunara.',
      ],
      whenToSeeDoctor:
          'Jika harus ganti pembalut penuh tiap 1–2 jam berturut-turut, atau keluar gumpalan darah berukuran lebih dari koin (2.5 cm).',
      icon: Icons.water_drop_rounded,
      themeColor: AppColors.redFlag,
      lightColor: AppColors.redFlagLight,
    ),
    'secondary_amenorrhea': MedicalTermData(
      key: 'secondary_amenorrhea',
      commonTitle: 'Haid Berhenti Sementara',
      medicalTerm: 'Amenore Sekunder',
      plainExplanation:
          'Kondisi ketika haid tidak kunjung datang selama 3 siklus berturut-turut atau minimal 90 hari pada wanita yang sebelumnya sudah pernah haid.',
      biologicalMechanism:
          'Terjadi saat poros hormonal otak mendeteksi stres ekstrem, berat badan turun drastis, gangguan tiroid, atau sindrom PCOS, sehingga indung telur menunda ovulasi.',
      practicalTips: [
        'Lakukan tes pack kehamilan terlebih dahulu jika ada riwayat hubungan intim.',
        'Hindari diet defisit kalori yang terlalu ketat.',
        'Bawa riwayat catatan Lunara saat berkonsultasi ke dokter.',
      ],
      whenToSeeDoctor:
          'Kondisi terlambat >= 90 hari disarankan segera diperiksakan ke dokter spesialis kandungan (Sp.OG).',
      icon: Icons.warning_amber_rounded,
      themeColor: AppColors.redFlag,
      lightColor: AppColors.redFlagLight,
    ),
    'fha': MedicalTermData(
      key: 'fha',
      commonTitle: 'Haid Tertunda Akibat Beban Fisik/Pikiran',
      medicalTerm: 'Functional Hypothalamic Amenorrhea (FHA)',
      plainExplanation:
          'Kondisi alami saat tubuh menghemat energi dengan menonaktifkan proses menstruasi sementara karena menganggap tubuh sedang dalam mode darurat atau kelelahan.',
      biologicalMechanism:
          'Dipicu oleh kombinasi diet ketat, olahraga terlalu berat, atau tekanan emosional yang menurunkan hormon leptin dan menekan pelepasan hormon GnRH di otak.',
      practicalTips: [
        'Kurangi intensitas olahraga yang menguras tenaga secara berlebihan.',
        'Tingkatkan porsi karbohidrat kompleks dan lemak sehat (alpukat, minyak zaitun).',
        'Beri tubuh waktu pemulihan dan tidur yang cukup.',
      ],
      whenToSeeDoctor:
          'Jika penyesuaian gaya hidup selama 1–2 bulan belum mengembalikan siklus haid normal.',
      icon: Icons.spa_rounded,
      themeColor: AppColors.phaseLuteal,
      lightColor: AppColors.phaseLutealLight,
    ),
    'follicular_phase': MedicalTermData(
      key: 'follicular_phase',
      commonTitle: 'Fase Pematangan Telur & Pemulihan Energi',
      medicalTerm: 'Fase Folikular (Follicular Phase)',
      plainExplanation:
          'Masa setelah darah haid selesai hingga sesaat sebelum sel telur dilepaskan. Pada masa ini biasanya Anda merasa lebih berenergi, fokus, dan segar.',
      biologicalMechanism:
          'Kadar hormon estrogen perlahan naik untuk menebalkan kembali dinding rahim dan membantu folikel di ovarium mematangkan calon sel telur terbaik.',
      practicalTips: [
        'Manfaatkan energi tinggi ini untuk olahraga kardio atau proyek penting.',
        'Konsumsi makanan tinggi antioksidan dan sayuran segar.',
        'Pikiran cenderung lebih jernih dan suasana hati lebih positif.',
      ],
      whenToSeeDoctor:
          'Fase ini normalnya berlangsung 10–18 hari. Jika fase ini terasa jauh lebih panjang, konsultasikan variabilitas siklus.',
      icon: Icons.wb_sunny_rounded,
      themeColor: AppColors.phaseFollicular,
      lightColor: AppColors.phaseFollicularLight,
    ),
    'ovulation_phase': MedicalTermData(
      key: 'ovulation_phase',
      commonTitle: 'Masa Subur Puncak & Pelepasan Sel Telur',
      medicalTerm: 'Fase Ovulasi (Ovulation)',
      plainExplanation:
          'Momen singkat saat sel telur matang dilepaskan dari ovarium menuju saluran tuba, siap untuk dibuahi. Ini adalah jendela peluang kehamilan tertinggi.',
      biologicalMechanism:
          'Lonjakan tajam hormon LH (Luteinizing Hormone) memicu pelepasan telur. Sel telur hanya bertahan hidup 12–24 jam, namun sperma dapat bertahan 3–5 hari sebelumnya.',
      practicalTips: [
        'Amati lendir serviks yang menjadi bening, licin, dan elastis mirip putih telur mentah.',
        'Jika ingin hamil, ini adalah waktu paling efektif untuk berhubungan intim.',
        'Jika menunda kehamilan, gunakan pengaman atau hindari penetrasi tanpa proteksi.',
      ],
      whenToSeeDoctor:
          'Jika mengalami nyeri ovulasi yang sangat tajam dan tidak mereda dalam 24 jam.',
      icon: Icons.auto_awesome_rounded,
      themeColor: AppColors.phaseOvulation,
      lightColor: AppColors.phaseOvulationLight,
    ),
    'luteal_phase': MedicalTermData(
      key: 'luteal_phase',
      commonTitle: 'Masa Pra-Haid / PMS',
      medicalTerm: 'Fase Luteal (Luteal Phase)',
      plainExplanation:
          'Masa setelah ovulasi sampai hari pertama haid berikutnya. Tubuh mulai memperlambat ritme dan Anda mungkin merasakan tanda-tanda PMS.',
      biologicalMechanism:
          'Bekas folikel berubah menjadi korpus luteum yang memproduksi hormon progesteron. Jika tidak terjadi pembuahan, progesteron turun memicu peluruhan dinding rahim.',
      practicalTips: [
        'Kurangi konsumsi kopi berlebih dan makanan terlalu asin agar tidak kembung.',
        'Luangkan waktu istirahat yang lebih tenang dan jangan paksakan fisik terlalu keras.',
        'Pahami bahwa fluktuasi emosi adalah reaksi fisiologis hormon yang wajar.',
      ],
      whenToSeeDoctor:
          'Jika perubahan suasana hati sangat berat dan mengganggu hubungan sehari-hari (indikasi PMDD).',
      icon: Icons.nightlight_round,
      themeColor: AppColors.phaseLuteal,
      lightColor: AppColors.phaseLutealLight,
    ),
    'fabm': MedicalTermData(
      key: 'fabm',
      commonTitle: 'Metode Pencegahan Kehamilan Alami',
      medicalTerm: 'Fertility Awareness-Based Methods (FABM)',
      plainExplanation:
          'Cara alami mengenali hari-hari subur dan tidak subur dalam siklus menstruasi untuk merencanakan atau menunda kehamilan tanpa obat atau alat hormonal.',
      biologicalMechanism:
          'Menggabungkan perkiraan waktu hidup sel telur (12–24 jam) dan daya tahan hidup sperma (hingga 5 hari di rahim), menciptakan jendela subur sekitar 6 hari per siklus.',
      practicalTips: [
        'Sangat bergantung pada keteraturan siklus bulanan Anda (21–35 hari).',
        'Gunakan kontrasepsi pelindung (kondom) pada hari-hari zona risiko tinggi.',
        'Metode ini TIDAK melindungi dari infeksi menular seksual (IMS).',
      ],
      whenToSeeDoctor:
          'Konsultasikan dengan dokter atau bidan untuk metode kontrasepsi jangka panjang jika siklus Anda sering tidak teratur.',
      icon: Icons.shield_outlined,
      themeColor: AppColors.phaseFollicular,
      lightColor: AppColors.phaseFollicularLight,
    ),
    'ttc_wilcox': MedicalTermData(
      key: 'ttc_wilcox',
      commonTitle: 'Hari Emas Konsepsi (Program Hamil)',
      medicalTerm: 'Jendela Fertilitas Wilcox & Rekomendasi ASRM',
      plainExplanation:
          'Rentang 6 hari paling subur dalam siklus menstruasi (5 hari sebelum ovulasi hingga hari ovulasi) dengan peluang konsepsi tertinggi pada H-2, H-1, dan hari ovulasi (~34–36%).',
      biologicalMechanism:
          'Studi klinis Wilcox et al. (NEJM 1995) membuktikan kehamilan hampir selalu terjadi dari hubungan intim selama 6 hari ini. Sperma dapat bertahan 3–5 hari di saluran reproduksi berkat lendir serviks yang ramah, sedangkan sel telur bertahan 12–24 jam.',
      practicalTips: [
        'Konsensus ASRM (American Society for Reproductive Medicine) merekomendasikan hubungan intim tiap 1–2 hari sekali (selang-seling) di jendela subur.',
        'Tidak perlu berhubungan intim berkali-kali dalam sehari karena dapat menurunkan konsentrasi sperma.',
        'Fokus rileks dan nikmati momen bersama pasangan untuk menjaga keseimbangan hormonal.',
      ],
      whenToSeeDoctor:
          'Jika sudah aktif mencoba hamil selama 12 bulan (usia < 35 tahun) atau 6 bulan (usia >= 35 tahun) belum membuahkan hasil, jadwalkan konsultasi ke dokter spesialis kandungan (Sp.OG subfertilitas).',
      icon: Icons.stars_rounded,
      themeColor: AppColors.intimacyAccent,
      lightColor: AppColors.intimacyLight,
    ),
  };
}

/// Helper & Bottom Sheet Interaktif
class MedicalTermHelper {
  MedicalTermHelper._();

  /// Menampilkan Bottom Sheet Penjelasan Istilah Medis
  static void show(BuildContext context, String termKey) {
    HapticFeedback.lightImpact();
    final data = MedicalTermRegistry.terms[termKey];
    if (data == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MedicalTermModal(data: data),
    );
  }

  /// Tombol Ikon Info (ℹ️) Kecil yang Siap Ditempel di Judul / Kartu
  static Widget infoIcon(
    BuildContext context,
    String termKey, {
    double size = 16,
    Color? color,
  }) {
    return Semantics(
      label: 'Penjelasan istilah medis',
      button: true,
      child: InkWell(
        onTap: () => show(context, termKey),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.info_outline_rounded,
            size: size,
            color: color ?? AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _MedicalTermModal extends StatelessWidget {
  final MedicalTermData data;

  const _MedicalTermModal({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header Ikon & Judul Awam
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: data.lightColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(data.icon, color: data.themeColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.commonTitle,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            data.medicalTerm,
                            style: AppTypography.badgeText.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Penjelasan Bahasa Awam
              Text(
                'Apa Artinya Bagi Tubuh Anda?',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.plainExplanation,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),

              // Mekanisme Biologis
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.biotech_rounded, size: 18, color: data.themeColor),
                        const SizedBox(width: 8),
                        Text(
                          'Dasar Medis & Fisiologis',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.biologicalMechanism,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tips Praktis Sehari-hari
              Text(
                'Langkah Praktis yang Membantu',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...data.practicalTips.map((tip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: data.themeColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),

              // Kapan Perlu Konsultasi Dokter
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        size: 20, color: AppColors.primaryDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kapan Harus Berkonsultasi ke Dokter?',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.whenToSeeDoctor,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Tutup
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text(
                    'Mengerti',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
