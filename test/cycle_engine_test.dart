import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/database/models/cycle_model.dart';
import 'package:lunara/core/services/cycle_engine.dart';

void main() {
  group('CycleEngine - Smart Gap Handling & Average Calculation', () {
    test('1. Baseline default: pengguna baru tanpa data mengembalikan 28.0 hari', () {
      final avg = CycleEngine.calculateAverageCycleLength([]);
      expect(avg, 28.0);
    });

    test('2. Siklus normal teratur: menghitung rata-rata dari siklus fisiologis (27, 28, 29 hari)', () {
      final cycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 1, 1),
          cycleLengthDays: 28,
        ),
        CycleModel(
          cycleId: 'c2',
          startDate: DateTime(2026, 1, 29),
          cycleLengthDays: 29,
        ),
        CycleModel(
          cycleId: 'c3',
          startDate: DateTime(2026, 2, 27),
          cycleLengthDays: 27,
        ),
      ];

      final avg = CycleEngine.calculateAverageCycleLength(cycles);
      // (28 + 29 + 27) / 3 = 28.0
      expect(avg, 28.0);
    });

    test('3. Smart Gap Handling: jeda bolong > 45 hari (Februari terlewat) otomatis disaring', () {
      // Skenario Nyata:
      // - Siklus 1: 1 Jan (28 hari)
      // - Februari LUPA DICATAT (Jeda 61 hari ke Maret!)
      // - Siklus 2: 3 Maret (61 hari) -> Outlier!
      // - Siklus 3: 31 Maret (28 hari)
      final cycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 1, 1),
          cycleLengthDays: 28,
          isOutlier: false,
        ),
        CycleModel(
          cycleId: 'c2_missing_gap',
          startDate: DateTime(2026, 3, 3),
          cycleLengthDays: 61, // Jeda > 45 hari akibat lupa catat
          isOutlier: true,
        ),
        CycleModel(
          cycleId: 'c3',
          startDate: DateTime(2026, 3, 31),
          cycleLengthDays: 28,
          isOutlier: false,
        ),
      ];

      final avg = CycleEngine.calculateAverageCycleLength(cycles);
      // Nilai 61 hari WAJIB disaring!
      // Rata-rata harus tetap (28 + 28) / 2 = 28.0, BUKAN (28 + 61 + 28) / 3 = 39.0!
      expect(avg, 28.0);
    });

    test('4. Deteksi otomatis jeda outlier menggunakan isOutlierGap', () {
      final dateJan = DateTime(2026, 1, 1);
      final dateFeb = DateTime(2026, 1, 29); // 28 hari -> Normal
      final dateMar = DateTime(2026, 3, 3);  // 61 hari dari Jan -> Outlier

      expect(CycleEngine.isOutlierGap(dateJan, dateFeb), isFalse);
      expect(CycleEngine.isOutlierGap(dateJan, dateMar), isTrue);
    });
  });

  group('CycleEngine - 4 Fase Fisiologis (Guyton & Hall)', () {
    final cycleStart = DateTime(2026, 1, 1);
    const avgLength = 28.0;
    const duration = 5;

    test('Fase Menstruasi: Hari ke-3 dalam siklus', () {
      final testDate = DateTime(2026, 1, 3);
      final phaseInfo = CycleEngine.getCurrentPhase(
        cycleStart,
        avgLength,
        periodDuration: duration,
        referenceDate: testDate,
      );

      expect(phaseInfo.phase, CyclePhase.menstrual);
      expect(phaseInfo.dayOfCycle, 3);
      expect(phaseInfo.phaseTitle, 'Fase Menstruasi');
      expect(phaseInfo.isLate, isFalse);
    });

    test('Fase Folikular: Hari ke-9 dalam siklus', () {
      final testDate = DateTime(2026, 1, 9);
      final phaseInfo = CycleEngine.getCurrentPhase(
        cycleStart,
        avgLength,
        periodDuration: duration,
        referenceDate: testDate,
      );

      expect(phaseInfo.phase, CyclePhase.follicular);
      expect(phaseInfo.dayOfCycle, 9);
      expect(phaseInfo.phaseTitle, 'Fase Folikular');
      expect(phaseInfo.isLate, isFalse);
    });

    test('Fase Ovulasi: Hari ke-14 dalam siklus (Puncak Masa Subur)', () {
      final testDate = DateTime(2026, 1, 14);
      final phaseInfo = CycleEngine.getCurrentPhase(
        cycleStart,
        avgLength,
        periodDuration: duration,
        referenceDate: testDate,
      );

      expect(phaseInfo.phase, CyclePhase.ovulation);
      expect(phaseInfo.dayOfCycle, 14);
      expect(phaseInfo.phaseTitle, 'Fase Ovulasi');
      expect(phaseInfo.isLate, isFalse);
    });

    test('Fase Luteal / PMS: Hari ke-22 dalam siklus', () {
      final testDate = DateTime(2026, 1, 22);
      final phaseInfo = CycleEngine.getCurrentPhase(
        cycleStart,
        avgLength,
        periodDuration: duration,
        referenceDate: testDate,
      );

      expect(phaseInfo.phase, CyclePhase.luteal);
      expect(phaseInfo.dayOfCycle, 22);
      expect(phaseInfo.phaseTitle, contains('Luteal'));
      expect(phaseInfo.isLate, isFalse);
    });

    test('Kondisi Terlambat: Hari ke-32 (melewati 28 hari sebanyak 4 hari)', () {
      final testDate = DateTime(2026, 2, 2); // 32 hari dari 1 Jan
      final phaseInfo = CycleEngine.getCurrentPhase(
        cycleStart,
        avgLength,
        periodDuration: duration,
        referenceDate: testDate,
      );

      expect(phaseInfo.isLate, isTrue);
      expect(phaseInfo.phaseTitle, contains('Terlambat'));
    });
  });

  group('CycleEngine - Estimasi Tanggal & Keterlambatan', () {
    test('calculateNextPeriodDate menghitung tanggal berikutnya tepat sesuai panjang siklus', () {
      final start = DateTime(2026, 1, 1);
      final next = CycleEngine.calculateNextPeriodDate(start, 28.0);
      expect(next, DateTime(2026, 1, 29));
    });

    test('calculateDelayDays mengembalikan 0 jika belum melewati tanggal estimasi', () {
      final expected = DateTime(2026, 1, 29);
      final today = DateTime(2026, 1, 25);
      final delay = CycleEngine.calculateDelayDays(expected, today);
      expect(delay, 0);
    });

    test('calculateDelayDays mengembalikan jumlah hari keterlambatan jika telah lewat', () {
      final expected = DateTime(2026, 1, 29);
      final today = DateTime(2026, 2, 2); // Telat 4 hari
      final delay = CycleEngine.calculateDelayDays(expected, today);
      expect(delay, 4);
    });
  });
}
