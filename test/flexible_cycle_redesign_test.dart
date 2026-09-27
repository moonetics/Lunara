import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/database/models/cycle_model.dart';
import 'package:lunara/core/database/models/daily_entry_model.dart';
import 'package:lunara/core/services/cycle_engine.dart';

void main() {
  group('Flexible Cycle Redesign - Model & Adapter Tests', () {
    test('1. CycleModel mendukung endDate dan isUnrecordedGap', () {
      final cycle = CycleModel(
        cycleId: 'c_test_1',
        startDate: DateTime(2026, 4, 28),
        endDate: DateTime(2026, 5, 4),
        periodDurationDays: 7,
        isOngoing: false,
        isUnrecordedGap: true,
      );

      expect(cycle.startDate, DateTime(2026, 4, 28));
      expect(cycle.endDate, DateTime(2026, 5, 4));
      expect(cycle.periodDurationDays, 7);
      expect(cycle.isUnrecordedGap, true);
      expect(cycle.isOngoing, false);

      final adapter = CycleModelAdapter();
      expect(adapter.typeId, 1);
    });

    test('2. DailyEntryModel mendukung hasIntimacy dan usedProtection', () {
      final entryNone = DailyEntryModel(
        entryId: 'd1',
        cycleId: 'c1',
        entryDate: DateTime(2026, 7, 10),
      );
      expect(entryNone.hasIntimacy, false);
      expect(entryNone.usedProtection, isNull);

      final entryProtected = DailyEntryModel(
        entryId: 'd2',
        cycleId: 'c1',
        entryDate: DateTime(2026, 7, 20),
        hasIntimacy: true,
        usedProtection: true,
      );
      expect(entryProtected.hasIntimacy, true);
      expect(entryProtected.usedProtection, true);

      final entryUnprotected = DailyEntryModel(
        entryId: 'd3',
        cycleId: 'c1',
        entryDate: DateTime(2026, 7, 22),
        hasIntimacy: true,
        usedProtection: false,
      );
      expect(entryUnprotected.hasIntimacy, true);
      expect(entryUnprotected.usedProtection, false);

      final adapter = DailyEntryModelAdapter();
      expect(adapter.typeId, 2);
    });
  });

  group('Flexible Cycle Redesign - Cross-Month Period Calculations', () {
    test('3. Menghitung durasi haid lintas bulan (28 April - 4 Mei = 7 hari)', () {
      final start = DateTime(2026, 4, 28);
      final end = DateTime(2026, 5, 4);

      final duration = end.difference(start).inDays + 1;
      expect(duration, 7);

      // Verifikasi penentuan apakah suatu tanggal berada dalam rentang haid lintas bulan
      final datesInPeriod = [
        DateTime(2026, 4, 28),
        DateTime(2026, 4, 29),
        DateTime(2026, 4, 30),
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 2),
        DateTime(2026, 5, 3),
        DateTime(2026, 5, 4),
      ];

      for (final date in datesInPeriod) {
        final isInRange = !date.isBefore(start) && !date.isAfter(end);
        expect(isInRange, true, reason: 'Tanggal $date harus masuk dalam rentang haid');
      }

      final dateBefore = DateTime(2026, 4, 27);
      final dateAfter = DateTime(2026, 5, 5);
      expect(!dateBefore.isBefore(start) && !dateBefore.isAfter(end), false);
      expect(!dateAfter.isBefore(start) && !dateAfter.isAfter(end), false);
    });

    test('4. Siklus baru tanpa input awal (clean slate) default 28 hari', () {
      final avg = CycleEngine.calculateAverageCycleLength([]);
      expect(avg, 28.0);
    });

    test('5. Reset bersih menghapus keterlambatan tanpa merusak kalkulasi siklus', () {
      final now = DateTime(2026, 6, 1);
      final cycles = [
        CycleModel(
          cycleId: 'c_reset',
          startDate: DateTime(2026, 6, 1),
          cycleLengthDays: 28,
          periodDurationDays: 5,
          isOngoing: true,
        ),
      ];

      final nextPeriod = CycleEngine.calculateNextPeriodDate(cycles.first.startDate, 28);
      expect(nextPeriod, DateTime(2026, 6, 29));

      final delayDays = CycleEngine.calculateDelayDays(nextPeriod, now);
      expect(delayDays, 0);
    });

    test('6. isDateInFertileWindow mendeteksi jendela ovulasi secara presisi', () {
      final lastPeriod = DateTime(2026, 10, 1);
      const cycleLength = 28;
      // Ovulasi hari ke-14 = 14 Oktober
      // Jendela subur (H-5 s/d H+1) = 9 Oktober s/d 15 Oktober

      expect(CycleEngine.isDateInFertileWindow(DateTime(2026, 10, 14), lastPeriod, cycleLength), true);
      expect(CycleEngine.isDateInFertileWindow(DateTime(2026, 10, 9), lastPeriod, cycleLength), true);
      expect(CycleEngine.isDateInFertileWindow(DateTime(2026, 10, 15), lastPeriod, cycleLength), true);

      // Di luar jendela subur
      expect(CycleEngine.isDateInFertileWindow(DateTime(2026, 10, 5), lastPeriod, cycleLength), false);
      expect(CycleEngine.isDateInFertileWindow(DateTime(2026, 10, 20), lastPeriod, cycleLength), false);
    });

    test('7. getIntimacyConceptionAnalysis memberikan analisis proteksi dan peluang kehamilan yang tepat', () {
      final lastPeriod = DateTime(2026, 10, 1);
      const cycleLength = 28;

      // Seks tanpa pengaman di masa subur (14 Oktober)
      final analysisUnprotectedFertile = CycleEngine.getIntimacyConceptionAnalysis(
        intimacyDate: DateTime(2026, 10, 14),
        lastPeriodStartDate: lastPeriod,
        cycleLength: cycleLength,
        hasProtection: false,
      );
      expect(analysisUnprotectedFertile.isHighConceptionRisk, true);
      expect(analysisUnprotectedFertile.statusLabel, 'Peluang Konsepsi Tinggi');

      // Seks dengan pengaman di masa subur (14 Oktober)
      final analysisProtectedFertile = CycleEngine.getIntimacyConceptionAnalysis(
        intimacyDate: DateTime(2026, 10, 14),
        lastPeriodStartDate: lastPeriod,
        cycleLength: cycleLength,
        hasProtection: true,
      );
      expect(analysisProtectedFertile.isHighConceptionRisk, false);
      expect(analysisProtectedFertile.statusLabel, 'Masa Subur (Terproteksi)');

      // Seks di luar masa subur (22 Oktober)
      final analysisOutsideFertile = CycleEngine.getIntimacyConceptionAnalysis(
        intimacyDate: DateTime(2026, 10, 22),
        lastPeriodStartDate: lastPeriod,
        cycleLength: cycleLength,
        hasProtection: false,
      );
      expect(analysisOutsideFertile.isHighConceptionRisk, false);
      expect(analysisOutsideFertile.statusLabel, contains('Di Luar Masa Subur'));
    });

    test('8. Analisis konsepsi retroaktif mencocokkan siklus yang tepat untuk tanggal intimasi lampau', () {
      // Siklus 1: Mulai 19 Agustus 2026, siklus 28 hari -> Ovulasi ~ 2 September (jendela subur 28 Ags - 3 Sep)
      final augustCycle = CycleModel(
        cycleId: 'c_aug',
        startDate: DateTime(2026, 8, 19),
        endDate: DateTime(2026, 8, 23),
        periodDurationDays: 5,
        cycleLengthDays: 28,
        isOngoing: false,
      );
      // Siklus 2: Mulai 26 September 2026 (aktif)
      final septCycle = CycleModel(
        cycleId: 'c_sept',
        startDate: DateTime(2026, 9, 26),
        periodDurationDays: 1,
        cycleLengthDays: 28,
        isOngoing: true,
      );

      final cycles = [septCycle, augustCycle]; // Terurut terbaru ke terlama
      final intimacyDate = DateTime(2026, 9, 1);

      // Algoritma pencari siklus retroaktif
      final sorted = List<CycleModel>.from(cycles)..sort((a, b) => a.startDate.compareTo(b.startDate));
      CycleModel? matched;
      for (final c in sorted) {
        if (!c.startDate.isAfter(intimacyDate)) {
          matched = c;
        } else {
          break;
        }
      }

      expect(matched, isNotNull);
      expect(matched!.cycleId, 'c_aug');

      final analysis = CycleEngine.getIntimacyConceptionAnalysis(
        intimacyDate: intimacyDate,
        lastPeriodStartDate: matched.startDate,
        cycleLength: matched.cycleLengthDays,
        hasProtection: false,
      );

      // Tanggal 1 September berada di jendela subur siklus Agustus
      expect(analysis.isHighConceptionRisk, true);
      expect(analysis.statusLabel, 'Peluang Konsepsi Tinggi');
    });

    test('9. Siklus haid berjalan (ongoing) mempertahankan status menstruasi pada hari ke-2', () {
      final activeCycle = CycleModel(
        cycleId: 'c_active',
        startDate: DateTime(2026, 9, 26),
        periodDurationDays: 1,
        isOngoing: true,
      );

      // Hari ke-2 haid (27 September)
      final day2 = DateTime(2026, 9, 27);
      final diff = day2.difference(activeCycle.startDate).inDays; // 1

      // Proyeksi durasi normal 5 hari selama siklus ongoing
      final effectivePeriodDuration = (activeCycle.isOngoing || activeCycle.endDate == null)
          ? (activeCycle.periodDurationDays > 1 ? activeCycle.periodDurationDays : 5)
          : activeCycle.periodDurationDays;

      expect(diff < effectivePeriodDuration, true); // Masih dalam fase haid (pink), belum folikular!
    });

    test('10. Hapus catatan harian: simulasi deleteDailyEntryForDate & pembersihan log', () {
      final entries = <String, DailyEntryModel>{};
      final date1 = DateTime(2026, 9, 27);
      final date2 = DateTime(2026, 9, 28);

      final entry1 = DailyEntryModel(
        entryId: 'd_test_1',
        cycleId: 'c1',
        entryDate: date1,
        flowIntensity: 'spotting',
        mood: 'happy',
        symptoms: ['cramps', 'bloating'],
        hasIntimacy: true,
        usedProtection: true,
      );

      final entry2 = DailyEntryModel(
        entryId: 'd_test_2',
        cycleId: 'c1',
        entryDate: date2,
        flowIntensity: 'medium',
        mood: 'calm',
        symptoms: [],
        hasIntimacy: false,
      );

      entries[entry1.entryId] = entry1;
      entries[entry2.entryId] = entry2;

      expect(entries.length, 2);

      // Simulasi deleteDailyEntryForDate
      final targetDate = DateTime(2026, 9, 27);
      DailyEntryModel? foundEntry;
      for (final e in entries.values) {
        if (e.entryDate.year == targetDate.year &&
            e.entryDate.month == targetDate.month &&
            e.entryDate.day == targetDate.day) {
          foundEntry = e;
          break;
        }
      }

      expect(foundEntry, isNotNull);
      entries.remove(foundEntry!.entryId);

      expect(entries.length, 1);
      expect(entries.containsKey('d_test_1'), false);
      expect(entries.containsKey('d_test_2'), true);
    });

    test('11. Rich Activity Card: Mood dan flek tetap tampil meskipun keintiman bernilai true atau false', () {
      final richEntry = DailyEntryModel(
        entryId: 'd_rich',
        cycleId: 'c1',
        entryDate: DateTime(2026, 9, 27),
        flowIntensity: 'spotting',
        mood: 'happy',
        symptoms: ['headache', 'fatigue'],
        hasIntimacy: true,
        usedProtection: false,
      );

      // Verifikasi data untuk tag mini di UI
      final hasFlow = richEntry.flowIntensity.isNotEmpty && richEntry.flowIntensity != 'none';
      final hasMood = richEntry.mood.isNotEmpty;
      final hasSymptoms = richEntry.symptoms.isNotEmpty;

      expect(hasFlow, true);
      expect(hasMood, true);
      expect(hasSymptoms, true);
      expect(richEntry.hasIntimacy, true);
      expect(richEntry.usedProtection, false);
    });
  });
}

