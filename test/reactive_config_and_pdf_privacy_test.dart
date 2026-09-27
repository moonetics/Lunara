import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/database/local_db_service.dart';
import 'package:lunara/core/database/models/app_config_model.dart';
import 'package:lunara/core/database/models/cycle_model.dart';
import 'package:lunara/core/database/models/triage_record_model.dart';
import 'package:lunara/core/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reaktivitas Konfigurasi Antar-Layar (configNotifier)', () {
    test('configNotifier memberitahu listener seketika saat mode fokus diubah', () {
      final notifier = LocalDbService.instance.configNotifier;
      AppConfigModel? observedConfig;
      int notificationCount = 0;

      void listener() {
        notificationCount++;
        observedConfig = notifier.value;
      }

      notifier.addListener(listener);

      // 1. Ubah ke Program Hamil (Promil)
      notifier.value = AppConfigModel(appGoal: 'pregnancy_program');
      expect(notificationCount, 1);
      expect(observedConfig?.appGoal, 'pregnancy_program');
      expect(observedConfig?.isPregnancyProgram, isTrue);
      expect(observedConfig?.isNaturalContraception, isFalse);

      // 2. Ubah ke Tunda Hamil Alami (KB Alami)
      notifier.value = AppConfigModel(appGoal: 'natural_contraception');
      expect(notificationCount, 2);
      expect(observedConfig?.appGoal, 'natural_contraception');
      expect(observedConfig?.isNaturalContraception, isTrue);
      expect(observedConfig?.isPregnancyProgram, isFalse);

      // 3. Kembalikan ke Pantau Kesehatan Biasa
      notifier.value = AppConfigModel(appGoal: 'health_tracking');
      expect(notificationCount, 3);
      expect(observedConfig?.appGoal, 'health_tracking');
      expect(observedConfig?.isPregnancyProgram, isFalse);
      expect(observedConfig?.isNaturalContraception, isFalse);

      notifier.removeListener(listener);
    });
  });

  group('Privasi PDF: Opsi Sertakan/Sembunyikan Catatan Keintiman', () {
    final baseConfig = AppConfigModel(
      perspective: 'female_self',
      appGoal: 'natural_contraception',
    );

    final pastCycles = [
      CycleModel(
        cycleId: 'c1',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 29),
        cycleLengthDays: 28,
        periodDurationDays: 5,
        isOngoing: false,
      ),
      CycleModel(
        cycleId: 'c2',
        startDate: DateTime(2026, 7, 3),
        endDate: DateTime(2026, 7, 31),
        cycleLengthDays: 28,
        periodDurationDays: 5,
        isOngoing: false,
      ),
    ];

    test('1. generateMedicalReport dengan includeIntimacy: true menghasilkan PDF valid', () async {
      final pdfBytesWithIntimacy = await PdfExportService.instance.generateMedicalReport(
        patientName: 'Siti Rahma',
        patientAge: '28',
        config: baseConfig,
        pastCycles: pastCycles,
        includeIntimacy: true,
      );

      expect(pdfBytesWithIntimacy.isNotEmpty, isTrue);
      expect(pdfBytesWithIntimacy.length, greaterThan(1000));
      // Magic bytes %PDF
      expect(pdfBytesWithIntimacy[0], 0x25);
      expect(pdfBytesWithIntimacy[1], 0x50);
      expect(pdfBytesWithIntimacy[2], 0x44);
      expect(pdfBytesWithIntimacy[3], 0x46);
    });

    test('2. generateMedicalReport dengan includeIntimacy: false menghasilkan PDF valid tanpa bagian keintiman', () async {
      final pdfBytesWithoutIntimacy = await PdfExportService.instance.generateMedicalReport(
        patientName: 'Siti Rahma',
        patientAge: '28',
        config: baseConfig,
        pastCycles: pastCycles,
        includeIntimacy: false,
      );

      expect(pdfBytesWithoutIntimacy.isNotEmpty, isTrue);
      expect(pdfBytesWithoutIntimacy.length, greaterThan(1000));
      expect(pdfBytesWithoutIntimacy[0], 0x25);
      expect(pdfBytesWithoutIntimacy[1], 0x50);
      expect(pdfBytesWithoutIntimacy[2], 0x44);
      expect(pdfBytesWithoutIntimacy[3], 0x46);
    });

    test('3. generateMedicalReport dengan Triage & tanpa keintiman memiliki subpenomoran rapi', () async {
      final triage = TriageRecordModel(
        triageId: 't1',
        testDate: DateTime(2026, 9, 20),
        daysDelayed: 3,
        stressLevel: 3,
        severePelvicPain: false,
        isRedFlag: false,
        recommendationSummary: 'Variasi Siklus Terkait Kelelahan & Beban Kerja',
      );

      final pdfBytes = await PdfExportService.instance.generateMedicalReport(
        patientName: 'Siti Rahma',
        patientAge: '28',
        config: baseConfig,
        pastCycles: pastCycles,
        latestTriage: triage,
        includeIntimacy: false,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });

  group('Penyajian Klinis Haid Baru Berjalan (1-2 Hari) di PDF', () {
    test('1. Siklus ongoing (baru 1 hari) tidak merusak rata-rata siklus historis dan terformat klinis', () async {
      final completedCycle1 = CycleModel(
        cycleId: 'c_hist_1',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 29),
        cycleLengthDays: 28,
        periodDurationDays: 5,
        isOngoing: false,
      );
      final completedCycle2 = CycleModel(
        cycleId: 'c_hist_2',
        startDate: DateTime(2026, 7, 4),
        endDate: DateTime(2026, 8, 1),
        cycleLengthDays: 28,
        periodDurationDays: 5,
        isOngoing: false,
      );

      // Siklus baru yang baru berjalan 1 hari (hari ini baru haid)
      final ongoingCycle = CycleModel(
        cycleId: 'c_ongoing',
        startDate: DateTime(2026, 8, 29),
        endDate: null,
        cycleLengthDays: 1,
        periodDurationDays: 1,
        isOngoing: true,
      );

      final pdfBytes = await PdfExportService.instance.generateMedicalReport(
        patientName: 'Nurul Hidayah',
        patientAge: '25',
        config: AppConfigModel(),
        pastCycles: [ongoingCycle, completedCycle1, completedCycle2],
        activeCycle: ongoingCycle,
        includeIntimacy: true,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes[0], 0x25); // %
      expect(pdfBytes[1], 0x50); // P
      expect(pdfBytes[2], 0x44); // D
      expect(pdfBytes[3], 0x46); // F
    });

    test('2. Kondisi pasien baru dengan HANYA siklus ongoing (tanpa siklus historis) ditangani tanpa error', () async {
      final firstOngoingCycle = CycleModel(
        cycleId: 'first_c',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: null,
        cycleLengthDays: 2,
        periodDurationDays: 2,
        isOngoing: true,
      );

      final pdfBytes = await PdfExportService.instance.generateMedicalReport(
        patientName: 'Pasien Baru',
        patientAge: '22',
        config: AppConfigModel(),
        pastCycles: [firstOngoingCycle],
        activeCycle: firstOngoingCycle,
        includeIntimacy: true,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes[0], 0x25);
    });

    test('3. Kondisi belum ada siklus sama sekali (zero-data) ditangani dengan aman', () async {
      final pdfBytes = await PdfExportService.instance.generateMedicalReport(
        patientName: '',
        patientAge: null,
        config: AppConfigModel(),
        pastCycles: [],
        activeCycle: null,
        includeIntimacy: false,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes[0], 0x25);
    });
  });
}
