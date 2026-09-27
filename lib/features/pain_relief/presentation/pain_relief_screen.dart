import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Layar Pustaka Solusi Mandiri Pereda Nyeri & Kram Haid (Evidence-Based ACOG)
class PainReliefScreen extends StatelessWidget {
  const PainReliefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pustaka Solusi Pereda Nyeri',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ==================== 1. PENJELASAN BIOLOGIS PROSTAGLANDIN ====================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.science_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mengapa Kram Haid Terjadi?',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            'Kajian Fisiologi Kedokteran (Guyton & Hall Bab 82)',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Saat dinding rahim bersiap meluruhkan lapisan endometrium, sel-sel rahim melepaskan senyawa biokimia bernama Prostaglandin F2-alpha (PGF2α).\n\nZat ini memicu kontraksi ritmis otot polos dinding rahim (miometrium) dan mempersempit pembuluh darah (vasokonstriksi). Kondisi ini menyebabkan pasokan oksigen sementara ke jaringan otot rahim berkurang (iskemia fisiologis), yang dirasakan sebagai sensasi kram, pegal di panggul, atau rasa tertekan di punggung bawah.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 2. 4 SOLUSI NON-OBAT TERBUKTI KLINIS ====================
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '4 Solusi Alami Terbukti Klinis (ACOG Guidelines)',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Solusi 1: Terapi Hangat Lokal 40C
          _buildTherapyCard(
            number: '1',
            icon: Icons.hot_tub_rounded,
            accentColor: AppColors.phaseOvulation,
            title: 'Terapi Hangat Lokal (Suhu ~40°C)',
            badge: 'Efektivitas Setara NSAID (ACOG)',
            summary:
                'Menempelkan kompres hangat, heating pad, atau botol air hangat pada perut bagian bawah selama 15–20 menit.',
            mechanism:
                'Panas menyebabkan vasodilatasi pembuluh darah panggul, meningkatkan aliran oksigen ke miometrium, dan secara langsung meredakan iskemia otot rahim.',
          ),
          const SizedBox(height: 14),

          // Solusi 2: Asupan Magnesium & Vitamin B6
          _buildTherapyCard(
            number: '2',
            icon: Icons.energy_savings_leaf_rounded,
            accentColor: AppColors.primary,
            title: 'Asupan Magnesium & Vitamin B6',
            badge: 'Relaksasi Tonus Miometrium',
            summary:
                'Konsumsi makanan tinggi magnesium seperti pisang, kacang almond, bayam, biji labu, atau dark chocolate (>70%).',
            mechanism:
                'Magnesium bekerja sebagai antagonis kalsium alami yang menurunkan eksitabilitas neuromuskular rahim, sedangkan Vitamin B6 meregulasi neurotransmitter pengatur persepsi nyeri.',
          ),
          const SizedBox(height: 14),

          // Solusi 3: Teh Jahe Hangat & Hidrasi Optimal
          _buildTherapyCard(
            number: '3',
            icon: Icons.coffee_rounded,
            accentColor: AppColors.phaseFollicular,
            title: 'Seduhan Jahe Hangat & Hidrasi Optimal',
            badge: 'Inhibitor Biosintesis PGF2α',
            summary:
                'Minum 2–3 cangkir air rebusan jahe segar hangat per hari dan penuhi kebutuhan 2 liter air putih.',
            mechanism:
                'Senyawa bioaktif gingerol dan shogaol pada jahe terbukti menghambat enzim siklooksigenase (COX-2), menekan pembentukan prostaglandin secara alami tanpa mengiritasi lambung.',
          ),
          const SizedBox(height: 14),

          // Solusi 4: Peregangan Yoga Ringan
          _buildTherapyCard(
            number: '4',
            icon: Icons.self_improvement_rounded,
            accentColor: AppColors.phaseLuteal,
            title: 'Peregangan Yoga Ringan (Child’s Pose)',
            badge: 'Dekompresi Dasar Panggul',
            summary:
                'Lakukan pose Balasana (Child’s Pose) dan Cat-Cow selama 3–5 menit dengan pernapasan perut perlahan.',
            mechanism:
                'Meregangkan ligamen sakrouterina dan otot dasar panggul yang tegang, serta merangsang sistem saraf parasimpatis untuk melepaskan endorfin pereda nyeri alami.',
          ),
          const SizedBox(height: 24),

          // ==================== 3. PANDUAN UNTUK PASANGAN PRIA ====================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.companionHighlight, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.phaseMenstrual, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Panduan Perhatian untuk Pasangan Pria',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Siapkan kompres air hangat tanpa diminta.\n'
                  '2. Sediakan minuman hangat dan hindari makanan asin berlebih yang memicu kembung.\n'
                  '3. Berikan ruang istirahat yang tenang; kram haid bukan sekadar "sugesti", melainkan proses biologis nyata di otot rahim.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ==================== 4. PERINGATAN RED FLAG SP.OG ====================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.redFlagLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.redFlag.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.redFlag, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kapan Harus Berkonsultasi ke Dokter Sp.OG?',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.redFlag,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Segera periksakan diri jika: nyeri kram sangat ekstrem hingga pingsan/muntah, nyeri tidak berkurang sama sekali dengan kompres/istirahat, atau terjadi perdarahan deras menggumpal banyak. Ini penting untuk evaluasi dini kemungkinan endometriosis, adenomiosis, atau miom.',
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
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  static Widget _buildTherapyCard({
    required String number,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String badge,
    required String summary,
    required String mechanism,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, size: 18, color: accentColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Mekanisme Biologis: $mechanism',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
