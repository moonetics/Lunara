import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Layar Pratinjau Interaktif PDF Rekam Medis Pasien Lunara
class PdfPreviewScreen extends StatelessWidget {
  final String patientName;
  final String? patientAge;
  final bool includeIntimacy;

  const PdfPreviewScreen({
    super.key,
    required this.patientName,
    this.patientAge,
    this.includeIntimacy = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = LocalDbService.instance.getConfig();
    final pastCycles = LocalDbService.instance.getAllCycles();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Rekam Medis PDF',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: PdfPreview(
        initialPageFormat: PdfPageFormat.a4,
        pageFormats: const {'A4': PdfPageFormat.a4},
        build: (format) => PdfExportService.instance.generateMedicalReport(
          patientName: patientName,
          patientAge: patientAge,
          config: config,
          pastCycles: pastCycles,
          pageFormat: format,
          includeIntimacy: includeIntimacy,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'Lunara_Rekam_Siklus_${patientName.replaceAll(' ', '_')}.pdf',
        previewPageMargin: const EdgeInsets.all(16),
        loadingWidget: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Menyusun Dokumen Rekam Medis...',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
