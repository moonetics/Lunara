import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service untuk menangani autentikasi biometrik (Fingerprint/Face/PIN) lokal
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Mengecek apakah perangkat memiliki sensor biometrik atau kapabilitas PIN/passcode
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Error checking support: $e');
      return false;
    }
  }

  /// Mendapatkan daftar biometrik yang terdaftar pada perangkat
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Error getting available biometrics: $e');
      return [];
    }
  }

  /// Melakukan proses autentikasi biometrik dengan fallback PIN / Pola perangkat
  Future<bool> authenticate({
    String reason = 'Buka kunci Lunara untuk melindungi privasi data kesehatanmu',
  }) async {
    try {
      final isAvailable = await canAuthenticate();
      if (!isAvailable) {
        debugPrint('[BiometricService] Hardware biometrik/kredensial tidak tersedia.');
        return false;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // Fallback ke PIN/Pola/Passcode
        persistAcrossBackgrounding: true,
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Autentikasi dibatalkan atau gagal: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Unexpected error: $e');
      return false;
    }
  }
}
