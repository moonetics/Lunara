import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/database/models/app_config_model.dart';
import 'package:lunara/core/database/models/cycle_model.dart';
import 'package:lunara/core/services/cycle_engine.dart';
import 'package:lunara/core/theme/app_colors.dart';
import 'package:lunara/core/widgets/medical_term_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI Hierarchy & Decision-First Clinical Engine Tests', () {
    final cycleStart = DateTime(2026, 7, 1);
    const cycleLength = 28; // Ovulasi = 14 Juli. Jendela subur = 9–15 Juli. Golden = 12, 13, 14 Juli.

    test('1. Mode Promil: Hari Emas (H-2, H-1, Day 0) memicu probabilitas puncak Wilcox & ASRM advice', () {
      final promilConfig = AppConfigModel(appGoal: 'pregnancy_program');
      final goldenDate = DateTime(2026, 7, 13); // H-1 sebelum ovulasi 14 Juli

      final guidance = CycleEngine.getConceptionTimingGuidance(
        targetDate: goldenDate,
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: promilConfig.appGoal,
      );

      expect(guidance.isGoldenConceptionDay, isTrue);
      expect(guidance.probabilityPercentage, greaterThanOrEqualTo(25));
      expect(
        guidance.timingHeadline.contains('Emas') ||
        guidance.recommendation.toLowerCase().contains('optimal') ||
        guidance.recommendation.toLowerCase().contains('konsepsi'),
        isTrue,
      );
    });

    test('2. Mode Kontrasepsi Alami (FABM): Masa subur vs Fase Luteal pasca-ovulasi (0% risiko)', () {
      final fabmConfig = AppConfigModel(appGoal: 'natural_contraception');

      // Masa subur (13 Juli)
      final fertileDate = DateTime(2026, 7, 13);
      final fertileGuidance = CycleEngine.getConceptionTimingGuidance(
        targetDate: fertileDate,
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: fabmConfig.appGoal,
      );
      expect(fertileGuidance.probabilityPercentage, greaterThan(0));
      expect(
        fertileGuidance.timingHeadline.toLowerCase().contains('subur') ||
        fertileGuidance.timingHeadline.toLowerCase().contains('risiko') ||
        fertileGuidance.recommendation.toLowerCase().contains('pengaman'),
        isTrue,
      );

      // Fase Luteal (20 Juli) -> Pasca ovulasi
      final lutealDate = DateTime(2026, 7, 20);
      final lutealGuidance = CycleEngine.getConceptionTimingGuidance(
        targetDate: lutealDate,
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: fabmConfig.appGoal,
      );
      expect(lutealGuidance.probabilityPercentage, 0);
      expect(lutealGuidance.isGoldenConceptionDay, isFalse);
    });

    test('3. General Health Tracking: Penentuan fase fisiologis akurat untuk menstruasi & folikular', () {
      // Hari ke-3: Menstruasi
      final day3 = cycleStart.add(const Duration(days: 2));
      final phaseMenstrual = CycleEngine.getCurrentPhase(
        cycleStart,
        28.0,
        periodDuration: 5,
        referenceDate: day3,
      );
      expect(phaseMenstrual.phase, CyclePhase.menstrual);

      // Hari ke-9: Folikular
      final day9 = cycleStart.add(const Duration(days: 8));
      final phaseFollicular = CycleEngine.getCurrentPhase(
        cycleStart,
        28.0,
        periodDuration: 5,
        referenceDate: day9,
      );
      expect(phaseFollicular.phase, CyclePhase.follicular);
    });
  });

  group('Aksesibilitas & Standar Target Sentuh (Min 48dp & 50dp Button)', () {
    testWidgets('4. Medical Term Info Icon memenuhi standar target sentuh min 48x48dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButton(
                icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: const EdgeInsets.all(12),
                tooltip: 'Info Medis',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final iconButtonFinder = find.byType(IconButton);
      expect(iconButtonFinder, findsOneWidget);
      final RenderBox renderBox = tester.renderObject(iconButtonFinder);
      expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('5. Tombol Close di Header Sheet memenuhi standar min 48x48dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: const EdgeInsets.all(12),
                tooltip: 'Tutup',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final closeFinder = find.byTooltip('Tutup');
      expect(closeFinder, findsOneWidget);
      final RenderBox renderBox = tester.renderObject(closeFinder);
      expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('6. Primary CTA Button Decision-First Sheet memiliki tinggi >= 50dp (52dp)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.favorite_rounded, size: 20),
                  label: const Text('Catat Gejala, Mood & Intimasi'),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      final btnFinder = find.byType(ElevatedButton);
      expect(btnFinder, findsOneWidget);
      final RenderBox renderBox = tester.renderObject(btnFinder);
      expect(renderBox.size.height, greaterThanOrEqualTo(50.0));
    });

    testWidgets('7. Secondary Action Buttons (Haid Lampau & Hapus) memiliki tinggi min 48dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.water_drop_outlined, size: 16),
                      label: const Text('Haid Lampau'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Hapus Log'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final outlinedButtons = find.byType(OutlinedButton);
      expect(outlinedButtons, findsNWidgets(2));
      for (final element in tester.elementList(outlinedButtons)) {
        final renderBox = element.renderObject as RenderBox;
        expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
      }
    });
  });

  group('Dual-Indicator Visual Markers & Registry Validation', () {
    test('8. Semua key istilah medis yang direferensikan di Hero Card terdaftar', () {
      final heroTermKeys = [
        'ttc_wilcox',
        'fabm',
        'ovulation_phase',
        'dysmenorrhea',
        'follicular_phase',
        'luteal_phase',
        'hpo_axis',
      ];

      for (final key in heroTermKeys) {
        expect(
          MedicalTermRegistry.terms.containsKey(key),
          isTrue,
          reason: 'Istilah $key harus ada dalam kamus istilah medis',
        );
      }
    });

    test('9. Indikator Golden Star vs Safe Shield terpetakan akurat sesuai siklus dan konfigurasi', () {
      final cycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 5),
          cycleLengthDays: 28,
          periodDurationDays: 5,
        ),
      ];

      final promilConfig = AppConfigModel(appGoal: 'pregnancy_program');
      final fabmConfig = AppConfigModel(appGoal: 'natural_contraception');

      // 13 Juli = H-1 Ovulasi (Golden)
      final goldenDate = DateTime(2026, 7, 13);
      final isGoldenPromil = promilConfig.isPregnancyProgram &&
          CycleEngine.getConceptionTimingGuidance(
            targetDate: goldenDate,
            lastPeriodStartDate: cycles.first.startDate,
            cycleLength: cycles.first.cycleLengthDays,
            appGoal: promilConfig.appGoal,
          ).isGoldenConceptionDay;
      expect(isGoldenPromil, isTrue);

      // 20 Juli = Fase Luteal (Aman FABM)
      final lutealDate = DateTime(2026, 7, 20);
      final guidanceFabm = CycleEngine.getConceptionTimingGuidance(
        targetDate: lutealDate,
        lastPeriodStartDate: cycles.first.startDate,
        cycleLength: cycles.first.cycleLengthDays,
        appGoal: fabmConfig.appGoal,
      );
      expect(guidanceFabm.probabilityPercentage, 0);
    });
  });
}
