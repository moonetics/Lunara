import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../database/local_db_service.dart';
import '../database/models/app_config_model.dart';
import '../database/models/cycle_model.dart';
import '../database/models/daily_entry_model.dart';
import '../database/models/triage_record_model.dart';
import '../services/cycle_engine.dart';

/// Layanan Pembuat Laporan Rekam Medis PDF 1 Halaman A4 untuk Dokter Sp.OG
/// Didesain dengan tema Soft Pink profesional, tipografi terstruktur, dan tata letak seimbang.
class PdfExportService {
  PdfExportService._();
  static final PdfExportService instance = PdfExportService._();

  // Palet Warna Soft Pink Profesional
  static const PdfColor primaryColor = PdfColor.fromInt(0xFFB8556D);   // Deep Blush Rose
  static const PdfColor primaryLight = PdfColor.fromInt(0xFFFDEEF1);   // Pale Rose Cream
  static const PdfColor accentColor = PdfColor.fromInt(0xFFE28298);    // Soft Rose Pink
  static const PdfColor textDark = PdfColor.fromInt(0xFF2D2326);       // Deep Slate Charcoal
  static const PdfColor textMuted = PdfColor.fromInt(0xFF7D6E72);      // Muted Taupe
  static const PdfColor borderColor = PdfColor.fromInt(0xFFF4E4E8);    // Soft Rose Border
  static const PdfColor tableZebra = PdfColor.fromInt(0xFFFFF9FA);     // Ultra-light rose
  static const PdfColor alertRed = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor alertRedLight = PdfColor.fromInt(0xFFFEE2E2);

  /// Menghasilkan file PDF 1 lembar A4 siap cetak / konsultasi klinis
  Future<Uint8List> generateMedicalReport({
    required String patientName,
    String? patientAge,
    required AppConfigModel config,
    required List<CycleModel> pastCycles,
    CycleModel? activeCycle,
    TriageRecordModel? latestTriage,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool includeIntimacy = true,
  }) async {
    final pdf = pw.Document();
    final shortDateFormat = DateFormat('dd/MM/yyyy');
    final reportDate = DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now());

