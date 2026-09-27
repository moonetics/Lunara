import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/medical_constants.dart';
import '../../../core/services/triage_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Layar Hasil Evaluasi Keterlambatan Siklus Lunara
class TriageResultScreen extends StatelessWidget {
  final TriageEvaluationResult result;
  final TriageInput input;

  const TriageResultScreen({
    super.key,
    required this.result,
    required this.input,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Hasil Evaluasi Medis', style: AppTypography.headlineMedium),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BANNER PERINGATAN DARURAT (RED FLAG) JIKA ADA
              if (result.isRedFlag && result.redFlagWarning != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.redFlagLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.redFlag, width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.redFlag, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PERINGATAN RED FLAG MEDIS',
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.redFlag,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              result.redFlagWarning!,
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF7F1D1D),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 2. HEADER PENJELASAN RAMAH
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Telat ${input.daysDelayed} Hari dari Perkiraan',
                                style: AppTypography.titleMedium,
                              ),
                              Text(
                                '${result.factors.length} faktor biologis teridentifikasi',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tinjauan kemungkinan faktor fisiologis pemicu penundaan menstruasi berdasarkan referensi medis klinis:',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. DAFTAR FAKTOR BIOLOGIS & BADGE DASAR MEDIS
              Text('Faktor Kemungkinan Klinis', style: AppTypography.titleLarge),
              const SizedBox(height: 10),

              ...result.factors.map((factor) => _MedicalFactorCard(factor: factor)),

              const SizedBox(height: 16),

              // 4. KOTAK PANDUAN PENDAMPING PASANGAN
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.phaseFollicular.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: AppColors.phaseFollicular, size: 20),
                        const SizedBox(width: 10),
                        Text('Panduan untuk Pasangan Pria', style: AppTypography.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.partnerGuidance,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. ANJURAN GAYA HIDUP & OBSERVASI
              if (result.generalLifestyleAdvice.isNotEmpty) ...[
                Text('Rencana Tindakan 3–5 Hari', style: AppTypography.titleLarge),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: result.generalLifestyleAdvice.map((advice) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(advice, style: AppTypography.bodyMedium)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 6. DISCLAIMER RESMI HUKUM & ETIKA MEDIS
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  MedicalConstants.medicalDisclaimer,
                  style: AppTypography.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textTertiary,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // TOMBOL KEMBALI KE BERANDA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Selesai & Kembali ke Beranda'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu Faktor Medis dengan Badge Expandable "Dasar Medis"
class _MedicalFactorCard extends StatefulWidget {
  final TriageFactor factor;

  const _MedicalFactorCard({required this.factor});

  @override
  State<_MedicalFactorCard> createState() => _MedicalFactorCardState();
}

class _MedicalFactorCardState extends State<_MedicalFactorCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.factor.title,
                        style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isExpanded = !_isExpanded);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isExpanded ? AppColors.primary : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 13,
                              color: _isExpanded ? Colors.white : AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Dasar Medis',
                              style: AppTypography.badgeText.copyWith(
                                color: _isExpanded ? Colors.white : AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.factor.biologicalMechanism,
                  style: AppTypography.bodyMedium.copyWith(height: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.factor.recommendation,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // AREA EXPANDABLE RUJUKAN BUKU TEKS
          if (_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rujukan Literatur Kedokteran:', style: AppTypography.badgeText),
                        const SizedBox(height: 2),
                        Text(
                          widget.factor.citation,
                          style: AppTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
