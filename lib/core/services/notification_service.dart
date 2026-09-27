import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../database/models/app_config_model.dart';
import '../../features/tracker/state/cycle_state.dart';

/// Layanan Notifikasi Lokal 100% Offline Lunara
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String channelId = 'lunara_cycle_reminders';
  static const String channelName = 'Pengingat Siklus Lunara';
  static const String channelDesc = 'Notifikasi offline pengingat siklus menstruasi dan fase reproduksi';

  // Notification IDs
  static const int idPeriodWarning = 101;
  static const int idLutealPhase = 102;
  static const int idLatePeriod = 103;

  /// Inisialisasi plugin notifikasi dan database timezone
  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      debugPrint('[NotificationService] Notifikasi offline native dilewati pada browser Web.');
      return;
    }

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Gunakan fallback default jika zona khusus tidak ditemukan
    }

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('[NotificationService] Notifikasi ditekan: ${response.payload}');
        },
      );

      _isInitialized = true;
      debugPrint('[NotificationService] Inisialisasi notifikasi offline berhasil');
    } catch (e) {
      debugPrint('[NotificationService] Warning: Inisialisasi notifikasi gagal / dilewati: $e');
      _isInitialized = true;
    }
  }

  /// Meminta izin notifikasi runtime (Android 13+ POST_NOTIFICATIONS & macOS/iOS)
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final notifGranted = await android.requestNotificationsPermission();
        await android.requestExactAlarmsPermission();
        return notifGranted ?? false;
      }
      final macOS = _notifications.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macOS != null) {
        final notifGranted = await macOS.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return notifGranted ?? false;
      }
      final iOS = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iOS != null) {
        final notifGranted = await iOS.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return notifGranted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Gagal meminta permission: $e');
      return false;
    }
  }

  /// Membatalkan semua notifikasi pengingat terjadwal
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    await _notifications.cancel(id: idPeriodWarning);
    await _notifications.cancel(id: idLutealPhase);
    await _notifications.cancel(id: idLatePeriod);
    debugPrint('[NotificationService] Semua notifikasi terjadwal dibatalkan');
  }

  /// Menjadwalkan pengingat siklus berdasarkan status siklus dan konfigurasi pengguna
  Future<void> scheduleCycleReminders({
    required CycleState cycleState,
    required AppConfigModel config,
  }) async {
    if (kIsWeb) return;
    if (!config.isNotificationsEnabled) {
      await cancelAllReminders();
      return;
    }

    await init();
    final expectedDate = cycleState.nextPeriodDate;
    if (expectedDate == null) return;

    final isMale = config.isMaleHelper;
    final partnerName = config.partnerName.isNotEmpty ? config.partnerName : 'Pasangan';
    final now = DateTime.now();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    // 1. Notifikasi H-2 Haid
    final h2Date = expectedDate.subtract(const Duration(days: 2));
    final scheduledH2 = DateTime(
      h2Date.year,
      h2Date.month,
      h2Date.day,
      config.notificationHour,
      config.notificationMinute,
    );

    if (scheduledH2.isAfter(now)) {
      final title = 'Pengingat Siklus Lunara';
      final body = isMale
          ? 'Perkiraan haid $partnerName sekitar 2 hari lagi. Siapkan perhatian dan kebutuhan kenyamanannya.'
          : 'Perkiraan haidmu sekitar 2 hari lagi. Siapkan pembalut atau kebutuhan kenyamanan pribadimu.';

      try {
        await _notifications.zonedSchedule(
          id: idPeriodWarning,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(scheduledH2, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('[NotificationService] H-2 haid dijadwalkan pada: $scheduledH2');
      } catch (e) {
        debugPrint('[NotificationService] Gagal menjadwalkan H-2: $e');
      }
    }

    // 2. Notifikasi Fase Luteal / PMS (Hari ke-16 dari haid terakhir)
    final lastPeriod = cycleState.activeCycle?.startDate;
    if (lastPeriod != null) {
      final lutealDate = lastPeriod.add(const Duration(days: 15)); // Hari ke-16
      final scheduledLuteal = DateTime(
        lutealDate.year,
        lutealDate.month,
        lutealDate.day,
        config.notificationHour,
        config.notificationMinute,
      );

      if (scheduledLuteal.isAfter(now)) {
        final title = 'Fase Luteal & Perubahan Energi';
        final body = isMale
            ? '$partnerName memasuki fase Luteal (PMS). Mood mungkin lebih sensitif, berikan ruang aman dan dukungan hangat.'
            : 'Kamu memasuki fase Luteal. Energi tubuh menurun secara alami, prioritaskan istirahat cukup dan nutrisi bergizi.';

        try {
          await _notifications.zonedSchedule(
            id: idLutealPhase,
            title: title,
            body: body,
            scheduledDate: tz.TZDateTime.from(scheduledLuteal, tz.local),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          debugPrint('[NotificationService] Luteal reminder dijadwalkan pada: $scheduledLuteal');
        } catch (e) {
          debugPrint('[NotificationService] Gagal menjadwalkan Luteal: $e');
        }
      }
    }

    // 3. Notifikasi Lembut Keterlambatan Siklus (Jika siklus telah terlewat >= 3 hari)
    final delayDate = expectedDate.add(const Duration(days: 3));
    final scheduledDelay = DateTime(
      delayDate.year,
      delayDate.month,
      delayDate.day,
      config.notificationHour,
      config.notificationMinute,
    );

    if (scheduledDelay.isAfter(now)) {
      final title = 'Pemeriksaan Siklus Lunara';
      final body = isMale
          ? 'Siklus $partnerName belum terlacak selama beberapa hari. Buka Lunara untuk mengecek faktor biologis pendukung.'
          : 'Haidmu terdeteksi terlambat beberapa hari. Buka Lunara untuk evaluasi faktor biologis (stres atau kelelahan).';

      try {
        await _notifications.zonedSchedule(
          id: idLatePeriod,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(scheduledDelay, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('[NotificationService] Late reminder dijadwalkan pada: $scheduledDelay');
      } catch (e) {
        debugPrint('[NotificationService] Gagal menjadwalkan Late reminder: $e');
      }
    }
  }
}
