import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/services/cycle_analytics_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../pdf_export/presentation/patient_info_dialog.dart';
import '../../../core/widgets/medical_term_bottom_sheet.dart';

/// Layar Analisis Statistik & Tren Siklus Lunara (ACOG Bulletin 219 Aligned)
class CycleInsightsScreen extends StatefulWidget {
  const CycleInsightsScreen({super.key});

  @override
  State<CycleInsightsScreen> createState() => _CycleInsightsScreenState();
}

class _CycleInsightsScreenState extends State<CycleInsightsScreen> {
  late final ScrollController _scrollController;
  late final CycleAnalyticsResult _analytics;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final cycles = LocalDbService.instance.getAllCycles();
    final entries = LocalDbService.instance.getAllDailyEntries();
    _analytics = CycleAnalyticsEngine.calculate(cycles: cycles, entries: entries);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _analytics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Statistik & Tren Siklus',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Cetak Laporan PDF Dokter Sp.OG',
            onPressed: () {
              HapticFeedback.lightImpact();
              PatientInfoDialog.show(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.paddingOf(context).bottom + 48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== BADGE RUJUKAN MEDIS ====================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Evaluasi Keteraturan Berstandar POGI, ACOG Bulletin No. 219 & WHO',
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==================== 1. KARTU SKOR KETERATURAN ====================
            _buildRegularityScoreCard(analytics),
            const SizedBox(height: 16),

            // ==================== 2. GRID 4 METRIK FISIOLOGIS ====================
            _buildMetricsGrid(analytics),
            const SizedBox(height: 18),

            // ==================== 3. GRAFIK BATANG RIWAYAT SIKLUS ====================
            _buildCycleHistoryChartCard(analytics),
            const SizedBox(height: 18),

            // ==================== 4. ANALISIS GEJALA FISIK TERBANYAK ====================
            _buildSymptomsAnalysisCard(analytics),
            const SizedBox(height: 18),

            // ==================== 5. DISTRIBUSI SUASANA HATI (MOOD) ====================
            _buildMoodDistributionCard(analytics),
            const SizedBox(height: 18),

            // ==================== 6. STATISTIK KEINTIMAN & PROTEKSI ====================
            _buildIntimacyStatsCard(analytics),
            const SizedBox(height: 20),

            // ==================== 7. BANNER EKSPOR PDF UNTUK DOKTER ====================
            _buildDoctorExportBanner(context),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ==================== SUB-WIDGETS ====================

  /// Kartu Keteraturan Siklus
  Widget _buildRegularityScoreCard(CycleAnalyticsResult analytics) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: analytics.regularityColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: analytics.regularityBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: analytics.regularityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            analytics.regularityTitle,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: analytics.regularityColor,
                            ),
                          ),
                        ),
                        MedicalTermHelper.infoIcon(context, 'hpo_axis', color: analytics.regularityColor),
                      ],
                    ),
                    Text(
                      analytics.variabilityDays > 0
                          ? 'Variasi: ±${analytics.variabilityDays} hari'
                          : 'Data baseline awal',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analytics.regularityDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// Grid 4 Metrik Fisiologis Utama
  Widget _buildMetricsGrid(CycleAnalyticsResult analytics) {
    final cycleValue = analytics.hasCycleData ? '${analytics.averageCycleLength} hari' : '-';
    final cycleSubtitle = analytics.hasCycleData
        ? 'Normal: 21–35 hari'
        : (analytics.totalCyclesRecorded > 0 ? 'Siklus berjalan' : 'Belum ada data');

    final periodValue = analytics.hasPeriodData ? '${analytics.averagePeriodDuration} hari' : '-';
    final periodSubtitle = analytics.hasPeriodData ? 'Normal: 2–7 hari' : 'Belum ada data';

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Rata-rata Siklus',
            value: cycleValue,
            subtitle: cycleSubtitle,
            color: AppColors.phaseFollicular,
            icon: Icons.repeat_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Durasi Haid',
            value: periodValue,
            subtitle: periodSubtitle,
            color: AppColors.phaseMenstrual,
            icon: Icons.water_drop_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Grafik Batang Riwayat Siklus
  Widget _buildCycleHistoryChartCard(CycleAnalyticsResult analytics) {
    final history = analytics.cycleHistory;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Panjang Siklus',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    analytics.hasCycleData
                        ? 'Garis putus-putus: Rata-rata ${analytics.averageCycleLength} hari'
                        : 'Belum ada data riwayat siklus',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.phaseFollicularLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Normal: 21–35h',
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.phaseFollicular,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (history.isEmpty)
            Container(
              height: 150,
              alignment: Alignment.center,
              child: Text(
                'Belum ada data riwayat siklus terekam.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
            )
          else ...[
            RepaintBoundary(
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: CustomPaint(
                  painter: _CycleBarChartPainter(
                    history: history,
                    averageLength: analytics.averageCycleLength,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppColors.primary, 'Selesai'),
                const SizedBox(width: 14),
                _buildLegendItem(AppColors.primaryDark, 'Sedang Berjalan'),
                const SizedBox(width: 14),
                _buildLegendItem(AppColors.phaseFollicular, 'Garis Rata-rata', isLine: true),
              ],
            ),
            if (analytics.ignoredGapCyclesCount > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.phaseFollicularLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.phaseFollicular.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.phaseFollicular),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${analytics.ignoredGapCyclesCount} jeda siklus (>45 hari) diabaikan otomatis oleh sistem agar riwayat lupa mencatat tidak merusak skala grafik dan akurasi prediksi.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isLine = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLine ? 14 : 10,
          height: isLine ? 2 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isLine ? 1 : 3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  /// Kartu Analisis Gejala Fisik Terbanyak
  Widget _buildSymptomsAnalysisCard(CycleAnalyticsResult analytics) {
    final symptoms = analytics.topSymptoms;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Keluhan Fisik Paling Sering',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${analytics.totalEntriesLogged} Catatan',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Frekuensi keluhan yang dicatat dalam log harian',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 14),

          if (symptoms.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                'Belum ada keluhan fisik yang dicatat pada entri harian.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
            )
          else ...[
            ...symptoms.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.label,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (item.symptomKey == 'cramps') ...[
                              const SizedBox(width: 4),
                              MedicalTermHelper.infoIcon(context, 'dysmenorrhea', size: 14),
                            ],
                          ],
                        ),
                        Text(
                          '${item.percentage}% (${item.occurrenceCount}x)',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (item.percentage / 100).clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: AppColors.borderSubtle,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kram perut (dismenore) memuncak di hari ke-1 & 2 akibat pelepasan prostaglandin PGF2α di endometrium rahim (Guyton & Hall, Bab 82).',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Kartu Distribusi Suasana Hati
  Widget _buildMoodDistributionCard(CycleAnalyticsResult analytics) {
    final moods = analytics.topMoods;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribusi Suasana Hati (Mood)',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'Fluktuasi emosi yang terekam sepanjang siklus',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 14),

          if (moods.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                'Belum ada suasana hati yang dicatat.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moods.map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: m.color.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.label,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: m.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${m.percentage}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Rujukan: NICE Guidelines NG88 (PMS/PMDD) & Guyton-Hall: Fluktuasi rasa lelah atau sensitif lazim terjadi di fase Luteal akhir akibat penurunan tajam estrogen & progesteron.',
              style: AppTypography.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Kartu Ringkasan Keintiman & Proteksi
  Widget _buildIntimacyStatsCard(CycleAnalyticsResult analytics) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.intimacyLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: AppColors.intimacyAccent, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Aktivitas Keintiman & Proteksi',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Total Hari',
                  '${analytics.totalIntimacyDays}',
                  AppColors.intimacyAccent,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Dengan Pengaman',
                  '${analytics.protectedIntimacyDays}',
                  AppColors.phaseFollicular,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Tanpa Pengaman',
                  '${analytics.unprotectedIntimacyDays}',
                  AppColors.phaseMenstrual,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  /// Banner Ekspor Laporan Dokter Sp.OG
  Widget _buildDoctorExportBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konsultasi ke Dokter Kandungan?',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cetak riwayat siklus 6 bulan resmi dalam 1 lembar PDF.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              PatientInfoDialog.show(context);
            },
            child: const Text('Cetak PDF', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter untuk Grafik Batang Riwayat Panjang Siklus
class _CycleBarChartPainter extends CustomPainter {
  final List<CycleHistoryPoint> history;
  final double averageLength;

  _CycleBarChartPainter({
    required this.history,
    required this.averageLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final bottomPadding = 30.0;
    final topPadding = 20.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width;

    // Skala: minimum 15 hari, maksimum 45 hari (atau nilai maksimum data + 5)
    final maxDataLength = history.map((e) => e.cycleLengthDays).fold<int>(35, math.max);
    final scaleMax = math.max(40, maxDataLength + 5).toDouble();
    final scaleMin = 15.0;

    double getY(double days) {
      final ratio = (days - scaleMin) / (scaleMax - scaleMin);
      return (size.height - bottomPadding) - (ratio * chartHeight);
    }

    // 1. Gambar Area Rentang Fisiologis Normal (21 - 35 hari)
    final normalTopY = getY(35.0);
    final normalBottomY = getY(21.0);
    final normalPaint = Paint()
      ..color = AppColors.phaseFollicular.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, normalTopY, chartWidth, normalBottomY),
        const Radius.circular(6),
      ),
      normalPaint,
    );

    // 2. Gambar Garis Rata-rata (Dashed Baseline)
    final avgY = getY(averageLength);
    final avgPaint = Paint()
      ..color = AppColors.phaseFollicular.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < chartWidth) {
      canvas.drawLine(
        Offset(startX, avgY),
        Offset(math.min(startX + dashWidth, chartWidth), avgY),
        avgPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 3. Gambar Batang-Batang Riwayat
    final barCount = history.length;
    final totalSpacing = chartWidth / (barCount + 1);
    final barWidth = math.min(28.0, totalSpacing * 0.65);

    for (int i = 0; i < barCount; i++) {
      final item = history[i];
      final centerX = totalSpacing * (i + 1);
      final barY = getY(item.cycleLengthDays.toDouble());
      final baseY = size.height - bottomPadding;

      // Warna batang: ongoing lebih gelap, selesai soft pink
      final barPaint = Paint()
        ..color = item.isOngoing
            ? AppColors.primaryDark
            : (item.isOutlier ? AppColors.phaseLuteal : AppColors.primary)
        ..style = PaintingStyle.fill;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(centerX - (barWidth / 2), barY, centerX + (barWidth / 2), baseY),
        const Radius.circular(6),
      );
      canvas.drawRRect(barRect, barPaint);

      // Angka hari di atas batang
      final daysPainter = TextPainter(
        text: TextSpan(
          text: '${item.cycleLengthDays}h',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: item.isOngoing ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      daysPainter.paint(
        canvas,
        Offset(centerX - (daysPainter.width / 2), barY - daysPainter.height - 3),
      );

      // Label bulan di bawah batang
      final labelPainter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(centerX - (labelPainter.width / 2), baseY + 6),
      );
    }
  }

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(covariant _CycleBarChartPainter oldDelegate) {
    return oldDelegate.history != history || oldDelegate.averageLength != averageLength;
  }
}
