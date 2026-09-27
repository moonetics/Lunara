import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/local_db_service.dart';
import '../database/models/app_config_model.dart';
import '../database/models/cycle_model.dart';
import '../database/models/daily_entry_model.dart';
import '../database/models/triage_record_model.dart';

/// Layanan Pencadangan dan Pemulihan Data Offline 100% (JSON) Lunara
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  /// Menghasilkan format JSON lengkap dari seluruh data lokal Hive
  String exportToJson() {
    final db = LocalDbService.instance;
    final config = db.getConfig();
    final cycles = db.getAllCycles();
    final triageRecords = db.getAllTriageRecords();

    // Kumpulkan seluruh daily entries dari semua siklus
    final List<DailyEntryModel> allEntries = [];
    for (final cycle in cycles) {
      allEntries.addAll(db.getEntriesForCycle(cycle.cycleId));
    }

    final Map<String, dynamic> exportData = {
      'app': 'Lunara',
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'data': {
        'config': {
          'perspective': config.perspective,
          'partnerName': config.partnerName,
          'isBiometricEnabled': config.isBiometricEnabled,
          'defaultCycleLength': config.defaultCycleLength,
          'defaultPeriodDuration': config.defaultPeriodDuration,
          'isNotificationsEnabled': config.isNotificationsEnabled,
          'notificationHour': config.notificationHour,
          'notificationMinute': config.notificationMinute,
          'appGoal': config.appGoal,
        },
        'cycles': cycles
            .map((c) => {
                  'cycleId': c.cycleId,
                  'startDate': c.startDate.toIso8601String(),
                  'endDate': c.endDate?.toIso8601String(),
                  'cycleLengthDays': c.cycleLengthDays,
                  'periodDurationDays': c.periodDurationDays,
                  'isOngoing': c.isOngoing,
                  'isOutlier': c.isOutlier,
                  'notes': c.notes,
                })
            .toList(),
        'dailyEntries': allEntries
            .map((e) => {
                  'entryId': e.entryId,
                  'cycleId': e.cycleId,
                  'entryDate': e.entryDate.toIso8601String(),
                  'flowIntensity': e.flowIntensity,
                  'mood': e.mood,
                  'symptoms': e.symptoms,
                  'notes': e.notes,
                })
            .toList(),
        'triageRecords': triageRecords
            .map((t) => {
                  'triageId': t.triageId,
                  'testDate': t.testDate.toIso8601String(),
                  'daysDelayed': t.daysDelayed,
                  'hasPregnancyRisk': t.hasPregnancyRisk,
                  'pregnancyTestTaken': t.pregnancyTestTaken,
                  'pregnancyTestResult': t.pregnancyTestResult,
                  'stressLevel': t.stressLevel,
                  'drasticDietOrWeightChange': t.drasticDietOrWeightChange,
                  'intenseExercise': t.intenseExercise,
                  'emergencyContraceptive': t.emergencyContraceptive,
                  'severePelvicPain': t.severePelvicPain,
                  'probableFactors': t.probableFactors,
                  'recommendationSummary': t.recommendationSummary,
                  'primaryCitation': t.primaryCitation,
                  'isRedFlag': t.isRedFlag,
                })
            .toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Mengekspor dan membagikan berkas .json melalui Share Sheet sistem
  Future<void> shareBackupFile() async {
    final jsonString = exportToJson();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'lunara_cadangan_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Berkas Cadangan Rekam Siklus Lunara (Offline JSON)',
        subject: 'Cadangan Data Lunara',
      ),
    );
  }

  /// Memulihkan data dari string JSON ke dalam Hive database
  Future<bool> importFromJson(String jsonContent) async {
    try {
      final dynamic decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic> || decoded['app'] != 'Lunara') {
        debugPrint('[BackupService] Format berkas JSON tidak valid atau bukan dari Lunara.');
        return false;
      }

      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      final db = LocalDbService.instance;

      // 1. Pulihkan Konfigurasi
      final configMap = data['config'] as Map<String, dynamic>?;
      if (configMap != null) {
        final restoredConfig = AppConfigModel(
          perspective: configMap['perspective'] as String? ?? 'female_self',
          partnerName: configMap['partnerName'] as String? ?? 'Pasangan',
          isBiometricEnabled: configMap['isBiometricEnabled'] as bool? ?? false,
          defaultCycleLength: configMap['defaultCycleLength'] as int? ?? 28,
          defaultPeriodDuration: configMap['defaultPeriodDuration'] as int? ?? 5,
          isNotificationsEnabled: configMap['isNotificationsEnabled'] as bool? ?? true,
          notificationHour: configMap['notificationHour'] as int? ?? 9,
          notificationMinute: configMap['notificationMinute'] as int? ?? 0,
          appGoal: configMap['appGoal'] as String? ?? 'health_tracking',
        );
        await db.saveConfig(restoredConfig);
      }

      // 2. Pulihkan Siklus
      final cyclesList = data['cycles'] as List<dynamic>? ?? [];
      for (final item in cyclesList) {
        if (item is Map<String, dynamic>) {
          final cycle = CycleModel(
            cycleId: item['cycleId'] as String,
            startDate: DateTime.parse(item['startDate'] as String),
            endDate: item['endDate'] != null ? DateTime.parse(item['endDate'] as String) : null,
            cycleLengthDays: item['cycleLengthDays'] as int? ?? 28,
            periodDurationDays: item['periodDurationDays'] as int? ?? 5,
            isOngoing: item['isOngoing'] as bool? ?? false,
            isOutlier: item['isOutlier'] as bool? ?? false,
            notes: item['notes'] as String?,
          );
          await db.saveCycle(cycle);
        }
      }

      // 3. Pulihkan Catatan Harian
      final entriesList = data['dailyEntries'] as List<dynamic>? ?? [];
      for (final item in entriesList) {
        if (item is Map<String, dynamic>) {
          final entry = DailyEntryModel(
            entryId: item['entryId'] as String,
            cycleId: item['cycleId'] as String,
            entryDate: DateTime.parse(item['entryDate'] as String),
            flowIntensity: item['flowIntensity'] as String? ?? 'sedang',
            mood: item['mood'] as String? ?? 'biasa',
            symptoms: (item['symptoms'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
            notes: item['notes'] as String?,
          );
          await db.saveDailyEntry(entry);
        }
      }

      // 4. Pulihkan Catatan Triage
      final triageList = data['triageRecords'] as List<dynamic>? ?? [];
      for (final item in triageList) {
        if (item is Map<String, dynamic>) {
          final record = TriageRecordModel(
            triageId: item['triageId'] as String,
            testDate: DateTime.parse(item['testDate'] as String),
            daysDelayed: item['daysDelayed'] as int? ?? 0,
            hasPregnancyRisk: item['hasPregnancyRisk'] as bool? ?? false,
            pregnancyTestTaken: item['pregnancyTestTaken'] as bool? ?? false,
            pregnancyTestResult: item['pregnancyTestResult'] as String? ?? 'not_tested',
            stressLevel: item['stressLevel'] as int? ?? 1,
            drasticDietOrWeightChange: item['drasticDietOrWeightChange'] as bool? ?? false,
            intenseExercise: item['intenseExercise'] as bool? ?? false,
            emergencyContraceptive: item['emergencyContraceptive'] as bool? ?? false,
            severePelvicPain: item['severePelvicPain'] as bool? ?? false,
            probableFactors: (item['probableFactors'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
            recommendationSummary: item['recommendationSummary'] as String? ?? '',
            primaryCitation: item['primaryCitation'] as String? ?? '',
            isRedFlag: item['isRedFlag'] as bool? ?? false,
          );
          await db.saveTriageRecord(record);
        }
      }

      debugPrint('[BackupService] Pemulihan data cadangan berhasil diproses');
      return true;
    } catch (e) {
      debugPrint('[BackupService] Gagal memulihkan cadangan: $e');
      return false;
    }
  }

  /// Membuka file picker perangkat untuk memilih file cadangan .json
  Future<bool> pickAndRestoreBackup() async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isNotEmpty) {
        final path = files.first.path;
        if (path != null) {
          final file = File(path);
          final content = await file.readAsString();
          return await importFromJson(content);
        }
      }
      return false;
    } catch (e) {
      debugPrint('[BackupService] Error memilih berkas: $e');
      return false;
    }
  }
}
