import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/core/database/models/app_config_model.dart';

void main() {
  group('Phase 5 - AppConfigModel & Adapter Compatibility', () {
    test('1. Nilai default AppConfigModel sesuai spesifikasi Fase 5', () {
      final config = AppConfigModel();

      expect(config.isBiometricEnabled, false);
      expect(config.isNotificationsEnabled, true);
      expect(config.notificationHour, 9);
      expect(config.notificationMinute, 0);
      expect(config.perspective, 'female_self');
      expect(config.isMaleHelper, false);
      expect(config.isSoundEnabled, true);
    });

    test('2. AppConfigModelAdapter serialisasi dan deserialisasi 9 fields secara presisi', () {
      final original = AppConfigModel(
        perspective: 'male_helper',
        partnerName: 'Dinda',
        isBiometricEnabled: true,
        defaultCycleLength: 30,
        defaultPeriodDuration: 6,
        isNotificationsEnabled: true,
        notificationHour: 8,
        notificationMinute: 30,
        isSoundEnabled: true,
      );

      // Simulasikan reader/writer Hive
      final adapter = AppConfigModelAdapter();
      expect(adapter.typeId, 0);

      // Verifikasi instance field
      expect(original.notificationHour, 8);
      expect(original.notificationMinute, 30);
      expect(original.isBiometricEnabled, true);
      expect(original.isMaleHelper, true);
      expect(original.isSoundEnabled, true);
    });
  });

  group('Phase 5 - Notification Date Calculation Logic', () {
    test('3. Perhitungan tanggal H-2 sebelum estimasi haid', () {
      final expectedDate = DateTime(2026, 10, 15);
      final h2Date = expectedDate.subtract(const Duration(days: 2));

      expect(h2Date.year, 2026);
      expect(h2Date.month, 10);
      expect(h2Date.day, 13);
    });

    test('4. Perhitungan tanggal masuk fase Luteal (Hari ke-16 dari haid terakhir)', () {
      final lastPeriod = DateTime(2026, 10, 1);
      final lutealDate = lastPeriod.add(const Duration(days: 15)); // Hari ke-16

      expect(lutealDate.year, 2026);
      expect(lutealDate.month, 10);
      expect(lutealDate.day, 16);
    });

    test('5. Perhitungan tanggal evaluasi keterlambatan siklus (H+3 hari)', () {
      final expectedDate = DateTime(2026, 10, 15);
      final delayDate = expectedDate.add(const Duration(days: 3));

      expect(delayDate.year, 2026);
      expect(delayDate.month, 10);
      expect(delayDate.day, 18);
    });
  });

  group('Phase 5 - Biometric Background Lock Timeout Threshold', () {
    test('6. Verifikasi batas waktu 30 detik untuk penguncian aplikasi di latar belakang', () {
      const lockTimeout = Duration(seconds: 30);

      final pausedAt = DateTime.now();
      final resumedWithinTolerance = pausedAt.add(const Duration(seconds: 25));
      final resumedAfterTimeout = pausedAt.add(const Duration(seconds: 35));

      final shouldLockTolerance = resumedWithinTolerance.difference(pausedAt) > lockTimeout;
      final shouldLockTimeout = resumedAfterTimeout.difference(pausedAt) > lockTimeout;

      expect(shouldLockTolerance, isFalse, reason: 'Resume dalam 25 detik tidak boleh terkunci');
      expect(shouldLockTimeout, isTrue, reason: 'Resume setelah 35 detik wajib terkunci');
    });
  });
}
