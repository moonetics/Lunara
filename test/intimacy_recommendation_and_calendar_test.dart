import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/database/models/cycle_model.dart';
import 'package:lunara/core/services/cycle_engine.dart';
import 'package:lunara/core/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Penyelarasan Kalender Dinamis (38 Hari Siklus) & Masa Subur', () {
    test('1. Siklus 38 hari: Tanggal 2 dan 3 Agustus berada di dalam jendela ovulasi (Masa Subur)', () {
      final cycleStart = DateTime(2026, 7, 12);
      const cycleLength = 38;

      // Pada siklus 38 hari: Ovulasi = 38 - 14 = Hari ke-24 (4 Agustus 2026)
      // Jendela subur = H-5 s/d H+1 (30 Juli s/d 5 Agustus 2026)
      final dateAug2 = DateTime(2026, 8, 2);
      final dateAug3 = DateTime(2026, 8, 3);
      final dateAug4 = DateTime(2026, 8, 4); // Hari ovulasi
      final dateAug10 = DateTime(2026, 8, 10); // Fase Luteal

      expect(CycleEngine.isDateInFertileWindow(dateAug2, cycleStart, cycleLength), isTrue);
      expect(CycleEngine.isDateInFertileWindow(dateAug3, cycleStart, cycleLength), isTrue);
      expect(CycleEngine.isDateInFertileWindow(dateAug4, cycleStart, cycleLength), isTrue);
      expect(CycleEngine.isDateInFertileWindow(dateAug10, cycleStart, cycleLength), isFalse);
    });

    test('2. findCycleForDate menemukan siklus yang tepat untuk tanggal tertentu', () {
      final cycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 7, 12),
          endDate: DateTime(2026, 7, 18),
          cycleLengthDays: 38,
          periodDurationDays: 7,
        ),
        CycleModel(
          cycleId: 'c2',
          startDate: DateTime(2026, 8, 19),
          endDate: DateTime(2026, 8, 25),
          cycleLengthDays: 28,
          periodDurationDays: 7,
        ),
      ];

      final matchedJuly = CycleEngine.findCycleForDate(DateTime(2026, 8, 3), cycles);
      expect(matchedJuly, isNotNull);
      expect(matchedJuly!.cycleId, 'c1');
      expect(matchedJuly.startDate, DateTime(2026, 7, 12));

      final matchedAug = CycleEngine.findCycleForDate(DateTime(2026, 8, 20), cycles);
      expect(matchedAug, isNotNull);
      expect(matchedAug!.cycleId, 'c2');
      expect(matchedAug.startDate, DateTime(2026, 8, 19));
    });
  });

  group('Rekomendasi Intimasi Klinis & Panduan Higienitas', () {
    final cycleStart = DateTime(2026, 7, 12);
    const cycleLength = 38;

    test('3. Masa Subur + Dengan Pengaman memberikan status Terproteksi dan efektivitas kondom', () {
      final analysis = CycleEngine.getIntimacyConceptionAnalysis(
        intimacyDate: DateTime(2026, 8, 3), // H-1 sebelum ovulasi 4 Agustus
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        hasProtection: true,
        appGoal: 'natural_contraception',
      );

      expect(analysis.isHighConceptionRisk, isFalse);
      expect(analysis.statusLabel, 'Masa Subur (Terproteksi)');
      expect(analysis.badgeColor, AppColors.phaseOvulation);
      expect(analysis.actionableAdvice.contains('98%'), isTrue);
      expect(analysis.hygieneTip.contains('buang air kecil'), isTrue);
      expect(analysis.timingContext.contains('Sebelum Ovulasi'), isTrue);
    });

    test('4. Masa Subur + Tanpa Pengaman (Mode Kontrasepsi) memberikan peringatan darurat 72 jam', () {
      final analysis = CycleEngine.getIntimacyConceptionAnalysis(
        intimacyDate: DateTime(2026, 8, 3),
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        hasProtection: false,
        appGoal: 'natural_contraception',
      );

      expect(analysis.isHighConceptionRisk, isTrue);
      expect(analysis.statusLabel, 'Peluang Konsepsi Tinggi');
      expect(analysis.badgeColor, AppColors.intimacyAccent);
      expect(analysis.actionableAdvice.contains('72 jam'), isTrue);
      expect(analysis.actionableAdvice.contains('POGI'), isTrue);
      expect(analysis.hygieneTip.contains('ISK'), isTrue);
    });

    test('5. Masa Subur + Tanpa Pengaman (Mode Kesehatan) memberikan informasi konsepsi promil', () {
      final analysis = CycleEngine.getIntimacyConceptionAnalysis(
        intimacyDate: DateTime(2026, 8, 3),
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        hasProtection: false,
        appGoal: 'health_tracking',
      );

      expect(analysis.isHighConceptionRisk, isTrue);
      expect(analysis.actionableAdvice.contains('optimal untuk pembuahan'), isTrue);
      expect(analysis.hygieneTip.isNotEmpty, isTrue);
    });

    test('6. Di Luar Masa Subur (Fase Luteal) memberikan status aman & tips higienitas', () {
      final analysis = CycleEngine.getIntimacyConceptionAnalysis(
        intimacyDate: DateTime(2026, 8, 10),
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        hasProtection: false,
        appGoal: 'natural_contraception',
      );

      expect(analysis.isHighConceptionRisk, isFalse);
      expect(analysis.statusLabel, 'Tanpa Pengaman (Di Luar Masa Subur)');
      expect(analysis.timingContext.contains('Luteal'), isTrue);
      expect(analysis.hygieneTip.contains('BAK'), isTrue);
    });

    test('7. Mode Program Hamil (TTC): Hari Emas Konsepsi memberikan edukasi ASRM frekuensi intim', () {
      final analysis = CycleEngine.getIntimacyConceptionAnalysis(
        intimacyDate: DateTime(2026, 8, 2), // H-2 sebelum ovulasi 4 Agustus
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        hasProtection: false,
        appGoal: 'pregnancy_program',
      );

      expect(analysis.isHighConceptionRisk, isTrue);
      expect(analysis.statusLabel.contains('Hari Emas Konsepsi (Promil)'), isTrue);
      expect(analysis.badgeColor, AppColors.intimacyAccent);
      expect(analysis.actionableAdvice.contains('1–2 hari'), isTrue);
      expect(analysis.actionableAdvice.contains('ASRM'), isTrue);
    });
  });

  group('Wilcox et al. (NEJM 1995) Evidence-Based Conception Timing Engine', () {
    final cycleStart = DateTime(2026, 7, 12);
    const cycleLength = 28; // Ovulasi = 28 - 14 = Hari ke-14 -> 25 Juli 2026 (12 + 13 hari)

    test('8. Probabilitas Harian Wilcox NEJM sesuai persentase klinis', () {
      final ovulationDay = DateTime(2026, 7, 25);

      // Hari Emas (H-2, H-1, Day 0)
      final hMinus2 = CycleEngine.getConceptionTimingGuidance(
        targetDate: ovulationDay.subtract(const Duration(days: 2)),
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: 'pregnancy_program',
      );
      expect(hMinus2.probabilityPercentage, 36);
      expect(hMinus2.isGoldenConceptionDay, isTrue);
      expect(hMinus2.recommendation.contains('Wilcox NEJM'), isTrue);

      final hMinus1 = CycleEngine.getConceptionTimingGuidance(
        targetDate: ovulationDay.subtract(const Duration(days: 1)),
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: 'pregnancy_program',
      );
      expect(hMinus1.probabilityPercentage, 34);
      expect(hMinus1.isGoldenConceptionDay, isTrue);

      final dayZero = CycleEngine.getConceptionTimingGuidance(
        targetDate: ovulationDay,
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: 'pregnancy_program',
      );
      expect(dayZero.probabilityPercentage, 36);
      expect(dayZero.isGoldenConceptionDay, isTrue);

      // Jendela Subur Awal (H-3, H-4, H-5)
      final hMinus3 = CycleEngine.getConceptionTimingGuidance(
        targetDate: ovulationDay.subtract(const Duration(days: 3)),
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: 'pregnancy_program',
      );
      expect(hMinus3.probabilityPercentage, 14);
      expect(hMinus3.isGoldenConceptionDay, isFalse);

      final hMinus4 = CycleEngine.getConceptionTimingGuidance(
        targetDate: ovulationDay.subtract(const Duration(days: 4)),
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: 'pregnancy_program',
      );
      expect(hMinus4.probabilityPercentage, 16);
      expect(hMinus4.isGoldenConceptionDay, isFalse);

      final hMinus5 = CycleEngine.getConceptionTimingGuidance(
        targetDate: ovulationDay.subtract(const Duration(days: 5)),
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: 'pregnancy_program',
      );
      expect(hMinus5.probabilityPercentage, 10);
      expect(hMinus5.isGoldenConceptionDay, isFalse);

      // Pasca-ovulasi (H+1 dan H+2/Luteal)
      final hPlus1 = CycleEngine.getConceptionTimingGuidance(
        targetDate: ovulationDay.add(const Duration(days: 1)),
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: 'natural_contraception',
      );
      expect(hPlus1.probabilityPercentage, 4);

      final hPlus2 = CycleEngine.getConceptionTimingGuidance(
        targetDate: ovulationDay.add(const Duration(days: 2)),
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: 'natural_contraception',
      );
      expect(hPlus2.probabilityPercentage, 0);
      expect(hPlus2.isAbsoluteSafeDay, isTrue);
      expect(hPlus2.recommendation.contains('Zona Bebas Pengaman'), isTrue);
    });

    test('9. Adaptasi panduan rekomendasi antara Program Hamil vs Tunda Hamil pada Hari Emas', () {
      final goldenDate = DateTime(2026, 7, 24); // H-2

      final promilGuidance = CycleEngine.getConceptionTimingGuidance(
        targetDate: goldenDate,
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: 'pregnancy_program',
      );
      expect(promilGuidance.recommendation.contains('paling optimal untuk berhubungan intim'), isTrue);

      final tundaGuidance = CycleEngine.getConceptionTimingGuidance(
        targetDate: goldenDate,
        lastPeriodStartDate: cycleStart,
        cycleLength: cycleLength,
        appGoal: 'natural_contraception',
      );
      expect(tundaGuidance.recommendation.contains('Zona Merah'), isTrue);
      expect(tundaGuidance.recommendation.contains('kondom'), isTrue);
    });
  });
}
