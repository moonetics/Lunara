import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../navigation/main_nav_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../security/presentation/auth_gate.dart';

/// Layar Pembuka Resmi (Splash Screen) Lunara
/// Menampilkan animasi logo resmi dengan teks dan efek suara sambutan santai
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Jalankan animasi masuk
    _animController.forward();

    // Mainkan efek suara menenangkan saat pembukaan
    SoundService.instance.playWelcomeChime();

    // Transisi teratur ke halaman utama setelah durasi estetika tuntas (~2.5 detik)
    _navigationTimer = Timer(const Duration(milliseconds: 2500), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;

    final isFirstTime = LocalDbService.instance.isFirstTimeUser;
    final nextScreen = AuthGate(
      child: isFirstTime ? const OnboardingScreen() : const MainNavScreen(),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient gradient yang lembut dan nyaman
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    AppColors.primaryContainer.withValues(alpha: 0.5),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          // Konten Logo Tengah dengan Animasi Fade & Scale
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Lunara with text transparan (300x300 dp)
                      Image.asset(
                        'assets/images/logo_with_text.png',
                        width: 300,
                        height: 300,
                        fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite_rounded, size: 72, color: AppColors.primary),
                                const SizedBox(height: 12),
                                Text(
                                  'LUNARA',
                                  style: AppTypography.displayMedium.copyWith(
                                    letterSpacing: 2.0,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tagline di bagian bawah
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'Privat • Bebas Server • Berstandar Medis',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
