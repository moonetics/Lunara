import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/database/models/triage_record_model.dart';
import '../../../core/services/triage_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'triage_result_screen.dart';

/// Layar Kuesioner Evaluasi Keterlambatan Siklus 1 Menit
class TriageQuestionnaireScreen extends StatefulWidget {
  final int daysDelayed;

  const TriageQuestionnaireScreen({
    super.key,
    required this.daysDelayed,
  });

  @override
  State<TriageQuestionnaireScreen> createState() => _TriageQuestionnaireScreenState();
}

class _TriageQuestionnaireScreenState extends State<TriageQuestionnaireScreen> {
  // Q1: Hubungan Intim & Kehamilan
  String _pregnancyStatus = 'none'; // 'none', 'tested_negative', 'not_tested', 'tested_positive'

  // Q2: Tingkat Stres (1 s/d 5)
  double _stressLevel = 3.0;

  // Q3: Diet & Berat Badan
  bool _drasticDiet = false;

  // Q4: Olahraga Berat
  bool _intenseExercise = false;

  // Q5: Kontrasepsi Darurat
  bool _emergencyPill = false;

  // Skrining Red Flag (Nyeri Panggul Akut)
  bool _severePain = false;

  bool _isLoading = false;

  final Map<int, String> _stressDescriptions = {
    1: 'Sangat Tenang & Rileks',
    2: 'Beban Normal Sehari-hari',
    3: 'Sedang Banyak Tugas / Pikiran',
    4: 'Stres Cukup Tinggi & Lelah',
    5: 'Stres Sangat Berat / Insomnia',
  };

  void _submitTriage() {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final hasRisk = _pregnancyStatus != 'none';
      final testTaken = _pregnancyStatus == 'tested_negative' || _pregnancyStatus == 'tested_positive';
      final testResult = _pregnancyStatus == 'tested_positive'
          ? 'positive'
          : (_pregnancyStatus == 'tested_negative' ? 'negative' : 'not_tested');

      final input = TriageInput(
        daysDelayed: widget.daysDelayed,
        hasPregnancyRisk: hasRisk,
        pregnancyTestTaken: testTaken,
        pregnancyTestResult: testResult,
        stressLevel: _stressLevel.round(),
        drasticDietOrWeightChange: _drasticDiet,
        intenseExercise: _intenseExercise,
        emergencyContraceptive: _emergencyPill,
        severePelvicPain: _severePain,
      );

      final evaluation = TriageEngine.evaluate(input);

      // Simpan rekam triage ke database lokal Hive
      final record = TriageRecordModel(
        triageId: 'triage_${DateTime.now().millisecondsSinceEpoch}',
        testDate: DateTime.now(),
        daysDelayed: widget.daysDelayed,
        hasPregnancyRisk: hasRisk,
        pregnancyTestTaken: testTaken,
        pregnancyTestResult: testResult,
        stressLevel: _stressLevel.round(),
        drasticDietOrWeightChange: _drasticDiet,
        intenseExercise: _intenseExercise,
        emergencyContraceptive: _emergencyPill,
        severePelvicPain: _severePain,
        probableFactors: evaluation.factors.map((f) => f.title).toList(),
        recommendationSummary: evaluation.generalLifestyleAdvice.join('. '),
        primaryCitation: evaluation.factors.isNotEmpty ? evaluation.factors.first.citation : '',
        isRedFlag: evaluation.isRedFlag,
      );

      LocalDbService.instance.saveTriageRecord(record);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TriageResultScreen(result: evaluation, input: input),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Evaluasi Medis Keterlambatan', style: AppTypography.headlineMedium),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kuesioner Cepat 1 Menit',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Jawab 5 pertanyaan jujur untuk memetakan alasan biologis mengapa haid Anda terlambat ${widget.daysDelayed} hari.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Q1: AKTIVITAS SEKSUAL & TES KEHAMILAN
              _buildQuestionCard(
                number: '1',
                title: 'Aktivitas Intim & Tes Kehamilan',
                subtitle: 'Apakah ada potensi konsepsi dalam siklus aktif ini?',
                child: Column(
                  children: [
                    _buildRadioOption('none', 'Tidak ada hubungan intim tanpa proteksi'),
                    _buildRadioOption('not_tested', 'Ada hubungan intim, belum tes kehamilan'),
                    _buildRadioOption('tested_negative', 'Sudah tes urine (Test Pack) & hasil NEGATIF'),
                    _buildRadioOption('tested_positive', 'Sudah tes urine & hasil POSITIF'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Q2: TINGKAT STRES & BEBAN EMOSIONAL
              _buildQuestionCard(
                number: '2',
                title: 'Tingkat Stres 2 Minggu Terakhir',
                subtitle: 'Stres fisik/pikiran menekan hormon ovulasi di hipotalamus.',
                child: Column(
                  children: [
                    Slider(
                      value: _stressLevel,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _stressLevel = val);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1 (Rendah)', style: AppTypography.bodySmall),
                        Text(
                          _stressDescriptions[_stressLevel.round()]!,
                          style: AppTypography.labelLarge.copyWith(
                            color: _stressLevel >= 4 ? AppColors.warning : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text('5 (Sangat Tinggi)', style: AppTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Q3: DIET & BERAT BADAN
              _buildSwitchCard(
                number: '3',
                title: 'Perubahan Diet atau Penurunan Berat Badan',
                subtitle: 'Apakah Anda menjalani diet defisit kalori ekstrem atau berat badan turun mendadak?',
                value: _drasticDiet,
                onChanged: (val) => setState(() => _drasticDiet = val),
              ),

              const SizedBox(height: 16),

              // Q4: AKTIVITAS FISIK / OLAHRAGA INTENS
              _buildSwitchCard(
                number: '4',
                title: 'Aktivitas Fisik / Olahraga Berat',
                subtitle: 'Apakah ada latihan fisik intens/maraton/angkat beban berat yang tidak biasa?',
                value: _intenseExercise,
                onChanged: (val) => setState(() => _intenseExercise = val),
              ),

              const SizedBox(height: 16),

              // Q5: KONTRASEPSI DARURAT ATAU OBAT
              _buildSwitchCard(
                number: '5',
                title: 'Konsumsi Pil Darurat atau Obat Tertentu',
                subtitle: 'Apakah mengonsumsi morning-after pill, obat kortikosteroid, atau antidepresan?',
                value: _emergencyPill,
                onChanged: (val) => setState(() => _emergencyPill = val),
              ),

              const SizedBox(height: 16),

              // SKRINING RED FLAG (NYERI HEBAT)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _severePain ? AppColors.redFlag : AppColors.border,
                    width: _severePain ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.emergency_outlined, color: AppColors.redFlag, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Skrining Tanda Bahaya (Red Flag)', style: AppTypography.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Apakah Anda mengalami nyeri perut bawah yang tajam/hebat mendadak atau demam tinggi?',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _severePain,
                      activeTrackColor: AppColors.redFlag,
                      activeThumbColor: Colors.white,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _severePain = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // TOMBOL EVALUASI SEKARANG
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTriage,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Evaluasi Alasan Medis Sekarang'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required String number,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: AppTypography.badgeText.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTypography.titleMedium)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.bodySmall),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioOption(String key, String label) {
    final isSelected = _pregnancyStatus == key;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _pregnancyStatus = key);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 6 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required String number,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: AppTypography.badgeText.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }
}
