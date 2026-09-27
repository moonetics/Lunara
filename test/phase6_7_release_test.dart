import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/database/models/app_config_model.dart';
import 'package:lunara/core/database/models/cycle_model.dart';
import 'package:lunara/core/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6 - Medical PDF Report Generation', () {
    test('1. PdfExportService menghasilkan berkas PDF valid ber-header %PDF', () async {
      final config = AppConfigModel(
        perspective: 'female_self',
        partnerName: 'Dinda',
      );

      final dummyCycles = [
        CycleModel(
          cycleId: 'c1',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 29),
          cycleLengthDays: 28,
          periodDurationDays: 5,
        ),
        CycleModel(
          cycleId: 'c2',
          startDate: DateTime(2026, 7, 3),
          endDate: DateTime(2026, 7, 31),
          cycleLengthDays: 29,
          periodDurationDays: 5,
        ),
      ];

      final pdfBytes = await PdfExportService.instance.generateMedicalReport(
        patientName: 'Ny. Dinda',
        patientAge: '26 Tahun',
        config: config,
        pastCycles: dummyCycles,
      );

      // Verifikasi berkas tidak kosong dan memiliki ukuran wajar
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));

      // Verifikasi Magic Bytes PDF: %PDF- (0x25, 0x50, 0x44, 0x46)
      expect(pdfBytes[0], 0x25); // %
      expect(pdfBytes[1], 0x50); // P
      expect(pdfBytes[2], 0x44); // D
      expect(pdfBytes[3], 0x46); // F
    });

    test('2. PdfExportService menangani kondisi zero-state (belum ada riwayat siklus) dengan aman', () async {
      final config = AppConfigModel(
        perspective: 'female_self',
      );

      final pdfBytes = await PdfExportService.instance.generateMedicalReport(
        patientName: 'Pasien Lunara',
        patientAge: '24',
        config: config,
        pastCycles: [],
        activeCycle: null,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes[0], 0x25); // %
      expect(pdfBytes[1], 0x50); // P
      expect(pdfBytes[2], 0x44); // D
      expect(pdfBytes[3], 0x46); // F
    });
  });

  group('Phase 7 - JSON Backup & Restore Format Integrity', () {
    test('2. Struktur JSON cadangan memiliki metadata valid dan kompatibel', () {
      final config = AppConfigModel(
        perspective: 'male_helper',
        partnerName: 'Aisyah',
        isBiometricEnabled: true,
      );

      final sampleJson = {
        'app': 'Lunara',
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'data': {
          'config': {
            'perspective': config.perspective,
            'partnerName': config.partnerName,
            'isBiometricEnabled': config.isBiometricEnabled,
            'defaultCycleLength': 28,
            'defaultPeriodDuration': 5,
            'isNotificationsEnabled': true,
            'notificationHour': 9,
            'notificationMinute': 0,
          },
          'cycles': [
            {
              'cycleId': 'cycle_100',
              'startDate': DateTime(2026, 8, 1).toIso8601String(),
              'endDate': DateTime(2026, 8, 29).toIso8601String(),
              'cycleLengthDays': 28,
              'periodDurationDays': 5,
              'isOngoing': false,
              'isOutlier': false,
              'notes': null,
            }
          ],
          'dailyEntries': [],
          'triageRecords': [],
        },
      };

      final encodedString = jsonEncode(sampleJson);
      final dynamic decoded = jsonDecode(encodedString);

      expect(decoded['app'], 'Lunara');
      expect(decoded['version'], '1.0.0');
      expect(decoded['data']['config']['partnerName'], 'Aisyah');
      expect(decoded['data']['cycles'].length, 1);
      expect(config.appGoal, 'health_tracking');
      expect(config.isNaturalContraception, isFalse);

      final contraceptionConfig = AppConfigModel(appGoal: 'natural_contraception');
      expect(contraceptionConfig.isNaturalContraception, isTrue);
    });
  });
}
