import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../database/local_db_service.dart';

/// Layaran Pengelola Efek Suara Lunara (Offline & Privacy-First)
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  AudioPlayer? _player;

  /// Memutar nada denting santai menyambut pengguna saat aplikasi dibuka
  Future<void> playWelcomeChime() async {
    try {
      final config = LocalDbService.instance.getConfig();
      if (!config.isSoundEnabled) return;

      _player ??= AudioPlayer();
      await _player!.stop();
      // Gunakan AssetSource dari file lokal yang didaftarkan di pubspec
      await _player!.play(AssetSource('audio/welcome_chime.wav'));
    } catch (e) {
      debugPrint('[SoundService] Suara sambutan tidak dapat diputar: $e');
    }
  }

  /// Membebaskan sumber daya pemutar suara
  void dispose() {
    try {
      _player?.dispose();
      _player = null;
    } catch (_) {}
  }
}
