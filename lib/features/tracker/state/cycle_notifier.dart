import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/database/models/cycle_model.dart';
import '../../../core/services/cycle_engine.dart';
import 'cycle_state.dart';

/// Provider Global untuk Siklus Menstruasi Lunara
final cycleProvider = StateNotifierProvider<CycleNotifier, CycleState>((ref) {
  final notifier = CycleNotifier(LocalDbService.instance);
  notifier.loadCycles();
  return notifier;
});

/// StateNotifier Pengelola Logika Siklus & Data Lokal
class CycleNotifier extends StateNotifier<CycleState> {
  final LocalDbService _db;

  CycleNotifier(this._db) : super(const CycleState());

  /// Memuat seluruh siklus dari Hive dan mengkalkulasi fase harian
  Future<void> loadCycles() async {
    state = state.copyWith(isLoading: true);
    try {
      final cycles = _db.getAllCycles();
      final avgLength = CycleEngine.calculateAverageCycleLength(cycles);
      final active = _db.getActiveCycle();

      DateTime? nextDate;
      int delayDays = 0;
      CyclePhaseInfo? phaseInfo;

      if (active != null) {
        nextDate = CycleEngine.calculateNextPeriodDate(active.startDate, avgLength);
        delayDays = CycleEngine.calculateDelayDays(nextDate);
        phaseInfo = CycleEngine.getCurrentPhase(
          active.startDate,
          avgLength,
          periodDuration: active.periodDurationDays,
        );
      }

      state = state.copyWith(
        allCycles: cycles,
        activeCycle: active,
        averageCycleLength: avgLength,
        nextPeriodDate: nextDate,
        delayDays: delayDays,
        isDelayed: delayDays > 0,
        currentPhaseInfo: phaseInfo,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data siklus: $e',
      );
    }
  }

  /// Mencatat hari pertama haid baru (memulai siklus baru)
  Future<void> recordPeriodStart(
    DateTime startDate, {
    int periodDuration = 5,
  }) async {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final existingCycles = _db.getAllCycles();

    // 1. Jika ada siklus yang sedang berlangsung sebelumnya, tutup siklus tersebut
    for (final oldCycle in existingCycles) {
      if (oldCycle.isOngoing) {
        final lengthDays = normalizedStart.difference(oldCycle.startDate).inDays;
        final isOutlier = CycleEngine.isOutlierGap(oldCycle.startDate, normalizedStart);

        final updatedOld = oldCycle.copyWith(
          isOngoing: false,
          cycleLengthDays: lengthDays > 0 ? lengthDays : oldCycle.cycleLengthDays,
          isOutlier: isOutlier,
        );
        await _db.saveCycle(updatedOld);
      }
    }

    // 2. Buat siklus baru
    final newCycleId = 'cycle_${normalizedStart.millisecondsSinceEpoch}';
    final newCycle = CycleModel(
      cycleId: newCycleId,
      startDate: normalizedStart,
      periodDurationDays: periodDuration,
      isOngoing: true,
      cycleLengthDays: state.averageCycleLength.round(),
    );

    await _db.saveCycle(newCycle);
    await loadCycles();
  }

  /// Mencatat hari terakhir haid (selesai haid)
  Future<void> recordPeriodEnd(DateTime endDate) async {
    final active = state.activeCycle;
    if (active == null) return;

    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final duration = normalizedEnd.difference(active.startDate).inDays + 1;

    final updated = active.copyWith(
      endDate: normalizedEnd,
      periodDurationDays: duration > 0 ? duration : active.periodDurationDays,
    );

    await _db.saveCycle(updated);
    await loadCycles();
  }

  /// Menambahkan riwayat siklus lampau (*Historical Backfill*)
  Future<void> addHistoricalCycle(
    DateTime startDate, {
    DateTime? endDate,
    int? explicitCycleLength,
  }) async {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    DateTime? normalizedEnd;
    if (endDate != null) {
      normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    }

    final periodDuration = normalizedEnd != null
        ? normalizedEnd.difference(normalizedStart).inDays + 1
        : 5;

    final cycleId = 'hist_${normalizedStart.millisecondsSinceEpoch}';
    final cycle = CycleModel(
      cycleId: cycleId,
      startDate: normalizedStart,
      endDate: normalizedEnd,
      periodDurationDays: periodDuration > 0 ? periodDuration : 5,
      cycleLengthDays: explicitCycleLength ?? 28,
      isOngoing: false,
      isOutlier: explicitCycleLength != null &&
          (explicitCycleLength < 21 || explicitCycleLength > 45),
    );

    await _db.saveCycle(cycle);
    await loadCycles();
  }

  /// Menghapus siklus tertentu
  Future<void> deleteCycle(String cycleId) async {
    await _db.deleteCycle(cycleId);
    await loadCycles();
  }

  /// Memulai periode haid baru secara dinamis
  Future<void> startNewPeriod([DateTime? startDate]) async {
    final date = startDate ?? DateTime.now();
    await _db.startNewPeriod(date);
    await loadCycles();
  }

  /// Menyelesaikan periode haid saat darah berhenti
  Future<void> endCurrentPeriod([DateTime? endDate]) async {
    final date = endDate ?? DateTime.now();
    await _db.endCurrentPeriod(date);
    await loadCycles();
  }

  /// Tombol Penyelamat: Reset status siklus jika pengguna sempat haid tapi lupa tanggalnya
  Future<void> resetCycleStatus() async {
    await _db.resetCycleStatus();
    await loadCycles();
  }
}
