import 'package:flutter/material.dart';
import '../../../core/database/local_db_service.dart';
import 'biometric_lock_screen.dart';

/// Gerbang Keamanan Biometrik & Lifecycle Observer Lunara
class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({
    super.key,
    required this.child,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _isLocked = false;
  DateTime? _lastPausedAt;

  // Batas toleransi latar belakang sebelum aplikasi terkunci (30 detik)
  static const Duration _lockTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Kunci saat cold start jika biometrik diaktifkan oleh pengguna
    final config = LocalDbService.instance.getConfig();
    if (config.isBiometricEnabled) {
      _isLocked = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final config = LocalDbService.instance.getConfig();
    if (!config.isBiometricEnabled) {
      if (_isLocked) {
        setState(() => _isLocked = false);
      }
      return;
    }

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _lastPausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_lastPausedAt != null) {
        final elapsed = DateTime.now().difference(_lastPausedAt!);
        if (elapsed > _lockTimeout) {
          setState(() {
            _isLocked = true;
          });
        }
      }
      _lastPausedAt = null;
    }
  }

  void _onUnlocked() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return BiometricLockScreen(onAuthenticated: _onUnlocked);
    }
    return widget.child;
  }
}
