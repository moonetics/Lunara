import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/database/models/app_config_model.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../pain_relief/presentation/pain_relief_screen.dart';
import '../../pdf_export/presentation/patient_info_dialog.dart';
import '../../tracker/state/cycle_notifier.dart';
import '../../../core/widgets/medical_term_bottom_sheet.dart';
import 'legal_info_sheets.dart';

/// Layar Pengaturan & Privasi Lunara (Keamanan Biometrik, Notifikasi, Mode Pengguna)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late AppConfigModel _config;
  late TextEditingController _partnerController;

  @override
  void initState() {
    super.initState();
    _config = LocalDbService.instance.getConfig();
    _partnerController = TextEditingController(text: _config.partnerName);
  }

  @override
  void dispose() {
    _partnerController.dispose();
    super.dispose();
  }

  Future<void> _toggleBiometrics(bool value) async {
    HapticFeedback.lightImpact();
    if (value) {
      // Uji autentikasi sebelum mengaktifkan
      final canAuth = await BiometricService.instance.canAuthenticate();
      if (!canAuth) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.redFlag,
            content: const Text(
              'Perangkat tidak mendukung biometrik atau PIN/pola belum diatur di pengaturan HP.',
            ),
          ),
        );
        return;
      }

      final authenticated = await BiometricService.instance.authenticate(
        reason: 'Verifikasi sidik jari/PIN untuk mengaktifkan perlindungan privasi Lunara',
      );

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _config.isBiometricEnabled = true;
        });
        await LocalDbService.instance.saveConfig(_config);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Kunci biometrik berhasil diaktifkan.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.redFlag,
            content: const Text('Autentikasi dibatalkan. Kunci biometrik belum aktif.'),
          ),
        );
      }
    } else {
      setState(() {
        _config.isBiometricEnabled = false;
      });
      await LocalDbService.instance.saveConfig(_config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Kunci biometrik dinonaktifkan.'),
        ),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    HapticFeedback.lightImpact();
    if (value) {
      final granted = await NotificationService.instance.requestNotificationPermission();
      if (!mounted) return;

      if (granted) {
        setState(() {
          _config.isNotificationsEnabled = true;
        });
        await LocalDbService.instance.saveConfig(_config);

        // Jadwalkan notifikasi siklus saat ini
        final cycleState = ref.read(cycleProvider);
        await NotificationService.instance.scheduleCycleReminders(
          cycleState: cycleState,
          config: _config,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Notifikasi pengingat siklus berhasil diaktifkan.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.redFlag,
            content: const Text('Izin notifikasi tidak diberikan oleh sistem.'),
          ),
        );
      }
    } else {
      setState(() {
        _config.isNotificationsEnabled = false;
      });
      await LocalDbService.instance.saveConfig(_config);
      await NotificationService.instance.cancelAllReminders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Semua jadwal pengingat notifikasi dibatalkan.'),
        ),
      );
    }
  }

  Future<void> _pickReminderTime() async {
    HapticFeedback.selectionClick();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _config.notificationHour,
        minute: _config.notificationMinute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _config.notificationHour = pickedTime.hour;
        _config.notificationMinute = pickedTime.minute;
      });
      await LocalDbService.instance.saveConfig(_config);

      // Reschedule reminders
      if (_config.isNotificationsEnabled) {
        final cycleState = ref.read(cycleProvider);
        await NotificationService.instance.scheduleCycleReminders(
          cycleState: cycleState,
          config: _config,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Waktu pengingat diubah menjadi ${pickedTime.format(context)}.',
          ),
        ),
      );
    }
  }

  void _confirmResetData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.redFlag, size: 28),
            const SizedBox(width: 8),
            Text(
              'Hapus Semua Data?',
              style: AppTypography.titleLarge.copyWith(color: AppColors.redFlag),
            ),
          ],
        ),
        content: Text(
          'Tindakan ini akan menghapus permanen seluruh riwayat siklus, catatan harian, dan hasil triage kesehatan dari perangkat ini.\n\nData tidak dapat dipulihkan kembali.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.redFlag,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalDbService.instance.clearAllData();
              await NotificationService.instance.cancelAllReminders();
              ref.read(cycleProvider.notifier).loadCycles();

              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
            child: const Text('Ya, Hapus Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedHour = _config.notificationHour.toString().padLeft(2, '0');
    final formattedMinute = _config.notificationMinute.toString().padLeft(2, '0');
    final timeString = '$formattedHour:$formattedMinute WIB';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pengaturan & Privasi',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ==================== 1. KEAMANAN & BIOMETRIK ====================
          _buildSectionHeader('Keamanan & Privasi Data', Icons.security_rounded),
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: AppColors.onPrimary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Kunci Biometrik / PIN',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Kunci otomatis saat cold start atau saat aplikasi berada di latar belakang lebih dari 30 detik.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  value: _config.isBiometricEnabled,
                  onChanged: _toggleBiometrics,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: AppColors.onPrimary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Efek Suara Sambutan',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Mainkan nada denting santai menenangkan saat aplikasi dibuka.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  value: _config.isSoundEnabled,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _config.isSoundEnabled = val;
                    });
                    LocalDbService.instance.saveConfig(_config);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 2. NOTIFIKASI OFFLINE ====================
          _buildSectionHeader('Notifikasi Pengingat Lokal', Icons.notifications_active_rounded),
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: AppColors.onPrimary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.phaseFollicularLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.alarm_rounded, color: AppColors.phaseFollicular),
                  ),
                  title: Text(
                    'Pengingat Siklus Otomatis',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Jadwal lokal offline untuk H-2 haid, fase Luteal, dan evaluasi keterlambatan tanpa server.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  value: _config.isNotificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
                if (_config.isNotificationsEnabled) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.schedule_rounded, color: AppColors.textSecondary),
                    title: Text('Waktu Kirim Pengingat', style: AppTypography.bodyMedium),
                    subtitle: Text(
                      'Rekomendasi: Pagi hari yang tenang',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                    trailing: ActionChip(
                      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.5),
                      label: Text(
                        timeString,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _pickReminderTime,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 3. PREFERENSI PERSPEKTIF ====================
          _buildSectionHeader('Preferensi & Mode Penggunaan', Icons.person_pin_rounded),
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.surfaceVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peran Pengguna Utama',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPerspectiveCard(
                          title: 'Mencatat Mandiri',
                          subtitle: 'Ruang Wanita',
                          icon: Icons.female_rounded,
                          isSelected: !_config.isMaleHelper,
                          onTap: () {
                            setState(() {
                              _config.perspective = 'female_self';
                            });
                            LocalDbService.instance.saveConfig(_config);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPerspectiveCard(
                          title: 'Membantu Pasangan',
                          subtitle: 'Mode Pria',
                          icon: Icons.male_rounded,
                          isSelected: _config.isMaleHelper,
                          onTap: () {
                            setState(() {
                              _config.perspective = 'male_helper';
                            });
                            LocalDbService.instance.saveConfig(_config);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_config.isMaleHelper) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _partnerController,
                      decoration: InputDecoration(
                        labelText: 'Nama Panggilan Pasangan',
                        hintText: 'Contoh: Aisyah',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_rounded, color: AppColors.primary),
                          onPressed: () {
                            setState(() {
                              _config.partnerName = _partnerController.text.trim();
                            });
                            LocalDbService.instance.saveConfig(_config);
                            FocusScope.of(context).unfocus();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: const Text('Nama pasangan diperbarui.'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fokus Pelacakan Aplikasi',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                      ),
                      MedicalTermHelper.infoIcon(context, 'fabm'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPerspectiveCard(
                          title: 'Kesehatan',
                          subtitle: 'Fase & Gejala',
                          icon: Icons.spa_rounded,
                          isSelected: _config.isHealthTracking,
                          onTap: () {
                            setState(() {
                              _config.appGoal = 'health_tracking';
                            });
                            LocalDbService.instance.saveConfig(_config);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPerspectiveCard(
                          title: 'Promil (TTC)',
                          subtitle: 'Hari Emas',
                          icon: Icons.child_care_rounded,
                          isSelected: _config.isPregnancyProgram,
                          onTap: () {
                            setState(() {
                              _config.appGoal = 'pregnancy_program';
                            });
                            LocalDbService.instance.saveConfig(_config);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPerspectiveCard(
                          title: 'Tunda Hamil',
                          subtitle: 'Metode FABM',
                          icon: Icons.shield_outlined,
                          isSelected: _config.isNaturalContraception,
                          onTap: () {
                            setState(() {
                              _config.appGoal = 'natural_contraception';
                            });
                            LocalDbService.instance.saveConfig(_config);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_config.isPregnancyProgram) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.intimacyLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.intimacyAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.star_rounded, size: 18, color: AppColors.intimacyAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mode Program Hamil (TTC) mengoptimalkan peluang kehamilan dengan memetakan Hari Emas Konsepsi (H-2, H-1, Ovulasi) berprobabilitas ~36% (Wilcox et al., NEJM). ASRM menganjurkan frekuensi berhubungan intim setiap 1–2 hari sekali.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.intimacyAccent,
                                height: 1.4,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_config.isNaturalContraception) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.phaseFollicularLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.phaseFollicular.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.shield_rounded, size: 18, color: AppColors.phaseFollicular),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mode Tunda Kehamilan (FABM) memetakan Zona Merah (risiko tinggi konsepsi - wajib pengaman) dan Zona Hijau Aman (Fase Luteal pasca-ovulasi, risiko biologis 0%). Efektif bila siklus teratur (21–35 hari) dan tidak melindungi dari infeksi menular seksual.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onPhaseFollicular,
                                height: 1.4,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.spa_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mode Pantau Kesehatan melacak 4 fase fisiologis hormonal (Menstruasi, Folikular, Ovulasi, Luteal) untuk memahami fluktuasi energi, nutrisi harian, dan kenyamanan PMS.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryDark,
                                height: 1.4,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // ==================== 4. LAPORAN & REKAM MEDIS ====================
          _buildSectionHeader('Dokumen & Rekam Medis', Icons.medical_services_outlined),
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Cetak Ringkasan Siklus (PDF)',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Dokumen 1 halaman untuk dibawa saat kontrol ke dokter Sp.OG / bidan.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    PatientInfoDialog.show(context);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.phaseMenstrualLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.self_improvement_rounded, color: AppColors.phaseMenstrual),
                  ),
                  title: Text(
                    'Pustaka Solusi Mandiri Pereda Nyeri',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Edukasi mekanisme prostaglandin & 4 terapi non-obat terbukti ACOG.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PainReliefScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 5. CADANGAN & PEMULIHAN ====================
          _buildSectionHeader('Cadangan & Pemulihan (Offline JSON)', Icons.cloud_sync_outlined),
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
                  ),
                  title: Text(
                    'Cadangkan Data (Ekspor JSON)',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Simpan salinan rekam siklus ke penyimpanan HP atau kirim via WhatsApp.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await BackupService.instance.shareBackupFile();
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.file_download_outlined, color: AppColors.primary),
                  ),
                  title: Text(
                    'Pulihkan Data (Impor JSON)',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Pilih file .json cadangan untuk memulihkan seluruh riwayat siklus.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await BackupService.instance.pickAndRestoreBackup();
                    if (!mounted) return;
                    if (success) {
                      await ref.read(cycleProvider.notifier).loadCycles();
                      if (!mounted) return;
                      _config = LocalDbService.instance.getConfig();
                      setState(() {});
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: const Text('Data cadangan berhasil dipulihkan ke aplikasi.'),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.textSecondary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: const Text('Pemulihan dibatalkan atau berkas tidak valid.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          // ==================== 6. TENTANG & KEBIJAKAN ====================
          _buildSectionHeader('Tentang & Kebijakan', Icons.info_outline_rounded),
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Kebijakan Privasi (100% Offline)',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Jaminan perlindungan data lokal tanpa pelacak atau iklan.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    LegalInfoSheets.showPrivacyPolicy(context);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.phaseMenstrualLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services_outlined, color: AppColors.phaseMenstrual),
                  ),
                  title: Text(
                    'Syarat & Disclaimer Medis',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Batasan medis ACOG & panduan konsultasi dokter Sp.OG.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    LegalInfoSheets.showMedicalDisclaimer(context);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Tentang Lunara',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Versi 1.0.0, filosofi desain, & rujukan literatur klinis.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    LegalInfoSheets.showAboutLunara(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 7. DATA & RESET ====================
          _buildSectionHeader('Pembersihan Data', Icons.delete_outline_rounded),
          Card(
            elevation: 0,
            color: AppColors.redFlagLight.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.redFlag.withValues(alpha: 0.2)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.redFlag.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: AppColors.redFlag),
              ),
              title: Text(
                'Hapus Seluruh Data Aplikasi',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.redFlag,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Menghapus semua siklus, log harian, dan reset ke layar awal.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.redFlag),
              onTap: _confirmResetData,
            ),
          ),
          const SizedBox(height: 32),

          // ==================== 5. INFORMASI TENTANG ====================
          Center(
            child: Column(
              children: [
                Text(
                  'Lunara v1.0.0 • Local-First Menstrual Companion',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '100% Offline • Bebas Iklan & Tanpa Pelacakan Data',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerspectiveCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.4) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
