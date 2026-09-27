import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/app_config_model.dart';
import 'models/cycle_model.dart';
import 'models/daily_entry_model.dart';
import 'models/triage_record_model.dart';

/// Layanan Database Lokal 100% Offline (Hive) Lunara
class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  static const String appConfigBoxName = 'lunara_app_config_box';
  static const String cyclesBoxName = 'lunara_cycles_box';
  static const String dailyEntriesBoxName = 'lunara_daily_entries_box';
  static const String triageBoxName = 'lunara_triage_box';

  late Box<AppConfigModel> _appConfigBox;
  late Box<CycleModel> _cyclesBox;
  late Box<DailyEntryModel> _dailyEntriesBox;
  late Box<TriageRecordModel> _triageBox;

  /// Notifier reaktif agar seluruh layar UI (Kalender, Beranda, Pengaturan)
  /// dapat langsung memperbarui tampilan seketika saat konfigurasi diubah.
  final ValueNotifier<AppConfigModel> configNotifier =
      ValueNotifier<AppConfigModel>(AppConfigModel());

  /// Inisialisasi Hive, registrasi adapter, dan buka semua box
  Future<void> init() async {
    await Hive.initFlutter();

    // Registrasi TypeAdapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppConfigModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CycleModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DailyEntryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TriageRecordModelAdapter());
    }

    // Buka box
    _appConfigBox = await Hive.openBox<AppConfigModel>(appConfigBoxName);
    _cyclesBox = await Hive.openBox<CycleModel>(cyclesBoxName);
    _dailyEntriesBox = await Hive.openBox<DailyEntryModel>(dailyEntriesBoxName);
    _triageBox = await Hive.openBox<TriageRecordModel>(triageBoxName);

    // Inisialisasi konfigurasi awal jika belum ada
    if (_appConfigBox.isEmpty) {
      await _appConfigBox.put('config', AppConfigModel());
      debugPrint('[Lunara DB] Default AppConfig initialized');
    }

    // Set nilai awal notifier dari database
    configNotifier.value = getConfig();

    debugPrint('[Lunara DB] All Hive boxes initialized successfully');
  }

  // ==================== APP CONFIG ====================
  AppConfigModel getConfig() {
    return _appConfigBox.get('config') ?? AppConfigModel();
  }

  Future<void> saveConfig(AppConfigModel config) async {
    await _appConfigBox.put('config', config);
    configNotifier.value = config;
  }

  bool get isFirstTimeUser => _cyclesBox.isEmpty;

  // ==================== CYCLES ====================
  List<CycleModel> getAllCycles() {
    final list = _cyclesBox.values.toList();
    // Urutkan dari siklus paling baru ke paling lama
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  CycleModel? getActiveCycle() {
    try {
      return _cyclesBox.values.firstWhere((c) => c.isOngoing);
    } catch (_) {
      // Jika tidak ada yang ditandai ongoing, ambil siklus terbaru
      final cycles = getAllCycles();
      return cycles.isNotEmpty ? cycles.first : null;
    }
  }

  /// Mengecek apakah pengguna sedang dalam status menstruasi aktif hari ini
  bool isCurrentlyBleeding() {
    final active = getActiveCycle();
    if (active == null) return false;
    return active.isOngoing;
  }

  Future<void> saveCycle(CycleModel cycle) async {
    await _cyclesBox.put(cycle.cycleId, cycle);
  }

  Future<void> deleteCycle(String cycleId) async {
    await _cyclesBox.delete(cycleId);
  }

  /// Memulai periode menstruasi baru saat darah keluar
  Future<CycleModel> startNewPeriod(DateTime startDate) async {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final allCycles = getAllCycles();

    // Tutup siklus yang sebelumnya masih ongoing jika ada
    for (final c in allCycles) {
      if (c.isOngoing) {
        c.isOngoing = false;
        c.endDate ??= normalizedStart.subtract(const Duration(days: 1));
        await saveCycle(c);
      }
    }

    // Jika ada siklus sebelumnya, perbarui panjang siklus sebelumnya
    if (allCycles.isNotEmpty) {
      final prev = allCycles.first;
      final gapDays = normalizedStart.difference(prev.startDate).inDays;
      if (gapDays > 0) {
        prev.cycleLengthDays = gapDays;
        if (gapDays > 45) {
          prev.isOutlier = true;
        }
        await saveCycle(prev);
      }
    }

    final newCycle = CycleModel(
      cycleId: 'cycle_${normalizedStart.millisecondsSinceEpoch}',
      startDate: normalizedStart,
      isOngoing: true,
      cycleLengthDays: 28,
      periodDurationDays: 1,
    );

    await saveCycle(newCycle);

    // Catat entri harian hari pertama haid
    final entry = getEntryForDate(normalizedStart) ??
        DailyEntryModel(
          entryId: 'entry_${normalizedStart.millisecondsSinceEpoch}',
          cycleId: newCycle.cycleId,
          entryDate: normalizedStart,
          flowIntensity: 'medium',
          symptoms: ['cramps'],
        );
    entry.flowIntensity = 'medium';
    await saveDailyEntry(entry);

    return newCycle;
  }

  /// Menyelesaikan periode menstruasi saat darah telah berhenti
  Future<CycleModel?> endCurrentPeriod(DateTime endDate) async {
    final active = getActiveCycle();
    if (active == null) return null;

    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final duration = normalizedEnd.difference(active.startDate).inDays + 1;

    active.endDate = normalizedEnd;
    active.periodDurationDays = duration > 0 ? duration : 1;
    active.isOngoing = false;

    await saveCycle(active);
    return active;
  }

  /// Menyimpan data haid masa lalu dengan rentang tanggal bebas (Cross-month friendly)
  Future<CycleModel> addHistoricalCycle(
    DateTime startDate,
    DateTime endDate, {
    String? notes,
  }) async {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final duration = normalizedEnd.difference(normalizedStart).inDays + 1;

    final cycle = CycleModel(
      cycleId: 'cycle_${normalizedStart.millisecondsSinceEpoch}',
      startDate: normalizedStart,
      endDate: normalizedEnd,
      periodDurationDays: duration > 0 ? duration : 1,
      isOngoing: false,
      notes: notes,
    );

    await saveCycle(cycle);

    // Hitung ulang relasi cycle length antar siklus
    final allCycles = getAllCycles();
    for (int i = 0; i < allCycles.length - 1; i++) {
      final current = allCycles[i];
      final older = allCycles[i + 1];
      final length = current.startDate.difference(older.startDate).inDays;
      if (length > 0) {
        older.cycleLengthDays = length;
        if (length > 45) {
          older.isOutlier = true;
        }
        await saveCycle(older);
      }
    }

    return cycle;
  }

  /// Tombol Penyelamat: Reset status siklus jika pengguna sempat haid tapi lupa tanggalnya
  Future<void> resetCycleStatus() async {
    final allCycles = getAllCycles();
    for (final c in allCycles) {
      if (c.isOngoing) {
        c.isOngoing = false;
        await saveCycle(c);
      }
    }

    if (allCycles.isNotEmpty) {
      final latest = allCycles.first;
      latest.isOutlier = true;
      latest.isUnrecordedGap = true;
      await saveCycle(latest);
    }
  }

  // ==================== DAILY ENTRIES ====================
  List<DailyEntryModel> getAllDailyEntries() {
    return _dailyEntriesBox.values.toList()
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));
  }

  List<DailyEntryModel> getEntriesForCycle(String cycleId) {
    return _dailyEntriesBox.values
        .where((entry) => entry.cycleId == cycleId)
        .toList()
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));
  }

  DailyEntryModel? getEntryForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    try {
      return _dailyEntriesBox.values.firstWhere((entry) {
        final d = entry.entryDate;
        return d.year == normalizedDate.year &&
            d.month == normalizedDate.month &&
            d.day == normalizedDate.day;
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDailyEntry(DailyEntryModel entry) async {
    await _dailyEntriesBox.put(entry.entryId, entry);
  }

  /// Menghapus catatan harian berdasarkan entryId
  Future<void> deleteDailyEntry(String entryId) async {
    await _dailyEntriesBox.delete(entryId);
  }

  /// Menghapus catatan harian pada tanggal tertentu
  Future<bool> deleteDailyEntryForDate(DateTime date) async {
    final entry = getEntryForDate(date);
    if (entry != null) {
      await _dailyEntriesBox.delete(entry.entryId);
      return true;
    }
    return false;
  }

  // ==================== TRIAGE RECORDS ====================
  List<TriageRecordModel> getAllTriageRecords() {
    final list = _triageBox.values.toList();
    list.sort((a, b) => b.testDate.compareTo(a.testDate));
    return list;
  }

  Future<void> saveTriageRecord(TriageRecordModel record) async {
    await _triageBox.put(record.triageId, record);
  }

  /// Reset semua data (untuk testing atau pembersihan pengguna)
  Future<void> clearAllData() async {
    await _cyclesBox.clear();
    await _dailyEntriesBox.clear();
    await _triageBox.clear();
    await _appConfigBox.put('config', AppConfigModel());
  }
}
