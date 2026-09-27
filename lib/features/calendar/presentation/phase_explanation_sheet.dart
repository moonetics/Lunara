import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

enum ExplainedPhase {
  menstrual,
  follicular,
  ovulation,
  luteal,
  intimacy,
}

/// Lembar Edukasi Fisiologis Interaktif untuk 4 Fase Siklus
class PhaseExplanationSheet extends StatelessWidget {
  final ExplainedPhase initialPhase;

  const PhaseExplanationSheet({
    super.key,
    required this.initialPhase,
  });

  static void show(BuildContext context, {ExplainedPhase phase = ExplainedPhase.menstrual}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhaseExplanationSheet(initialPhase: phase),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _getPhaseDetails(initialPhase);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Badge & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: info.lightColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(info.icon, color: info.themeColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: info.themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        info.tag,
                        style: AppTypography.bodySmall.copyWith(
                          color: info.themeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.title,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Dinamika Hormon Biologis
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.biotech_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Apa yang Terjadi di Tubuhmu?',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  info.biologicalDescription,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Energi & Mood
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: info.lightColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: info.themeColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 18, color: info.themeColor),
                    const SizedBox(width: 8),
                    Text(
                      'Energi Fisik & Suasana Hati',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: info.themeColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  info.energyAndMood,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Tips Perawatan Mandiri
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 18, color: AppColors.intimacyAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Saran Perawatan Nyaman',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  info.selfCareAdvice,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Tutup
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  _PhaseDetails _getPhaseDetails(ExplainedPhase phase) {
    switch (phase) {
      case ExplainedPhase.menstrual:
        return const _PhaseDetails(
          tag: 'HARI 1 - HARI TERAKHIR HAID',
          title: 'Fase Menstruasi (Haid)',
          icon: Icons.water_drop_rounded,
          themeColor: AppColors.phaseMenstrual,
          lightColor: AppColors.phaseMenstrualLight,
          biologicalDescription:
              'Kadar hormon estrogen dan progesteron turun tajam, menyebabkan dinding rahim (endometrium) yang menebal luruh secara alami bersama aliran darah haid.',
          energyAndMood:
              'Tingkat energi cenderung paling rendah. Wajar merasa ingin istirahat, sedikit lesu, atau merasakan kram perut bagian bawah akibat kontraksi miometrium rahim.',
          selfCareAdvice:
              'Gunakan kompres hangat (botol air hangat/heating pad) pada perut bawah, perbanyak minum air hangat, teh jahe, dan konsumsi makanan kaya zat besi serta magnesium.',
        );
      case ExplainedPhase.follicular:
        return const _PhaseDetails(
          tag: 'PASCA-HAID S/D H-1 OVULASI',
          title: 'Fase Folikular (Pematangan)',
          icon: Icons.spa_rounded,
          themeColor: AppColors.phaseFollicular,
          lightColor: AppColors.phaseFollicularLight,
          biologicalDescription:
              'Kelenjar pituitari memproduksi hormon FSH (Follicle-Stimulating Hormone) yang merangsang folikel ovarium mematangkan sel telur. Hormon estrogen mulai meningkat pesat.',
          energyAndMood:
              'Energi fisik, fokus mental, dan rasa optimisme meningkat drastis. Waktu optimal untuk berolahraga, memulai proyek baru, dan beraktivitas produktif.',
          selfCareAdvice:
              'Manfaatkan energi yang sedang prima untuk aktivitas fisik aktif. Penuhi asupan protein dan sayuran hijau untuk mendukung regenerasi lapisan rahim yang baru.',
        );
      case ExplainedPhase.ovulation:
        return const _PhaseDetails(
          tag: 'PUNCAK KESUBURAN (HARI KE-14 SIKLUS)',
          title: 'Fase Ovulasi (Masa Subur)',
          icon: Icons.bubble_chart_rounded,
          themeColor: AppColors.phaseOvulation,
          lightColor: AppColors.phaseOvulationLight,
          biologicalDescription:
              'Lonjakan hormon LH (Luteinizing Hormone) memicu pelepasan sel telur matang dari ovarium menuju tuba falopi, menciptakan jendela peluang kehamilan tertinggi.',
          energyAndMood:
              'Daya tarik, rasa percaya diri, dan gairah seksual mencapai puncaknya secara biologis. Suhu basal tubuh sedikit meningkat.',
          selfCareAdvice:
              'Bagi yang merencanakan kehamilan, waktu ini sangat ideal untuk berhubungan intim. Untuk pencegahan kehamilan, pastikan menggunakan proteksi secara optimal.',
        );
      case ExplainedPhase.luteal:
        return const _PhaseDetails(
          tag: 'PASCA-OVULASI S/D H-1 HAID',
          title: 'Fase Luteal & PMS',
          icon: Icons.wb_twilight_rounded,
          themeColor: AppColors.phaseLuteal,
          lightColor: AppColors.phaseLutealLight,
          biologicalDescription:
              'Bekas folikel berubah menjadi korpus luteum yang memproduksi hormon progesteron dalam jumlah tinggi. Jika tidak terjadi pembuahan, kadar progesteron akan turun perlahan.',
          energyAndMood:
              'Perubahan hormon di akhir fase luteal dapat memicu sindrom pra-menstruasi (PMS): kembung, payudara lebih sensitif, nafsu makan bertambah (craving), dan suasana hati yang lebih sensitif.',
          selfCareAdvice:
              'Kurangi asupan kafein dan garam berlebih untuk mencegah kembung. Lakukan peregangan yoga ringan, tidur cukup 8 jam, dan berikan afirmasi positif pada diri sendiri.',
        );
      case ExplainedPhase.intimacy:
        return const _PhaseDetails(
          tag: 'KEINTIMAN & PERENCANAAN / PENCEGAHAN',
          title: 'Aktivitas Intim & Masa Subur',
          icon: Icons.favorite_rounded,
          themeColor: AppColors.intimacyAccent,
          lightColor: AppColors.intimacyLight,
          biologicalDescription:
              'Sperma memiliki viabilitas hidup 3-5 hari di dalam saluran reproduksi wanita, sedangkan ovum (sel telur) bertahan sekitar 12-24 jam setelah ovulasi. Hubungan intim di jendela 5 hari sebelum ovulasi hingga 1 hari setelahnya membawa peluang pembuahan (konsepsi) paling signifikan.',
          energyAndMood:
              'Keintiman yang sehat dan terencana mendukung keintiman emosional bersama pasangan. Memahami masa subur memberikan ketenangan pikiran, baik bagi yang merencanakan kehamilan (promil) maupun yang memilih menunda.',
          selfCareAdvice:
              'Gunakan metode barrier (seperti kondom) secara konsisten jika belum berencana hamil. Jika berhubungan tanpa pengaman di jendela subur dan terjadi keterlambatan haid di siklus berikutnya, lakukan tes kehamilan mandiri (test pack) 14 hari pasca-kontak atau di hari pertama telat haid.',
        );
    }
  }
}

class _PhaseDetails {
  final String tag;
  final String title;
  final IconData icon;
  final Color themeColor;
  final Color lightColor;
  final String biologicalDescription;
  final String energyAndMood;
  final String selfCareAdvice;

  const _PhaseDetails({
    required this.tag,
    required this.title,
    required this.icon,
    required this.themeColor,
    required this.lightColor,
    required this.biologicalDescription,
    required this.energyAndMood,
    required this.selfCareAdvice,
  });
}
