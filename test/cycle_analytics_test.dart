import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/constants/medical_constants.dart';
import 'package:lunara/core/database/models/cycle_model.dart';
import 'package:lunara/core/database/models/daily_entry_model.dart';
import 'package:lunara/core/services/cycle_analytics_engine.dart';

void main() {
  group('CycleAnalyticsEngine - Clinical Regularity & Statistics Tests (ACOG Bulletin 219)', () {
    test('1. Baseline kosong (zero state) mengembalikan nilai default yang aman', () {
      final result = CycleAnalyticsEngine.calculate(cycles: [], entries: []);

      expect(result.averageCycleLength, MedicalConstants.baselineDefaultCycleLength.toDouble());
      expect(result.averagePeriodDuration, MedicalConstants.baselinePeriodDuration.toDouble());
      expect(result.totalCyclesRecorded, 0);
      expect(result.variabilityDays, 0);
      expect(result.regularityCode, 'insufficient_data');
      expect(result.topSymptoms, isEmpty);
      expect(result.topMoods, isEmpty);
      expect(result.totalIntimacyDays, 0);
      expect(result.hasCycleData, false);
      expect(result.hasPeriodData, false);
    });

    test('2. Hanya 1 siklus terekam mengembalikan status data terbatas', () {
      final cycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 8, 1),
          periodDurationDays: 5,
          cycleLengthDays: 29,
          isOngoing: false,
        ),
      ];

      final result = CycleAnalyticsEngine.calculate(cycles: cycles, entries: []);

      expect(result.totalCyclesRecorded, 1);
      expect(result.averageCycleLength, 29.0);
      expect(result.shortestCycleLength, 29);
      expect(result.longestCycleLength, 29);
      expect(result.variabilityDays, 0);
      expect(result.regularityCode, 'insufficient_data');
      expect(result.hasCycleData, true);
      expect(result.hasPeriodData, true);
    });

    test('3. Siklus sangat teratur (variasi <= 4 hari) diklasifikasikan very_regular', () {
      final cycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 6, 1),
          periodDurationDays: 5,
          cycleLengthDays: 28,
        ),
        CycleModel(
          cycleId: 'c2',
          startDate: DateTime(2026, 6, 29),
          periodDurationDays: 5,
          cycleLengthDays: 29,
        ),
        CycleModel(
          cycleId: 'c3',
          startDate: DateTime(2026, 7, 28),
          periodDurationDays: 6,
          cycleLengthDays: 27,
        ),
      ];

      final result = CycleAnalyticsEngine.calculate(cycles: cycles, entries: []);

      expect(result.averageCycleLength, 28.0);
      expect(result.shortestCycleLength, 27);
      expect(result.longestCycleLength, 29);
      expect(result.variabilityDays, 2); // 29 - 27 = 2 (<= 4)
      expect(result.regularityCode, 'very_regular');
      expect(result.regularityTitle, 'Siklus Sangat Teratur');
    });

    test('4. Siklus teratur normal ACOG (variasi 5-9 hari) diklasifikasikan regular', () {
      final cycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 5, 1),
          periodDurationDays: 5,
          cycleLengthDays: 26,
        ),
        CycleModel(
          cycleId: 'c2',
          startDate: DateTime(2026, 5, 27),
          periodDurationDays: 4,
          cycleLengthDays: 33, // 33 - 26 = 7 hari variasi
        ),
      ];

      final result = CycleAnalyticsEngine.calculate(cycles: cycles, entries: []);

      expect(result.variabilityDays, 7);
      expect(result.regularityCode, 'regular');
      expect(result.regularityTitle, contains('Standar Emas ACOG'));
    });

    test('5. Siklus fluktuasi ringan (variasi 10-14 hari) diklasifikasikan moderate', () {
      final cycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 4, 1),
          periodDurationDays: 5,
          cycleLengthDays: 25,
        ),
        CycleModel(
          cycleId: 'c2',
          startDate: DateTime(2026, 4, 26),
          periodDurationDays: 5,
          cycleLengthDays: 37, // 37 - 25 = 12 hari variasi
        ),
      ];

      final result = CycleAnalyticsEngine.calculate(cycles: cycles, entries: []);

      expect(result.variabilityDays, 12);
      expect(result.regularityCode, 'moderate');
      expect(result.regularityTitle, 'Variasi Fisiologis Ringan');
    });

    test('6. Siklus fluktuatif tinggi (> 14 hari) diklasifikasikan irregular', () {
      final cycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 3, 1),
          periodDurationDays: 5,
          cycleLengthDays: 24,
        ),
        CycleModel(
          cycleId: 'c2',
          startDate: DateTime(2026, 3, 25),
          periodDurationDays: 5,
          cycleLengthDays: 42, // 42 - 24 = 18 hari
        ),
      ];

      final result = CycleAnalyticsEngine.calculate(cycles: cycles, entries: []);

      expect(result.variabilityDays, 18);
      expect(result.regularityCode, 'irregular');
      expect(result.regularityTitle, 'Siklus Fluktuatif');
    });

    test('7. Smart Gap Handling: Jeda bolong (> 45 hari atau isUnrecordedGap) disaring dari rata-rata', () {
      final cycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 1, 1),
          periodDurationDays: 5,
          cycleLengthDays: 28,
        ),
        CycleModel(
          cycleId: 'c_gap',
          startDate: DateTime(2026, 1, 29),
          periodDurationDays: 5,
          cycleLengthDays: 60, // Gap bolong 2 bulan
          isUnrecordedGap: true,
          isOutlier: true,
        ),
        CycleModel(
          cycleId: 'c3',
          startDate: DateTime(2026, 3, 30),
          periodDurationDays: 5,
          cycleLengthDays: 30,
        ),
      ];

      final result = CycleAnalyticsEngine.calculate(cycles: cycles, entries: []);

      // Hanya c1 (28) dan c3 (30) yang dihitung: (28 + 30) / 2 = 29.0
      expect(result.averageCycleLength, 29.0);
      expect(result.shortestCycleLength, 28);
      expect(result.longestCycleLength, 30);
      expect(result.variabilityDays, 2);
      expect(result.ignoredGapCyclesCount, 1);
      expect(result.cycleHistory.length, 2);
      expect(result.cycleHistory.any((p) => p.cycleLengthDays == 60), isFalse);
    });

    test('8. Analisis frekuensi keluhan & persentase gejala terbanyak presisi', () {
      final entries = [
        DailyEntryModel(
          entryId: 'e1',
          cycleId: 'c1',
          entryDate: DateTime(2026, 9, 25),
          symptoms: ['cramps', 'headache'],
        ),
        DailyEntryModel(
          entryId: 'e2',
          cycleId: 'c1',
          entryDate: DateTime(2026, 9, 26),
          symptoms: ['cramps'],
        ),
        DailyEntryModel(
          entryId: 'e3',
          cycleId: 'c1',
          entryDate: DateTime(2026, 9, 27),
          symptoms: ['bloating'],
        ),
        DailyEntryModel(
          entryId: 'e4',
          cycleId: 'c1',
          entryDate: DateTime(2026, 9, 28),
          symptoms: [],
        ),
      ];

      final result = CycleAnalyticsEngine.calculate(cycles: [], entries: entries);

      expect(result.topSymptoms.isNotEmpty, true);
      // Gejala terbanyak harus 'cramps' (2x dari 4 entri = 50.0%)
      final top = result.topSymptoms.first;
      expect(top.symptomKey, 'cramps');
      expect(top.occurrenceCount, 2);
      expect(top.percentage, 50.0);
      expect(top.label, contains('Dismenore'));
    });

    test('9. Distribusi mood dan rasio keintiman terproteksi vs tanpa pengaman akurat', () {
      final entries = [
        DailyEntryModel(
          entryId: 'e1',
          cycleId: 'c1',
          entryDate: DateTime(2026, 9, 20),
          mood: 'calm',
          hasIntimacy: true,
          usedProtection: true,
        ),
        DailyEntryModel(
          entryId: 'e2',
          cycleId: 'c1',
          entryDate: DateTime(2026, 9, 21),
          mood: 'calm',
          hasIntimacy: true,
          usedProtection: false,
        ),
        DailyEntryModel(
          entryId: 'e3',
          cycleId: 'c1',
          entryDate: DateTime(2026, 9, 22),
          mood: 'tired',
          hasIntimacy: false,
        ),
      ];

      final result = CycleAnalyticsEngine.calculate(cycles: [], entries: entries);

      expect(result.totalIntimacyDays, 2);
      expect(result.protectedIntimacyDays, 1);
      expect(result.unprotectedIntimacyDays, 1);

      expect(result.topMoods.length, 2);
      final topMood = result.topMoods.first;
      expect(topMood.moodKey, 'calm');
      expect(topMood.count, 2);
    });
  });
}
