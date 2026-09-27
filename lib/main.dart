import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/database/local_db_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal dan data lokal Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Database Lokal 100% Offline (Hive)
  await LocalDbService.instance.init();

  // Inisialisasi Layanan Notifikasi Lokal Offline
  await NotificationService.instance.init();

  runApp(
    const ProviderScope(
      child: LunaraApp(),
    ),
  );
}

class LunaraApp extends StatelessWidget {
  const LunaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lunara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
