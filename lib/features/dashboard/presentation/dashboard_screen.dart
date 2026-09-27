import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/medical_constants.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/database/models/app_config_model.dart';
import '../../../core/services/cycle_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../pain_relief/presentation/pain_relief_screen.dart';
import '../../pdf_export/presentation/patient_info_dialog.dart';
import '../../quick_log/presentation/quick_log_sheet.dart';
import '../../../core/services/notification_service.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../tracker/state/cycle_notifier.dart';
import '../../tracker/state/cycle_state.dart';
import '../../triage_delay/presentation/triage_questionnaire_screen.dart';
import '../../../core/widgets/medical_term_bottom_sheet.dart';
import 'cycle_insights_screen.dart';

/// Layar Dashboard Utama Lunara (Dual-Perspective)
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late AppConfigModel _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    LocalDbService.instance.configNotifier.addListener(_onConfigChanged);
  }

  void _onConfigChanged() {
    if (mounted) {
      setState(() {
        _config = LocalDbService.instance.configNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    LocalDbService.instance.configNotifier.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _loadConfig() {
    setState(() {
      _config = LocalDbService.instance.getConfig();
    });
  }

  void _openQuickLog() {
    HapticFeedback.lightImpact();
    QuickLogSheet.show(
      context,
      onSaved: () async {
        await ref.read(cycleProvider.notifier).loadCycles();
        _loadConfig();
        if (_config.isNotificationsEnabled) {
          final cycleState = ref.read(cycleProvider);
          await NotificationService.instance.scheduleCycleReminders(
            cycleState: cycleState,
            config: _config,
          );
        }
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycleState = ref.watch(cycleProvider);
    final phaseInfo = cycleState.currentPhaseInfo;
    final isMaleHelper = _config.isMaleHelper;
    final partnerName = _config.partnerName.isNotEmpty ? _config.partnerName : 'Pasangan';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_without_text.png',
                    height: 22,
                    width: 22,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LUNARA',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMaleHelper ? 'Mendampingi $partnerName' : 'Ruang Pribadi',
                style: AppTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Ganti Perspektif Pengguna',
            onPressed: () {
              HapticFeedback.lightImpact();
              final newPerspective = isMaleHelper ? 'female_self' : 'male_helper';
              _config.perspective = newPerspective;
              LocalDbService.instance.saveConfig(_config);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Text(
                    newPerspective == 'male_helper'
                        ? 'Beralih ke Mode: Membantu $partnerName'
                        : 'Beralih ke Mode: Mencatat Mandiri',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan & Privasi',
            onPressed: () async {
              HapticFeedback.lightImpact();
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadConfig();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(cycleProvider.notifier).loadCycles();
            _loadConfig();
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Banner Keterlambatan Proaktif (Jika telat >= 3 hari)
                if (cycleState.isDelayed && cycleState.delayDays >= MedicalConstants.earlyDelayThreshold)
                  _buildProactiveDelayCard(cycleState.delayDays),

                // 2. Visualisasi Utama: Cycle Progress Ring
                _buildCycleProgressRing(cycleState, phaseInfo),

                // 3. Tombol Aksi Utama: Mulai Haid / Selesaikan Haid Dinamis
                _buildPeriodActionCTA(cycleState),

                const SizedBox(height: 24),

                // 4. Widget Panduan Khusus Pria (Partner Care Widget)
                if (isMaleHelper && phaseInfo != null) ...[
                  _buildPartnerCareCard(phaseInfo, partnerName),
                  const SizedBox(height: 16),
                ],

                // Level 2: Kartu Fokus Hari Ini (Today's Contextual Spotlight)
                // Menyatukan Mode Rekomendasi (Promil/FABM/Kesehatan), Peluang Konsepsi, dan Tips Tubuh ke dalam 1 kartu terpadu
                if (phaseInfo != null) ...[
                  _buildTodaySpotlightCard(
                    cycleState: cycleState,
                    phaseInfo: phaseInfo,
                    config: _config,
                  ),
                  const SizedBox(height: 16),
                ],

                // 6. Akses Cepat Medis & Pustaka Nyeri
                _buildQuickActionCards(context),

                const SizedBox(height: 14),

                // 7. Kartu Akses Tren & Statistik Siklus (ACOG Bulletin 219)
                _buildCycleInsightsCard(context),

                const SizedBox(height: 80), // Padding untuk tombol melayang
              ],
            ),
          ),
        ),
      ),
      // Tombol Pencatatan Kilat 3-Detik di Bawah
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _openQuickLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.favorite_border_rounded, size: 22),
            label: Text(
              isMaleHelper ? 'Catat Gejala & Intimasi Pasangan' : 'Catat Gejala & Intimasi (< 3 Detik)',
              style: AppTypography.labelLarge.copyWith(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SUB-WIDGETS ====================

  /// Banner Peringatan Keterlambatan Proaktif & Tombol Penyelamat Lupa Tanggal
  Widget _buildProactiveDelayCard(int delayDays) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Belum ada catatan haid baru ($delayDays hari)',
                  style: AppTypography.titleLarge.copyWith(color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Apakah kamu sempat haid kemarin tapi lupa tanggal pastinya? Kamu bisa langsung reset ke siklus bersih agar status kembali tenang.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await ref.read(cycleProvider.notifier).resetCycleStatus();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text('Status siklus berhasil direset ke mode bersih.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Reset Bersih', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TriageQuestionnaireScreen(daysDelayed: delayDays),
                      ),
                    );
                  },
                  child: const Text('Cek Medis', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tombol Aksi Utama: Mulai Haid Hari Ini vs Selesaikan Haid Hari Ini
  Widget _buildPeriodActionCTA(CycleState cycleState) {
    final active = cycleState.activeCycle;
    final isBleeding = active != null && active.isOngoing;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBleeding ? AppColors.phaseMenstrualLight : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBleeding ? AppColors.phaseMenstrual : AppColors.border,
          width: isBleeding ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                if (isBleeding) {
                  // Konfirmasi Selesai Haid
                  final duration = DateTime.now().difference(active.startDate).inDays + 1;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Selesaikan Haid Hari Ini?'),
                      content: Text(
                        'Darah haid telah berhenti? Durasi haid kamu tercatat $duration hari.',
                        style: AppTypography.bodyMedium,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ya, Selesai'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(cycleProvider.notifier).endCurrentPeriod();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text('Haid selesai! Durasi tercatat $duration hari.'),
                        ),
                      );
                    }
                  }
                } else {
                  // Mulai Haid Hari Ini
                  await ref.read(cycleProvider.notifier).startNewPeriod();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.primary,
                        content: Text('Periode haid dimulai! Lunara mulai menghitung durasimu.'),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isBleeding ? AppColors.phaseMenstrual : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: Icon(isBleeding ? Icons.check_circle_outline_rounded : Icons.water_drop_rounded),
              label: Text(
                isBleeding ? 'Selesaikan Haid Hari Ini' : 'Mulai Haid Hari Ini',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          if (!isBleeding) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 1)),
                  firstDate: DateTime.now().subtract(const Duration(days: 60)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  await ref.read(cycleProvider.notifier).startNewPeriod(picked);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        content: Text('Haid dimulai pada tanggal yang kamu pilih.'),
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Baru sempat mencatat? Pilih tanggal mulai',
                style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Visualisasi Siklus Melingkar (Progress Ring) Adaptif
  Widget _buildCycleProgressRing(CycleState cycleState, CyclePhaseInfo? phaseInfo) {
    final active = cycleState.activeCycle;
    final isBleeding = active != null && active.isOngoing;
    final dayOfCycle = isBleeding
        ? (DateTime.now().difference(active.startDate).inDays + 1)
        : (phaseInfo?.dayOfCycle ?? 1);
    final totalDays = cycleState.averageCycleLength.round();
    final progress = active == null
        ? 0.0
        : (isBleeding ? 0.25 : (dayOfCycle / totalDays).clamp(0.0, 1.0));

    final isContraceptionMode = _config.isNaturalContraception;
    final isPromilMode = _config.isPregnancyProgram;
    final isFertileNow = active != null &&
        CycleEngine.isDateInFertileWindow(
          DateTime.now(),
          active.startDate,
          totalDays,
        );
    final timingGuidance = active != null
        ? CycleEngine.getConceptionTimingGuidance(
            targetDate: DateTime.now(),
            lastPeriodStartDate: active.startDate,
            cycleLength: totalDays,
            appGoal: _config.appGoal,
          )
        : null;

    Color themeColor = isBleeding
        ? AppColors.phaseMenstrual
        : (phaseInfo?.themeColor ?? AppColors.primary);
    Color lightColor = isBleeding
        ? AppColors.phaseMenstrualLight
        : (phaseInfo?.lightColor ?? AppColors.primaryContainer);

    if (isContraceptionMode && active != null && !isBleeding) {
      if (isFertileNow) {
        themeColor = AppColors.phaseOvulation;
        lightColor = AppColors.phaseOvulationLight;
      } else {
        themeColor = AppColors.phaseFollicular;
        lightColor = AppColors.phaseFollicularLight;
      }
    } else if (isPromilMode && active != null && !isBleeding) {
      if (timingGuidance?.isGoldenConceptionDay == true) {
        themeColor = AppColors.intimacyAccent;
        lightColor = AppColors.intimacyLight;
      } else if (isFertileNow) {
        themeColor = AppColors.phaseOvulation;
        lightColor = AppColors.phaseOvulationLight;
      } else {
        themeColor = AppColors.phaseLuteal;
        lightColor = AppColors.phaseLutealLight;
      }
    }

    String ringTitle = 'Selamat Datang';
    String ringCenterText = 'Siap Catat';
    String ringSubText = 'Belum ada haid terekam';
    String ringBadge = 'Tekan Mulai Haid di bawah';

    if (active != null) {
      if (isBleeding) {
        ringTitle = 'Sedang Menstruasi';
        ringCenterText = 'Hari ke-$dayOfCycle';
        ringSubText = isContraceptionMode
            ? 'Fase Tidak Subur'
            : (isPromilMode ? 'Peluang Konsepsi 0%' : 'Darah haid aktif');
        ringBadge = isContraceptionMode
            ? '🩸 Risiko Konsepsi Minimal'
            : (isPromilMode ? 'Fase Menstruasi — Istirahat' : 'Durasi berjalan alami');
      } else {
        ringTitle = phaseInfo?.phaseTitle ?? 'Fase Siklus';
        ringCenterText = 'Hari ke-$dayOfCycle';
        if (isContraceptionMode) {
          ringSubText = isFertileNow ? 'Jendela ovulasi aktif' : 'Di luar masa subur';
          ringBadge = isFertileNow ? '⚠️ Zona Subur — Risiko Tinggi' : '🛡️ Fase Rendah Risiko';
        } else if (isPromilMode) {
          if (timingGuidance?.isGoldenConceptionDay == true) {
            ringTitle = 'Hari Emas Promil';
            ringSubText = 'Peluang Konsepsi ~${timingGuidance?.probabilityPercentage}% (Wilcox)';
            ringBadge = '⭐ Hari Emas Konsepsi — Waktu Terbaik';
          } else if (isFertileNow) {
            ringTitle = 'Jendela Subur Promil';
            ringSubText = 'Peluang Konsepsi ~${timingGuidance?.probabilityPercentage}%';
            ringBadge = '✨ Peluang Terbuka — Sambut Ovulasi';
          } else {
            final daysToOvu = timingGuidance?.daysToOvulation ?? 0;
            if (daysToOvu < -5) {
              ringSubText = '${daysToOvu.abs() - 5} hari menuju jendela subur';
              ringBadge = '🌱 Menyiapkan Sel Telur';
            } else {
              ringSubText = 'Fase Luteal pasca-ovulasi';
              ringBadge = '🌿 Masa Istirahat Siklus';
            }
          }
        } else {
          ringSubText = 'dari $totalDays hari siklus';
          ringBadge = phaseInfo?.phaseSubtitle ?? 'Estimasi berjalan';
        }
      }
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: CustomPaint(
              painter: _CycleRingPainter(
                progress: progress,
                trackColor: AppColors.borderSubtle,
                progressColor: themeColor,
              ),
            ),
          ),
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              color: lightColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ringTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: themeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ringCenterText,
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  ringSubText,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    ringBadge,
                    style: AppTypography.badgeText.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Panduan Pendamping untuk Pasangan Pria
  Widget _buildPartnerCareCard(CyclePhaseInfo phaseInfo, String partnerName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Panduan Pendamping Hari Ini',
                style: AppTypography.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            phaseInfo.partnerCareAdvice,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined, color: AppColors.phaseFollicular, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saran: Sikap tenang dan perhatian tulusmu membantu menstabilkan hormon stres $partnerName.',
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Level 2: Kartu Fokus Hari Ini (Today's Contextual Spotlight)
  /// Mengintegrasikan Status Mode (Promil/FABM/Kesehatan), Peluang Konsepsi Wilcox NEJM,
  /// dan Rangkuman Fisiologis Tubuh (Nutrisi, Energi, Perawatan) ke dalam 1 kartu terpadu
  Widget _buildTodaySpotlightCard({
    required CycleState cycleState,
    required CyclePhaseInfo phaseInfo,
    required AppConfigModel config,
  }) {
    final active = cycleState.activeCycle;
    final totalDays = cycleState.averageCycleLength.round();
    final isPromil = config.isPregnancyProgram;
    final isContraception = config.isNaturalContraception;

    final timingGuidance = active != null
        ? CycleEngine.getConceptionTimingGuidance(
            targetDate: DateTime.now(),
            lastPeriodStartDate: active.startDate,
            cycleLength: totalDays,
            appGoal: config.appGoal,
          )
        : null;

    // Tentukan tema & istilah medis kartu berdasarkan mode aktif & fase
    String spotlightTitle;
    String spotlightSubtitle;
    String primaryAdvice;
    String termKey;
    IconData spotlightIcon;
    Color accentColor;
    Color containerColor;

    if (isPromil) {
      termKey = 'ttc_wilcox';
      accentColor = AppColors.intimacyAccent;
      containerColor = AppColors.intimacyLight;
      spotlightIcon = Icons.stars_rounded;

      if (timingGuidance?.isGoldenConceptionDay == true) {
        spotlightTitle = 'Hari Emas Konsepsi (~${timingGuidance?.probabilityPercentage}%)';
        spotlightSubtitle = 'Mode Program Hamil • Puncak Wilcox NEJM';
        primaryAdvice = timingGuidance?.recommendation ??
            'Waktu paling optimal untuk berhubungan intim bila merencanakan kehamilan. ASRM menganjurkan frekuensi setiap 1–2 hari sekali.';
      } else if ((timingGuidance?.probabilityPercentage ?? 0) > 0) {
        spotlightTitle = 'Jendela Subur Aktif (~${timingGuidance?.probabilityPercentage}%)';
        spotlightSubtitle = 'Mode Program Hamil • Sambut Ovulasi';
        primaryAdvice = timingGuidance?.recommendation ??
            'Sperma dapat bertahan hingga 5 hari di serviks. Berhubungan intim di fase ini mulai efektif menyambut ovulasi.';
      } else {
        spotlightTitle = 'Fase Istirahat Siklus';
        spotlightSubtitle = 'Mode Program Hamil • Menyiapkan Sel Telur';
        primaryAdvice = timingGuidance?.recommendation ??
            'Di luar jendela ovulasi. Fokus pada asupan nutrisi sehat dan istirahat berkualitas menyambut fase subur berikutnya.';
      }
    } else if (isContraception) {
      termKey = 'fabm';
      final isSafe = timingGuidance?.isAbsoluteSafeDay ?? false;
      final isFertile = (timingGuidance?.probabilityPercentage ?? 0) > 0;

      if (isFertile) {
        accentColor = AppColors.phaseOvulation;
        containerColor = AppColors.phaseOvulationLight;
        spotlightIcon = Icons.warning_amber_rounded;
        spotlightTitle = 'Zona Merah Konsepsi (Masa Subur)';
        spotlightSubtitle = 'Mode Tunda Hamil • Risiko Tinggi';
        primaryAdvice = timingGuidance?.recommendation ??
            'Hindari penetrasi tanpa proteksi atau gunakan kondom jika sedang mencegah kehamilan.';
      } else if (isSafe) {
        accentColor = AppColors.phaseFollicular;
        containerColor = AppColors.phaseFollicularLight;
        spotlightIcon = Icons.shield_outlined;
        spotlightTitle = 'Zona Aman Fisiologis (0%)';
        spotlightSubtitle = 'Mode Tunda Hamil • Bebas Pengaman ACOG';
        primaryAdvice = timingGuidance?.recommendation ??
            'Sel telur telah berdegenerasi dan progesteron mengentalkan lendir serviks. Peluang kehamilan secara biologis mendekati 0%.';
      } else {
        accentColor = AppColors.phaseFollicular;
        containerColor = AppColors.phaseFollicularLight;
        spotlightIcon = Icons.shield_outlined;
        spotlightTitle = 'Fase Rendah Risiko Konsepsi';
        spotlightSubtitle = 'Mode Tunda Hamil • Pra-Ovulasi';
        primaryAdvice = timingGuidance?.recommendation ??
            'Peluang konsepsi kalender minimal. Tetap gunakan proteksi untuk perlindungan optimal.';
      }
    } else {
      // Mode Kesehatan Siklus Default
      accentColor = phaseInfo.themeColor;
      containerColor = phaseInfo.lightColor;
      spotlightIcon = Icons.wb_sunny_rounded;
      spotlightTitle = phaseInfo.phaseTitle;
      spotlightSubtitle = 'Mode Kesehatan Siklus • Hari ke-${phaseInfo.dayOfCycle}';
      primaryAdvice = phaseInfo.biologicalSummary;
      termKey = phaseInfo.isLate
          ? 'hpo_axis'
          : (phaseInfo.phase == CyclePhase.menstrual
              ? 'dysmenorrhea'
              : (phaseInfo.phase == CyclePhase.follicular
                  ? 'follicular_phase'
                  : (phaseInfo.phase == CyclePhase.ovulation
                      ? 'ovulation_phase'
                      : 'luteal_phase')));
    }

    // Ekstraksi 3 tips harian tubuh (Nutrisi, Energi, Perawatan)
    String nutritionTip;
    String activityTip;
    String careTip;

    if (phaseInfo.isLate) {
      nutritionTip = 'Makanan hangat & minim kafein.';
      activityTip = 'Pernapasan diafragma turunkan kortisol.';
      careTip = 'Tes urine pagi jika ada riwayat intim.';
    } else {
      switch (phaseInfo.phase) {
        case CyclePhase.menstrual:
          nutritionTip = 'Zat besi & magnesium (bayam, dark chocolate).';
          activityTip = 'Peregangan santai (child\'s pose) atau jalan ringan.';
          careTip = 'Air hangat 2L & kompres perut bawah.';
          break;
        case CyclePhase.follicular:
          nutritionTip = 'Sayuran hijau, serat & protein sehat.';
          activityTip = 'Estrogen melonjak: stamina prima untuk olahraga.';
          careTip = 'Tidur cukup 7–8 jam dukung folikel.';
          break;
        case CyclePhase.ovulation:
          nutritionTip = 'Antioksidan buah beri, asam folat & alpukat.';
          activityTip = 'Puncak rasa percaya diri & energi sosial tinggi.';
          careTip = 'Amati lendir serviks (bening elastis).';
          break;
        case CyclePhase.luteal:
          nutritionTip = 'Batasi garam & kopi cegah kembung PMS.';
          activityTip = 'Pilates atau jalan santai redakan ketegangan.';
          careTip = 'Waktu istirahat lebih tenang (progesteron dominan).';
          break;
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Spotlight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: containerColor.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(spotlightIcon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spotlightTitle,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        spotlightSubtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                MedicalTermHelper.infoIcon(context, termKey, color: accentColor),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rekomendasi Utama Mode Hari Ini
                Text(
                  primaryAdvice,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),

                // Trio Penyelarasan Tubuh (Nutrisi, Energi, Perawatan)
                Text(
                  'PANDUAN HARIAN TUBUH',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSpotlightMiniRow(
                  icon: Icons.restaurant_rounded,
                  iconColor: AppColors.phaseFollicular,
                  label: 'Nutrisi',
                  content: nutritionTip,
                ),
                const SizedBox(height: 6),
                _buildSpotlightMiniRow(
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.phaseLuteal,
                  label: 'Energi',
                  content: activityTip,
                ),
                const SizedBox(height: 6),
                _buildSpotlightMiniRow(
                  icon: Icons.spa_rounded,
                  iconColor: AppColors.primary,
                  label: 'Perawatan',
                  content: careTip,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightMiniRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            color: AppColors.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            content,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PainReliefScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.phaseMenstrualLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.self_improvement_rounded, color: AppColors.phaseMenstrual, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pereda Nyeri',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '4 Terapi Non-Obat ACOG',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              PatientInfoDialog.show(context);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ekspor PDF',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rekam Medis Dokter Sp.OG',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Kartu Akses Tren & Statistik Siklus (ACOG Practice Bulletin No. 219)
  Widget _buildCycleInsightsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CycleInsightsScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_graph_rounded, color: AppColors.primaryDark, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Tren & Statistik Siklus',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.phaseFollicularLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACOG 219',
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.phaseFollicular,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Grafik variasi 6 bulan & analisis gejala terbanyak',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar progress ring siklus
class _CycleRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _CycleRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    // 1. Gambar Track Latar Belakang
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Gambar Busur Progress Aktif
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CycleRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