    // Muat logo emblem untuk kop surat jika tersedia
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo_without_text.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      // Fallback jika headless test environment
    }

    // Saring hanya siklus yang sudah selesai (bukan ongoing) untuk perhitungan rata-rata
    final completedCycles = pastCycles.where((c) => !c.isOngoing && c.endDate != null).toList();
    final avgCycleLength = CycleEngine.calculateAverageCycleLength(
      completedCycles.isNotEmpty ? completedCycles : pastCycles,
    );

    CycleModel? effectiveActiveCycle = activeCycle;
    if (effectiveActiveCycle == null) {
      try {
        effectiveActiveCycle = LocalDbService.instance.getActiveCycle();
      } catch (_) {
        // Fallback jika database belum diinisialisasi dalam lingkungan headless test
      }
    }

    TriageRecordModel? effectiveLatestTriage = latestTriage;
    if (effectiveLatestTriage == null) {
      try {
        final triageRecords = LocalDbService.instance.getAllTriageRecords();
        effectiveLatestTriage = triageRecords.isNotEmpty ? triageRecords.first : null;
      } catch (_) {
        // Fallback jika database belum diinisialisasi dalam lingkungan headless test
      }
    }

    // Penomoran subjudul dinamis sesuai opsi keintiman
    final intimacySectionNumber = includeIntimacy ? '2' : '';
    final triageSectionNumber = includeIntimacy ? '3' : '2';
    final notesSectionNumber = (effectiveLatestTriage != null)
        ? (includeIntimacy ? '4' : '3')
        : (includeIntimacy ? '3' : '2');

    // Ambil maksimal 5 siklus terakhir agar muat rapi & seimbang dalam 1 halaman A4
    final recentCycles = pastCycles.take(5).toList();

    // Rata-rata durasi haid dari siklus yang tervalidasi selesai
    final validDurations = completedCycles
        .where((c) => c.periodDurationDays >= 2 && c.periodDurationDays <= 12)
        .map((c) => c.periodDurationDays)
        .toList();
    final avgDuration = validDurations.isNotEmpty
        ? (validDurations.reduce((a, b) => a + b) / validDurations.length).toStringAsFixed(1)
        : (completedCycles.isNotEmpty
            ? completedCycles.first.periodDurationDays.toString()
            : config.defaultPeriodDuration.toString());

    // Ambil catatan keintiman 90 hari terakhir untuk tinjauan ginekologi
    List<DailyEntryModel> recentIntimacy = [];
    try {
      final allEntries = LocalDbService.instance.getAllDailyEntries();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      recentIntimacy = allEntries.where((e) => e.hasIntimacy && e.entryDate.isAfter(cutoffDate)).toList();
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==================== 1. KOP & HEADER DOKUMEN (STANDAR A4) ====================
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Logo / Emblem Lunara
                  if (logoImage != null)
                    pw.Container(
                      width: 26,
                      height: 26,
                      margin: const pw.EdgeInsets.only(right: 8),
                      child: pw.Image(logoImage),
                    ),
                  // Badge Nama Lunara
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'LUNARA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // Judul & Subjudul Laporan Klinis (Expanded agar teks membungkus rapi tanpa overflow)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LAPORAN REKAM MEDIS MENSTRUASI',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Ringkasan Siklus Mandiri untuk Konsultasi Dokter Spesialis Obstetri & Ginekologi (Sp.OG)',
                          style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  // Badge Dokumen Resmi & Timestamp Cetak (Rata Kanan Rapi)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: pw.BoxDecoration(
                          color: primaryLight,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: borderColor, width: 0.5),
                        ),
                        child: pw.Text(
                          'DOKUMEN RESMI PASIEN',
                          style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                      ),
                      pw.SizedBox(height: 2.5),
                      pw.Text(
                        'Cetak: $reportDate WIB',
                        style: const pw.TextStyle(fontSize: 7, color: textMuted),
                        textAlign: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: accentColor, thickness: 1.5),
              pw.SizedBox(height: 8),

              // ==================== 2. IDENTITAS & INDIKATOR UTAMA ====================
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Identitas Pasien
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: primaryLight,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: borderColor, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DATA PASIEN',
                            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                          pw.SizedBox(height: 4),
                          _buildPatientRow('Nama/Inisial', patientName.isNotEmpty ? patientName : 'Pasien Lunara'),
                          _buildPatientRow('Usia', (patientAge != null && patientAge.isNotEmpty) ? patientAge : '-'),
                          _buildPatientRow('Model Pantau', config.isMaleHelper ? 'Bantuan Pasangan' : 'Mandiri'),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),

                  // 3 Box Metrik Kunci
                  pw.Expanded(
                    flex: 6,
                    child: pw.Row(
                      children: [
                        _buildMetricBox(
                          title: 'HPHT TERAKHIR',
                          value: effectiveActiveCycle != null ? shortDateFormat.format(effectiveActiveCycle.startDate) : '-',
                          subtitle: effectiveActiveCycle != null
                              ? 'Hari ke-${DateTime.now().difference(effectiveActiveCycle.startDate).inDays + 1}'
                              : 'Belum ada data',
                        ),
                        pw.SizedBox(width: 6),
                        _buildMetricBox(
                          title: 'RATA-RATA SIKLUS',
                          value: completedCycles.isNotEmpty ? '${avgCycleLength.toStringAsFixed(1)} Hari' : '-',
                          subtitle: completedCycles.isNotEmpty ? 'Standar ACOG (21-35 hr)' : 'Belum ada data',
                        ),
                        pw.SizedBox(width: 6),
                        _buildMetricBox(
                          title: 'RATA-RATA HAID',
                          value: completedCycles.isNotEmpty ? '$avgDuration Hari' : '-',
                          subtitle: completedCycles.isNotEmpty ? '${completedCycles.length} Siklus Selesai' : 'Belum ada data',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ==================== 3. RIWAYAT SIKLUS TERAKHIR ====================
              _buildSubheader('1', 'RIWAYAT SIKLUS & MENSTRUASI TERAKHIR'),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                headerDecoration: const pw.BoxDecoration(color: primaryLight),
                headerHeight: 20,
                cellHeight: 18,
                headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 7.5, color: textDark),
                columnWidths: const {
                  0: pw.FixedColumnWidth(24),
                  1: pw.FlexColumnWidth(2.2),
                  2: pw.FlexColumnWidth(1.8),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(2.5),
                  5: pw.FlexColumnWidth(2.5),
                },
                headers: <String>[
                  'No',
                  'Tanggal Mulai (HPHT)',
                  'Panjang Siklus',
                  'Lama Haid',
                  'Status Variasi Fisiologis',
                  'Catatan Validitas',
                ],
                data: recentCycles.isEmpty
                    ? [
                        [
                          '1',
                          effectiveActiveCycle != null ? shortDateFormat.format(effectiveActiveCycle.startDate) : '-',
                          '-',
                          effectiveActiveCycle != null ? 'Sedang Berjalan' : '-',
                          effectiveActiveCycle != null ? 'Siklus Aktif (Belum Selesai)' : 'Belum Ada Siklus',
                          effectiveActiveCycle != null ? 'Haid Berlangsung (Ongoing)' : 'Menunggu Input',
                        ]
                      ]
                    : List<List<String>>.generate(recentCycles.length, (index) {
                        final cycle = recentCycles[index];
                        final isCycleOngoing = cycle.isOngoing || cycle.endDate == null;

                        final lengthStr = isCycleOngoing ? 'Sedang Berjalan' : '${cycle.cycleLengthDays} Hari';
                        final durStr = isCycleOngoing
                            ? 'Hari ke-${cycle.periodDurationDays} (Sedang Haid)'
                            : '${cycle.periodDurationDays} Hari';
                        final isRegular = cycle.cycleLengthDays >= 21 && cycle.cycleLengthDays <= 35;
                        final statusStr = isCycleOngoing
                            ? 'Siklus Aktif (Belum Selesai)'
                            : (isRegular ? 'Teratur (Normal ACOG)' : 'Variasi Siklus');
                        final noteStr = isCycleOngoing
                            ? 'Haid Berlangsung (Ongoing)'
                            : (cycle.isOutlier ? 'Jeda Terlewat (>45 hr)' : 'Data Tervalidasi');

                        return [
                          '#${recentCycles.length - index}',
                          shortDateFormat.format(cycle.startDate),
                          lengthStr,
                          durStr,
                          statusStr,
                          noteStr,
                        ];
                      }),
              ),
              // Catatan Kaki Resmi (*Footnote* ACOG 219 & FIGO) di bawah tabel
              pw.SizedBox(height: 3),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '* ',
                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: textMuted),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'Catatan Klinis Rujukan: Standar keteraturan siklus mengacu pada ACOG Practice Bulletin No. 219 & FIGO (siklus normal: 21-35 hari, durasi haid: 3-8 hari, variabilitas antar-siklus: <= 9 hari). Siklus bertanda \'Sedang Berjalan\' belum dihitung ke dalam pembagi rata-rata.',
                      style: const pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic, color: textMuted),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ==================== 4. RINGKASAN KEINTIMAN (90 HARI TERAKHIR) ====================
              if (includeIntimacy) ...[
                _buildSubheader(intimacySectionNumber, 'CATATAN KEINTIMAN & AKTIVITAS SEKSUAL (90 HARI TERAKHIR)'),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: primaryLight,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: borderColor, width: 0.8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildIntimacyInfoCol(
                        label: 'Frekuensi Tercatat',
                        val: recentIntimacy.isNotEmpty ? '${recentIntimacy.length} Kali' : 'Tidak ada catatan',
                      ),
                      pw.Container(width: 0.5, height: 20, color: borderColor),
                      _buildIntimacyInfoCol(
                        label: 'Aktivitas Terakhir',
                        val: recentIntimacy.isNotEmpty ? shortDateFormat.format(recentIntimacy.first.entryDate) : '-',
                      ),
                      pw.Container(width: 0.5, height: 20, color: borderColor),
                      _buildIntimacyInfoCol(
                        label: 'Metode Perlindungan',
                        val: recentIntimacy.any((e) => e.usedProtection == false)
                            ? 'Tercatat Tanpa Pengaman'
                            : (recentIntimacy.isNotEmpty ? 'Dengan Pengaman' : 'N/A'),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
              ],

              // ==================== 5. EVALUASI TRIAGE & GEJALA ====================
              if (effectiveLatestTriage != null) ...[
                _buildSubheader(triageSectionNumber, 'EVALUASI KETERLAMBATAN & TRIAGE KLINIS'),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: effectiveLatestTriage.isRedFlag ? alertRedLight : primaryLight,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(
                      color: effectiveLatestTriage.isRedFlag ? alertRed : primaryColor,
                      width: 0.8,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Hasil Evaluasi Mandiri: ${effectiveLatestTriage.recommendationSummary.isNotEmpty ? effectiveLatestTriage.recommendationSummary : "Variasi Fisiologis Normal"}',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: effectiveLatestTriage.isRedFlag ? alertRed : primaryColor,
                            ),
                          ),
                          pw.Text(
                            'Tanggal Evaluasi: ${shortDateFormat.format(effectiveLatestTriage.testDate)}',
                            style: const pw.TextStyle(fontSize: 7, color: textMuted),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        effectiveLatestTriage.isRedFlag
                            ? 'PERINGATAN KLINIS: Gejala memerlukan konfirmasi pemeriksaan fisik oleh dokter Sp.OG.'
                            : 'Faktor pemicu fisiologis: Skor stres ${effectiveLatestTriage.stressLevel}/5, aktivitas fisik & kelelahan.',
                        style: const pw.TextStyle(fontSize: 7.5, color: textDark),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
              ],

              // ==================== 6. AREA CATATAN DOKTER Sp.OG ====================
              _buildSubheader(notesSectionNumber, 'LEMBAR PEMERIKSAAN DOKTER Sp.OG / BIDAN'),
              pw.Container(
                width: double.infinity,
                height: 90,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor, style: pw.BorderStyle.dashed, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Catatan Klinis Dokter:',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textMuted),
                        ),
                        pw.Text(
                          'Paraf / Tanda Tangan: ____________________',
                          style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Hasil Pemeriksaan Fisik / USG: \n\nDiagnosa Klinis: \n\nRencana Terapi / Edukasi Pasien:',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              // ==================== 7. FOOTER MEDIS ====================
              pw.Divider(color: borderColor, thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'PANDUAN MEDIS: Dihasilkan oleh Lunara (100% Local-First). Algoritma selaras dengan Konsensus POGI, ACOG Practice Bulletin No. 219, NICE Guidelines (PMS/PMDD), & Guyton-Hall Fisiologi.',
                      style: const pw.TextStyle(fontSize: 6.5, color: textMuted),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Text(
                    'Hal. 1 dari 1',
                    style: const pw.TextStyle(fontSize: 7, color: textMuted),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSubheader(String number, String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const pw.EdgeInsets.only(bottom: 5),
      decoration: pw.BoxDecoration(
        color: primaryLight,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 13,
            height: 13,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              color: primaryColor,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              number,
              style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientRow(String label, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 65,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: textMuted)),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 8, color: textMuted)),
          pw.Expanded(
            child: pw.Text(
              val,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textDark),
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricBox({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: primaryLight,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: borderColor, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(fontSize: 6, color: textMuted),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildIntimacyInfoCol({
    required String label,
    required String val,
  }) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 6.5, color: textMuted)),
        pw.SizedBox(height: 2),
        pw.Text(
          val,
          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
        ),
      ],
    );
  }
}
