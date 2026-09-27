import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/database/models/daily_entry_model.dart';
import '../../../core/services/cycle_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Modal Bottom Sheet Quick-Log 3-Detik Lunara
/// Dirancang untuk pencatatan kilat tanpa membebani pengguna.
class QuickLogSheet extends StatefulWidget {
  final DateTime? initialDate;
  final VoidCallback? onSaved;

  const QuickLogSheet({
    super.key,
    this.initialDate,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    DateTime? date,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickLogSheet(
        initialDate: date,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<QuickLogSheet> {
  late DateTime _selectedDate;
  String _selectedFlow = 'none';
  String _selectedMood = 'calm';
  final Set<String> _selectedSymptoms = {};
  bool _hasIntimacy = false;
  bool? _usedProtection; // null = tidak spesifik, true = dengan pengaman, false = tanpa pengaman
  bool _isLoading = false;
  bool _hasExistingEntry = false;

  final List<Map<String, String>> _flowOptions = [
    {'key': 'none', 'label': 'Tidak Ada', 'icon': '⚪'},
    {'key': 'spotting', 'label': 'Flek', 'icon': '🌸'},
    {'key': 'light', 'label': 'Ringan', 'icon': '💧'},
    {'key': 'medium', 'label': 'Sedang', 'icon': '🩸'},
    {'key': 'heavy', 'label': 'Banyak', 'icon': '🌊'},
  ];

  final List<Map<String, String>> _moodOptions = [
    {'key': 'happy', 'label': 'Senang', 'emoji': '😊'},
    {'key': 'calm', 'label': 'Tenang', 'emoji': '🌿'},
    {'key': 'tired', 'label': 'Lelah', 'emoji': '😴'},
    {'key': 'anxious', 'label': 'Cemas', 'emoji': '🌧️'},
    {'key': 'irritable', 'label': 'Sensitif', 'emoji': '⚡'},
  ];

  final List<Map<String, String>> _symptomOptions = [
    {'key': 'cramps', 'label': 'Kram Perut'},
    {'key': 'headache', 'label': 'Sakit Kepala'},
    {'key': 'bloating', 'label': 'Kembung'},
    {'key': 'backache', 'label': 'Pegal Pinggang'},
    {'key': 'tender_breasts', 'label': 'Payudara Nyeri'},
    {'key': 'acne', 'label': 'Jerawat'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadExistingEntry();
  }

  void _loadExistingEntry() {
    final existing = LocalDbService.instance.getEntryForDate(_selectedDate);
    _hasExistingEntry = existing != null;
    if (existing != null) {
      _selectedFlow = existing.flowIntensity;
      _selectedMood = existing.mood;
      _selectedSymptoms.clear();
      _selectedSymptoms.addAll(existing.symptoms);
      _hasIntimacy = existing.hasIntimacy;
      _usedProtection = existing.usedProtection;
    } else {
      _selectedFlow = 'none';
      _selectedMood = 'calm';
      _selectedSymptoms.clear();
      _hasIntimacy = false;
      _usedProtection = null;
    }
  }

  Future<void> _confirmDeleteEntry() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.redFlagLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.redFlag, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Catatan?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Seluruh data gejala, aliran, mood, dan keintiman pada tanggal ini akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redFlag,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await LocalDbService.instance.deleteDailyEntryForDate(_selectedDate);
        if (mounted) {
          Navigator.pop(context);
          widget.onSaved?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Catatan tanggal ini berhasil dihapus.'),
                ],
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      setState(() {
        _selectedDate = picked;
        _loadExistingEntry();
      });
    }
  }

  Future<void> _saveEntry() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final activeCycle = LocalDbService.instance.getActiveCycle();
      final cycleId = activeCycle?.cycleId ?? 'cycle_general';
      final entryId = 'entry_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}';

      final entry = DailyEntryModel(
        entryId: entryId,
        cycleId: cycleId,
        entryDate: _selectedDate,
        flowIntensity: _selectedFlow,
        mood: _selectedMood,
        symptoms: _selectedSymptoms.toList(),
        hasIntimacy: _hasIntimacy,
        usedProtection: _hasIntimacy ? _usedProtection : null,
      );

      await LocalDbService.instance.saveDailyEntry(entry);

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Catatan harian berhasil disimpan!'),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final formattedDate = dateFormat.format(_selectedDate);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar Drag
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header & Pengubah Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Catat Hari Ini', style: AppTypography.headlineMedium),
                    const SizedBox(height: 2),
                    Text(formattedDate, style: AppTypography.bodySmall),
                  ],
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Ganti Hari',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.primary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 1. Aliran Darah Haid (Flow Intensity)
            Text('Kondisi Darah Haid', style: AppTypography.titleMedium),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _flowOptions.map((opt) {
                  final isSelected = _selectedFlow == opt['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${opt['icon']} ${opt['label']}'),
                      selected: isSelected,
                      selectedColor: AppColors.phaseMenstrualLight,
                      labelStyle: AppTypography.labelLarge.copyWith(
                        color: isSelected ? AppColors.onPhaseMenstrual : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.phaseMenstrual : AppColors.border,
                      ),
                      onSelected: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedFlow = opt['key']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // 2. Suasana Hati (Mood)
            Text('Suasana Hati (Mood)', style: AppTypography.titleMedium),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _moodOptions.map((opt) {
                  final isSelected = _selectedMood == opt['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${opt['emoji']} ${opt['label']}'),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: AppTypography.labelLarge.copyWith(
                        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      onSelected: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedMood = opt['key']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Gejala Tubuh (Symptoms)
            Text('Keluhan Fisik (Bisa Pilih Beberapa)', style: AppTypography.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _symptomOptions.map((opt) {
                final isSelected = _selectedSymptoms.contains(opt['key']);
                return FilterChip(
                  label: Text(opt['label']!),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primary,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  onSelected: (val) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (val) {
                        _selectedSymptoms.add(opt['key']!);
                      } else {
                        _selectedSymptoms.remove(opt['key']);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 4. Aktivitas Seksual & Intimasi
            Row(
              children: [
                Text('Aktivitas Seksual & Intim', style: AppTypography.titleMedium),
                const SizedBox(width: 8),
                Text('(Opsional)', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Tidak Ada')),
                    selected: !_hasIntimacy,
                    selectedColor: AppColors.surfaceVariant,
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: !_hasIntimacy ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: !_hasIntimacy ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(color: !_hasIntimacy ? AppColors.textSecondary : AppColors.border),
                    onSelected: (val) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _hasIntimacy = false;
                        _usedProtection = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('🛡️ Pengaman')),
                    selected: _hasIntimacy && _usedProtection == true,
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: _hasIntimacy && _usedProtection == true ? AppColors.primaryDark : AppColors.textSecondary,
                      fontWeight: _hasIntimacy && _usedProtection == true ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: _hasIntimacy && _usedProtection == true ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (val) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _hasIntimacy = true;
                        _usedProtection = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('❤️ Tanpa')),
                    selected: _hasIntimacy && _usedProtection == false,
                    selectedColor: AppColors.intimacyLight,
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: _hasIntimacy && _usedProtection == false ? AppColors.intimacyAccent : AppColors.textSecondary,
                      fontWeight: _hasIntimacy && _usedProtection == false ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: _hasIntimacy && _usedProtection == false ? AppColors.intimacyAccent : AppColors.border,
                    ),
                    onSelected: (val) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _hasIntimacy = true;
                        _usedProtection = false;
                      });
                    },
                  ),
                ),
              ],
            ),

            if (_hasIntimacy && _usedProtection != null) ...[
              const SizedBox(height: 12),
              _buildIntimacyRecommendationCard(),
            ],

            const SizedBox(height: 28),

            // Tombol Simpan Kilat
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEntry,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan Catatan (< 3 Detik)'),
              ),
            ),
            if (_hasExistingEntry) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.redFlag,
                    side: const BorderSide(color: AppColors.redFlag, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Hapus Catatan Hari Ini', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: _isLoading ? null : _confirmDeleteEntry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntimacyRecommendationCard() {
    final cycles = LocalDbService.instance.getAllCycles();
    final config = LocalDbService.instance.getConfig();
    final matchedCycle = CycleEngine.findCycleForDate(_selectedDate, cycles);
    final avgCycleLength = CycleEngine.calculateAverageCycleLength(cycles).round();
    final cycleStartDate = matchedCycle?.startDate ??
        (cycles.isNotEmpty ? cycles.last.startDate : _selectedDate);
    final cycleLength = (matchedCycle != null && matchedCycle.cycleLengthDays > 0)
        ? matchedCycle.cycleLengthDays
        : (avgCycleLength > 0 ? avgCycleLength : 28);

    final isFertile = CycleEngine.isDateInFertileWindow(_selectedDate, cycleStartDate, cycleLength);
    final analysis = CycleEngine.getIntimacyConceptionAnalysis(
      intimacyDate: _selectedDate,
      lastPeriodStartDate: cycleStartDate,
      cycleLength: cycleLength,
      hasProtection: _usedProtection == true,
      isFertileWindow: isFertile,
      appGoal: config.appGoal,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: analysis.isHighConceptionRisk
            ? AppColors.intimacyLight
            : analysis.badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: analysis.isHighConceptionRisk
              ? AppColors.intimacyAccent
              : analysis.badgeColor.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: analysis.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  analysis.statusLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: analysis.badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (analysis.timingContext.isNotEmpty)
                Expanded(
                  child: Text(
                    analysis.timingContext,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            analysis.actionableAdvice,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.clean_hands_rounded, size: 14, color: AppColors.phaseFollicular),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  analysis.hygieneTip,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
