import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'pdf_preview_screen.dart';

/// Dialog input identitas pasien sebelum mengekspor berkas PDF rekam medis
class PatientInfoDialog extends StatefulWidget {
  const PatientInfoDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const PatientInfoDialog(),
    );
  }

  @override
  State<PatientInfoDialog> createState() => _PatientInfoDialogState();
}

class _PatientInfoDialogState extends State<PatientInfoDialog> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  bool _includeIntimacy = true;

  @override
  void initState() {
    super.initState();
    final config = LocalDbService.instance.getConfig();
    final defaultName = config.isMaleHelper && config.partnerName.isNotEmpty
        ? config.partnerName
        : 'Pasien Lunara';
    _nameController = TextEditingController(text: defaultName);
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _submit() {
    HapticFeedback.lightImpact();
    final name = _nameController.text.trim();
    final age = _ageController.text.trim();

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          patientName: name.isNotEmpty ? name : 'Pasien Lunara',
          patientAge: age.isNotEmpty ? age : null,
          includeIntimacy: _includeIntimacy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ekspor PDF Medis',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Ringkasan 1 halaman untuk Dokter Sp.OG',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Identitas pada Dokumen (Opsional / Inisial):',
              style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap / Inisial Pasien',
                hintText: 'Contoh: Ny. Dinda / D.A.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: 'Usia / Tahun Lahir',
                hintText: 'Contoh: 26 Tahun / 1999',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _includeIntimacy
                    ? AppColors.intimacyLight.withValues(alpha: 0.5)
                    : AppColors.surfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _includeIntimacy
                      ? AppColors.intimacyAccent.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _includeIntimacy ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _includeIntimacy ? AppColors.intimacyAccent : AppColors.textTertiary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Keintiman & Seksual',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _includeIntimacy
                              ? 'Sertakan frekuensi & metode pengaman 90 hari'
                              : 'Aktivitas intim dirahasiakan dari berkas PDF',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _includeIntimacy,
                    activeTrackColor: AppColors.primary,
                    activeThumbColor: Colors.white,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _includeIntimacy = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data dibuat 100% lokal di perangkat dan tidak dikirim ke server mana pun.',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Batal',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Buka Pratinjau'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
