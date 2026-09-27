import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Modal Lembar Kebijakan Privasi, Syarat Medis, dan Tentang Lunara
class LegalInfoSheets {
  /// Menampilkan lembar Kebijakan Privasi (100% Local-First & Zero Tracking)
  static void showPrivacyPolicy(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheetContainer(
        context: ctx,
        icon: Icons.shield_rounded,
        iconColor: AppColors.primary,
        iconBg: AppColors.primaryContainer,
        tag: 'PRIVASI & PERLINDUNGAN DATA',
        title: 'Kebijakan Privasi Lunara',
        sections: const [
          _LegalSection(
            title: '1. Arsitektur 100% Local-First (Offline)',
            body:
                'Seluruh catatan siklus, log gejala, riwayat keintiman, dan rekam medis Anda disimpan secara eksklusif di dalam memori internal perangkat ponsel Anda menggunakan basis data Hive lokal. Tidak ada peladen (server) luar atau sistem komputasi awan (cloud) pihak ketiga yang menyimpan data sensitif Anda.',
          ),
          _LegalSection(
            title: '2. Bebas Iklan & Tanpa Pelacakan (Zero Telemetry)',
            body:
                'Lunara tidak menyematkan pustaka pelacak (analytics SDK), Facebook Pixel, pengenal iklan (advertising ID), atau pelacak telemetri apa pun. Aktivitas penggunaan dan riwayat kesehatan reproduksi Anda adalah rahasia pribadi yang seutuhnya milik Anda.',
          ),
          _LegalSection(
            title: '3. Kontrol Penuh Penghapusan & Cadangan',
            body:
                'Anda memegang kendali mutlak atas data Anda. Anda dapat mengekspor salinan data terenkripsi lokal kapan pun, serta menghapus catatan harian atau seluruh basis data aplikasi secara permanen melalui menu Pengaturan.',
          ),
          _LegalSection(
            title: '4. Kepatuhan Standar Perlindungan Data Kesehatan',
            body:
                'Perancangan aplikasi Lunara berpedoman pada prinsip privasi ketat yang selaras dengan UU Perlindungan Data Pribadi (UU PDP) dan standar global GDPR untuk kategori data kesehatan khusus.',
          ),
        ],
      ),
    );
  }

  /// Menampilkan lembar Syarat Penggunaan & Batasan Tanggung Jawab Medis
  static void showMedicalDisclaimer(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheetContainer(
        context: ctx,
        icon: Icons.medical_services_rounded,
        iconColor: AppColors.intimacyAccent,
        iconBg: AppColors.intimacyLight,
        tag: 'BATASAN TANGGUNG JAWAB MEDIS',
        title: 'Syarat & Disclaimer Medis',
        sections: const [
          _LegalSection(
            title: '1. Bukan Pengganti Tenaga Medis Profesional',
            body:
                'Lunara dirancang sebagai alat bantu pencatatan mandiri, estimasi fisiologis, dan edukasi kesehatan reproduksi. Informasi yang disajikan BUKAN diagnosis medis resmi, BUKAN pengganti pemeriksaan ultrasonografi (USG), dan BUKAN pengganti konsultasi langsung dengan dokter spesialis obstetri & ginekologi (Sp.OG) atau bidan berwenang.',
          ),
          _LegalSection(
            title: '2. Estimasi Kalender Bukan Kontrasepsi Mutlak',
            body:
                'Perhitungan masa subur, ovulasi, dan jendela konsepsi didasarkan pada model biologis literatur medis (ACOG & Guyton/Hall). Karena panjang siklus wanita dapat dipengaruhi oleh stres, pola tidur, hormon, dan nutrisi, estimasi kalender tidak boleh dijadikan sebagai satu-satunya metode pencegahan kehamilan tanpa kontrasepsi barrier (seperti kondom).',
          ),
          _LegalSection(
            title: '3. Penanganan Kegawatdaruratan (Red Flags)',
            body:
                'Jika Anda mengalami gejala darurat seperti kram perut hebat yang tiba-tiba, perdarahan hebat tak lazim (mengganti pembalut tiap 1 jam), pusing ekstrem, atau demam tinggi saat haid, segera hubungi fasilitas pelayanan kesehatan atau instalasi gawat darurat (IGD) terdekat.',
          ),
        ],
      ),
    );
  }

  /// Menampilkan lembar informasi Tentang Lunara
  static void showAboutLunara(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheetContainer(
        context: ctx,
        icon: Icons.auto_awesome_rounded,
        iconColor: AppColors.primary,
        iconBg: AppColors.primaryContainer,
        tag: 'TENTANG APLIKASI',
        title: 'Tentang Lunara',
        customHeader: Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo_without_text.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'LUNARA',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Versi 1.0.0 • Local-First Menstrual Companion',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        sections: const [
          _LegalSection(
            title: 'Filosofi & Misi',
            body:
                'Lunara lahir untuk menghadirkan pengalaman pelacakan siklus bulanan yang intim, nyaman, dan berempati. Kami percaya bahwa kesehatan reproduksi wanita adalah hal yang bermartabat dan data tubuh Anda berhak mendapatkan perlindungan privasi tertinggi tanpa kompromi iklan.',
          ),
          _LegalSection(
            title: 'Landasan Rujukan Ilmiah Medis Resmi',
            body:
                '• POGI (Perkumpulan Obstetri & Ginekologi Indonesia) - Konsensus Nasional Gangguan Haid & Dismenore\n• ACOG (American College of Obstetricians and Gynecologists) Practice Bulletin No. 219 - Standar Evaluasi Menstruasi Normal & Keteraturan Fisiologis\n• NICE Clinical Guidelines (UK) NG88 - Diagnosis & Manajemen Premenstrual Syndrome (PMS & PMDD)\n• Guyton and Hall Textbook of Medical Physiology (14th Ed) - Bab 82 Dinamika Hormon Reproduksi Wanita & Ovulasi\n• Speroff\'s Clinical Gynecologic Endocrinology and Infertility (9th Ed) - Bab 11 Amenorrhea & Poros HPO/HPA\n• WHO (World Health Organization) Selected Practice Recommendations for Contraceptive Use',
          ),
          _LegalSection(
            title: 'Koleksi Mode Pendamping (Mode Pria)',
            body:
                'Lunara menyediakan perspektif khusus untuk pasangan pria agar dapat memahami fluktuasi hormon pasangannya dengan panduan empati harian berbasis sains, mempererat ikatan cinta dan pengertian emosional.',
          ),
        ],
      ),
    );
  }

  static Widget _buildSheetContainer({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String tag,
    required String title,
    Widget? customHeader,
    required List<_LegalSection> sections,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          ?customHeader,

          // Header Badge & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: AppTypography.bodySmall.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Scrollable Sections
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: sections.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final sec = sections[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sec.title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sec.body,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Tutup
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  final String title;
  final String body;

  const _LegalSection({
    required this.title,
    required this.body,
  });
}
