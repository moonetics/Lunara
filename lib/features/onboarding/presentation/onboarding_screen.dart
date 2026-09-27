import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/database/models/app_config_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../navigation/main_nav_screen.dart';
import '../../tracker/state/cycle_notifier.dart';

/// Layar Onboarding Dual-Perspective Lunara
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Step 1: Perspektif ('female_self' atau 'male_helper')
  String _perspective = 'female_self';

  // Step 2: Data Awal
  final TextEditingController _nameController = TextEditingController();
  bool _recordNow = false; // Pengguna bebas mulai tanpa catatan haid
  DateTime _lastPeriodDate = DateTime.now().subtract(const Duration(days: 1));
  int _periodDuration = 5;
  int _cycleLength = 28;

  // Backfill Riwayat Masa Lalu
  bool _addPastCycle = false;
  DateTime _pastCycleDate = DateTime.now().subtract(const Duration(days: 31));

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickLastPeriodDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.lightImpact();
      setState(() => _lastPeriodDate = picked);
    }
  }

  Future<void> _pickPastCycleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pastCycleDate,
      firstDate: DateTime.now().subtract(const Duration(days: 180)),
      lastDate: _lastPeriodDate.subtract(const Duration(days: 20)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.lightImpact();
      setState(() => _pastCycleDate = picked);
    }
  }

  Future<void> _submitOnboarding() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim().isEmpty
          ? (_perspective == 'male_helper' ? 'Pasangan' : 'Saya')
          : _nameController.text.trim();

      // 1. Simpan Konfigurasi ke Hive
      final config = AppConfigModel(
        perspective: _perspective,
        partnerName: name,
        defaultCycleLength: _cycleLength,
        defaultPeriodDuration: _periodDuration,
      );
      await LocalDbService.instance.saveConfig(config);

      // 2. Jika pengguna memilih untuk mencatat haid saat onboarding
      if (_recordNow) {
        if (_addPastCycle) {
          final pastEnd = _pastCycleDate.add(Duration(days: _periodDuration - 1));
          await ref.read(cycleProvider.notifier).addHistoricalCycle(
                _pastCycleDate,
                endDate: pastEnd,
                explicitCycleLength: _lastPeriodDate.difference(_pastCycleDate).inDays,
              );
        }

        await ref.read(cycleProvider.notifier).recordPeriodStart(
              _lastPeriodDate,
              periodDuration: _periodDuration,
            );
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy', 'id_ID');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Resmi Lunara
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo_with_text.png',
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              Text('Selamat Datang!', style: AppTypography.displayMedium),
              const SizedBox(height: 6),
              Text(
                'Aplikasi pelacak siklus 100% privat, bebas server, dan berbasis literatur kedokteran resmi.',
                style: AppTypography.bodyMedium,
              ),

              const SizedBox(height: 28),

              // BAGIAN 1: PEMILIHAN PERAN (PERSPEKTIF)
              Text('Bagaimana Anda akan menggunakan Lunara?', style: AppTypography.titleLarge),
              const SizedBox(height: 12),

              _buildRoleCard(
                keyId: 'female_self',
                title: 'Saya Mencatat untuk Diri Sendiri',
                subtitle: 'Pelacakan mandiri, edukasi 4 fase tubuh, dan modul pereda nyeri kram.',
                icon: Icons.person_rounded,
                accentColor: AppColors.primary,
              ),

              const SizedBox(height: 12),

              _buildRoleCard(
                keyId: 'male_helper',
                title: 'Saya Membantu Mencatatkan Pasangan',
                subtitle: 'Bantu catat siklus dia & dapatkan panduan perlakuan (Do\'s & Don\'ts) harian.',
                icon: Icons.favorite_rounded,
                accentColor: AppColors.phaseFollicular,
              ),

              const SizedBox(height: 28),

              // BAGIAN 2: INPUT NAMA & DATA HPHT
              Text(
                _perspective == 'male_helper' ? 'Nama Pasangan Anda' : 'Nama Panggilan Anda',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: _perspective == 'male_helper' ? 'Misal: Sarah' : 'Misal: Dinda',
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 20),

              // CARD PILIHAN: SUDAH HAID ATAU BELUM
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _recordNow ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _recordNow ? AppColors.primary : AppColors.border,
                    width: _recordNow ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catat Haid Sekarang?',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _recordNow
                                    ? 'Kamu sedang atau baru saja mulai haid'
                                    : 'Belum haid saat ini (bisa catat nanti)',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _recordNow,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            setState(() => _recordNow = val);
                          },
                        ),
                      ],
                    ),
                    if (!_recordNow) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.spa_outlined, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tenang, kamu bisa langsung mulai tanpa catatan. Begitu darah haid pertama keluar, cukup tekan tombol "Mulai Haid Hari Ini" di Beranda.',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (_recordNow) ...[
                const SizedBox(height: 20),

                Text('Hari Pertama Haid Terakhir (HPHT)', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickLastPeriodDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.water_drop_outlined, color: AppColors.phaseMenstrual),
                            const SizedBox(width: 12),
                            Text(dateFormat.format(_lastPeriodDate), style: AppTypography.bodyLarge),
                          ],
                        ),
                        const Icon(Icons.edit_calendar_rounded, size: 20, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Estimasi Panjang Siklus & Durasi
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Panjang Siklus', style: AppTypography.titleMedium),
                          const SizedBox(height: 4),
                          Text('(Rata-rata 28 hari)', style: AppTypography.bodySmall),
                          const SizedBox(height: 8),
                          _buildCounter(
                            value: _cycleLength,
                            min: 21,
                            max: 40,
                            onChanged: (val) => setState(() => _cycleLength = val),
                            suffix: 'hari',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lama Haid', style: AppTypography.titleMedium),
                          const SizedBox(height: 4),
                          Text('(Rata-rata 5 hari)', style: AppTypography.bodySmall),
                          const SizedBox(height: 8),
                          _buildCounter(
                            value: _periodDuration,
                            min: 2,
                            max: 10,
                            onChanged: (val) => setState(() => _periodDuration = val),
                            suffix: 'hari',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // OPSI BACKFILL DATA LAMPAU
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _addPastCycle,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              HapticFeedback.lightImpact();
                              setState(() => _addPastCycle = val ?? false);
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _addPastCycle = !_addPastCycle),
                              child: Text(
                                'Saya masih ingat tanggal haid bulan lalu (Backfill)',
                                style: AppTypography.titleMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_addPastCycle) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _pickPastCycleDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bulan lalu: ${dateFormat.format(_pastCycleDate)}',
                                  style: AppTypography.bodyMedium,
                                ),
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '💡 Data lama ini akan langsung dijadikan acuan rata-rata awal Lunara.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // TOMBOL SELESAI
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOnboarding,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _recordNow ? 'Simpan & Masuk ke Beranda' : 'Mulai Bersama Lunara (Belum Haid)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String keyId,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _perspective == keyId;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _perspective = keyId);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: isSelected ? accentColor : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: accentColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    required String suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          Text('$value $suffix', style: AppTypography.labelLarge),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
