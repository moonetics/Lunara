import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/database/models/cycle_model.dart';
import '../../../core/database/models/daily_entry_model.dart';
import '../../../core/services/cycle_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../quick_log/presentation/quick_log_sheet.dart';
import '../../tracker/state/cycle_notifier.dart';
import '../../dashboard/presentation/cycle_insights_screen.dart';
import '../../../core/database/models/app_config_model.dart';
import '../../../core/widgets/medical_term_bottom_sheet.dart';
import 'phase_explanation_sheet.dart';

/// Layar Kalender Siklus Bulanan Lunara (Visual Fase, Jeda Bolong & Edit Retroaktif)
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    LocalDbService.instance.configNotifier.addListener(_onConfigChanged);
  }

  void _onConfigChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    LocalDbService.instance.configNotifier.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _previousMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  /// Menampilkan dialog penambahan rentang data haid lampau (Mendukung lintas bulan)
  Future<void> _addHistoricalRange([DateTime? defaultDate]) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final initialStart = defaultDate ?? _selectedMonth;
    final initialEnd = initialStart.add(const Duration(days: 4));

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(now) ? now.subtract(const Duration(days: 4)) : initialStart,
        end: initialEnd.isAfter(now) ? now : initialEnd,
      ),
      helpText: 'PILIH RENTANG TANGGAL HAID (MULAI - SELESAI)',
      saveText: 'SIMPAN SIKLUS',
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

    if (pickedRange != null) {
      await LocalDbService.instance.addHistoricalCycle(pickedRange.start, pickedRange.end);
      await ref.read(cycleProvider.notifier).loadCycles();
      if (!mounted) return;
      final dateFormat = DateFormat('d MMM yyyy', 'id_ID');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('Riwayat haid ${dateFormat.format(pickedRange.start)} - ${dateFormat.format(pickedRange.end)} berhasil disimpan.'),
        ),
      );
      setState(() {});
    }
  }

  /// Menampilkan aksi saat tanggal kalender diklik (Decision-First Sheet)
  void _onDateTapped(DateTime date, List<CycleModel> cycles) {
    HapticFeedback.selectionClick();
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final entry = LocalDbService.instance.getEntryForDate(date);
    final config = LocalDbService.instance.getConfig();
    final matchedCycle = _findCycleForDate(date, cycles);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Date Header with accessible Close Button (min 48dp touch target)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dateFormat.format(date),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    padding: const EdgeInsets.all(12),
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Level 1: Hero Decision Card
              _buildDecisionFirstHeroCard(
                context: ctx,
                date: date,
                cycles: cycles,
                config: config,
                entry: entry,
              ),
              const SizedBox(height: 16),

              // 4. Catatan Intimasi / Mood saat ini (jika ada)
              if (entry != null && (entry.hasIntimacy || entry.symptoms.isNotEmpty)) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.hasIntimacy ? Icons.favorite_rounded : Icons.notes_rounded,
                        color: entry.hasIntimacy ? AppColors.intimacyAccent : AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.hasIntimacy
                              ? 'Intimasi: ${entry.usedProtection == true ? "Dengan Pengaman" : "Tanpa Pengaman"} • Mood: ${entry.mood}'
                              : 'Mood: ${entry.mood}${entry.symptoms.isNotEmpty ? " • Gejala: ${entry.symptoms.join(', ')}" : ""}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 5. Level 2: Primary Action Button (min 50dp height, thumb-friendly)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: Icon(
                    entry != null ? Icons.edit_note_rounded : Icons.favorite_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    entry != null ? 'Edit Catatan Tanggal Ini' : 'Catat Gejala, Mood & Intimasi',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    QuickLogSheet.show(
                      context,
                      date: date,
                      onSaved: () => setState(() {}),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // 6. Level 3: Secondary Actions Group
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.water_drop_outlined, size: 16, color: AppColors.phaseMenstrual),
                      label: Text(
                        'Haid Lampau',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.phaseMenstrual,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        side: BorderSide(color: AppColors.phaseMenstrual.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _addHistoricalRange(date);
                      },
                    ),
                  ),
                  if (entry != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.redFlag),
                        label: Text(
                          'Hapus Log',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.redFlag,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          side: BorderSide(color: AppColors.redFlag.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await LocalDbService.instance.deleteDailyEntryForDate(date);
                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: const Text('Catatan harian berhasil dihapus.'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              if (matchedCycle != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.settings_outlined, size: 16, color: AppColors.textSecondary),
                    label: Text(
                      'Kelola Siklus Haid Ini (${DateFormat("d MMM yyyy", "id_ID").format(matchedCycle.startDate)})',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCycleActionSheet(matchedCycle);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan modal edit atau hapus siklus retroaktif
  void _showCycleActionSheet(CycleModel cycle) {
    HapticFeedback.lightImpact();
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.phaseMenstrualLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: AppColors.phaseMenstrual),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Siklus Menstruasi',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Mulai: ${dateFormat.format(cycle.startDate)}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
              title: const Text('Ubah Tanggal Mulai'),
              subtitle: Text('Sesuaikan tanggal HPHT awal siklus ini'),
              onTap: () async {
                Navigator.pop(ctx);
                final newDate = await showDatePicker(
                  context: context,
                  initialDate: cycle.startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (newDate != null) {
                  cycle.startDate = newDate;
                  await LocalDbService.instance.saveCycle(cycle);
                  await ref.read(cycleProvider.notifier).loadCycles();
                  setState(() {});
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.redFlag),
              title: Text('Hapus Catatan Siklus Ini', style: TextStyle(color: AppColors.redFlag)),
              subtitle: Text('Rata-rata siklus akan otomatis dikalkulasi ulang'),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Hapus Siklus?'),
                    content: Text('Catatan haid tanggal ${dateFormat.format(cycle.startDate)} akan dihapus.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Batal')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.redFlag),
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await LocalDbService.instance.deleteCycle(cycle.cycleId);
                  await ref.read(cycleProvider.notifier).loadCycles();
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = LocalDbService.instance.getConfig();
    final cycles = LocalDbService.instance.getAllCycles();
    final dailyEntries = LocalDbService.instance.getAllDailyEntries();
    final monthTitle = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    // Cek apakah bulan yang dipilih memiliki catatan siklus atau jeda outlier
    final cyclesInMonth = cycles.where((c) {
      final startsInMonth = c.startDate.year == _selectedMonth.year && c.startDate.month == _selectedMonth.month;
      final overlapsMonth = c.endDate != null &&
          !c.startDate.isAfter(lastDayOfMonth) &&
          !c.endDate!.isBefore(firstDayOfMonth);
      return startsInMonth || overlapsMonth;
    }).toList();

    // Catatan harian di bulan ini (termasuk seks & gejala)
    final List<DailyEntryModel> dailyEntriesInMonth = dailyEntries.where((e) {
      return e.entryDate.year == _selectedMonth.year && e.entryDate.month == _selectedMonth.month;
    }).toList();

    // Deteksi jeda bolong jika bulan ini kosong dan ada siklus sebelum & sesudahnya
    final hasCycleBefore = cycles.any((c) => c.startDate.isBefore(_selectedMonth));
    final isGapMonth = cyclesInMonth.isEmpty && hasCycleBefore && _selectedMonth.isBefore(DateTime.now());

    // Satukan peristiwa bulan ini ke dalam daftar kronologis terpadu
    final activityItems = <_CalendarActivityItem>[];

    for (final cycle in cyclesInMonth) {
      activityItems.add(
        _CalendarActivityItem(
          date: cycle.startDate,
          widget: Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.phaseMenstrualLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.water_drop_rounded, color: AppColors.phaseMenstrual, size: 20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.phaseMenstrualLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Haid',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.phaseMenstrual,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cycle.endDate != null
                          ? '${DateFormat("d MMM", "id_ID").format(cycle.startDate)} - ${DateFormat("d MMM yyyy", "id_ID").format(cycle.endDate!)}'
                          : DateFormat('dd MMMM yyyy', 'id_ID').format(cycle.startDate),
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'Durasi haid: ${cycle.periodDurationDays} hari • ${cycle.isOngoing ? "Sedang berjalan" : "${cycle.cycleLengthDays} hari siklus"}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
              trailing: const Icon(Icons.more_vert_rounded, color: AppColors.textTertiary),
              onTap: () => _showCycleActionSheet(cycle),
            ),
          ),
        ),
      );
    }

    final avgCycleLength = CycleEngine.calculateAverageCycleLength(cycles).round();

    for (final entry in dailyEntriesInMonth) {
      if (entry.hasIntimacy) {
        final hasProtection = entry.usedProtection == true;
        final matchedCycle = _findCycleForDate(entry.entryDate, cycles);
        final cycleStartDate = matchedCycle?.startDate ??
            (cycles.isNotEmpty ? cycles.last.startDate : entry.entryDate);
        final cycleLength = (matchedCycle != null && matchedCycle.cycleLengthDays > 0)
            ? matchedCycle.cycleLengthDays
            : (avgCycleLength > 0 ? avgCycleLength : 28);

        final phaseColor = _getColorForDate(entry.entryDate, cycles);
        final isFertile = phaseColor == AppColors.phaseOvulation ||
            CycleEngine.isDateInFertileWindow(entry.entryDate, cycleStartDate, cycleLength);

        final config = LocalDbService.instance.getConfig();
        final intimacyAnalysis = CycleEngine.getIntimacyConceptionAnalysis(
          intimacyDate: entry.entryDate,
          lastPeriodStartDate: cycleStartDate,
          cycleLength: cycleLength,
          hasProtection: hasProtection,
          isFertileWindow: isFertile,
          appGoal: config.appGoal,
        );

        activityItems.add(
          _CalendarActivityItem(
            date: entry.entryDate,
            widget: Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.intimacyLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.favorite_rounded, color: AppColors.intimacyAccent, size: 20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: intimacyAnalysis.badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        intimacyAnalysis.statusLabel,
                        style: AppTypography.bodySmall.copyWith(
                          color: intimacyAnalysis.badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('dd MMMM yyyy', 'id_ID').format(entry.entryDate),
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          hasProtection ? Icons.shield_rounded : Icons.favorite_border_rounded,
                          size: 13,
                          color: hasProtection ? AppColors.phaseFollicular : AppColors.intimacyAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasProtection ? 'Dengan Pengaman (Terproteksi)' : 'Tanpa Pengaman',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: hasProtection ? AppColors.phaseFollicular : AppColors.intimacyAccent,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      intimacyAnalysis.description,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    if (entry.flowIntensity != 'none' || entry.symptoms.isNotEmpty || (entry.mood != 'calm' && entry.mood.isNotEmpty)) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (entry.flowIntensity != 'none')
                            _buildMiniTag(
                              _getFlowLabel(entry.flowIntensity),
                              AppColors.phaseMenstrual,
                            ),
                          if (entry.mood.isNotEmpty)
                            _buildMiniTag(
                              _getMoodLabel(entry.mood),
                              AppColors.textSecondary,
                            ),
                          if (entry.symptoms.isNotEmpty)
                            _buildMiniTag(
                              entry.symptoms.map((s) => _getSymptomLabel(s)).join(', '),
                              AppColors.primary,
                            ),
                        ],
                      ),
                    ],
                    if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Catatan: "${entry.notes}"',
                        style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                onTap: () => _showIntimacyDetailSheet(context, entry, intimacyAnalysis, cycles),
              ),
            ),
          ),
        );
      } else {
        final hasFlow = entry.flowIntensity != 'none';
        final hasSymptoms = entry.symptoms.isNotEmpty;
        final hasMood = entry.mood.isNotEmpty;
        final hasNotes = entry.notes != null && entry.notes!.trim().isNotEmpty;

        if (hasFlow || hasSymptoms || hasMood || hasNotes) {
          // Gejala atau mood harian tanpa keintiman
          activityItems.add(
            _CalendarActivityItem(
              date: entry.entryDate,
              widget: Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasFlow ? AppColors.phaseMenstrualLight : AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasFlow ? Icons.water_drop_rounded : Icons.edit_note_rounded,
                      color: hasFlow ? AppColors.phaseMenstrual : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (hasFlow ? AppColors.phaseMenstrual : AppColors.primary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hasFlow ? _getFlowLabel(entry.flowIntensity) : 'Log Harian',
                          style: AppTypography.bodySmall.copyWith(
                            color: hasFlow ? AppColors.phaseMenstrual : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          DateFormat('dd MMMM yyyy', 'id_ID').format(entry.entryDate),
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildMiniTag(_getMoodLabel(entry.mood), AppColors.textSecondary),
                          if (hasSymptoms)
                            _buildMiniTag(
                              entry.symptoms.map((s) => _getSymptomLabel(s)).join(', '),
                              AppColors.primary,
                            ),
                        ],
                      ),
                      if (hasNotes) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Catatan: "${entry.notes}"',
                          style: AppTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.edit_rounded, size: 16, color: AppColors.textTertiary),
                  onTap: () => _onDateTapped(entry.entryDate, cycles),
                ),
              ),
            ),
          );
        }
      }
    }

    // Urutkan seluruh aktivitas bulan ini dari tanggal terbaru ke terlama
    activityItems.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kalender Siklus',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_graph_rounded),
            tooltip: 'Tren & Statistik Siklus',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CycleInsightsScreen()),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ==================== 1. KONTROL BULAN (NAVIGASI) ====================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  onPressed: _previousMonth,
                ),
                Text(
                  monthTitle,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Banner Panduan Waktu Intimasi Berdasarkan Mode Pengguna
          if (config.isPregnancyProgram || config.isNaturalContraception) ...[
            _buildModeGuidanceBanner(config),
            const SizedBox(height: 14),
          ],

          // ==================== 2. GRID KALENDER BULANAN ====================
          _buildCalendarGrid(cycles, config),
          const SizedBox(height: 16),

          // ==================== 3. PENANDA JEDA BOLONG (JIKA ADA) ====================
          if (isGapMonth) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.phaseFollicularLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.phaseFollicular.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, color: AppColors.phaseFollicular),
                      const SizedBox(width: 8),
                      Text(
                        'Bulan Terlewat (Jeda Bolong)',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.phaseFollicular,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tidak ada catatan haid pada $monthTitle. Smart Gap Handling otomatis menyaring jeda ini agar rata-rata prediksi tetap akurat.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.phaseFollicular,
                        side: BorderSide(color: AppColors.phaseFollicular.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _addHistoricalRange(_selectedMonth),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('Tambah Riwayat Haid $monthTitle'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ==================== 5. AKTIVITAS & RIWAYAT BULAN INI ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivitas & Riwayat Bulan Ini',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Riwayat haid, keintiman & catatan harian',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _addHistoricalRange(_selectedMonth),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tambah Haid'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (activityItems.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.event_note_rounded, size: 36, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada catatan aktivitas di $monthTitle',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ketuk tanggal di kalender untuk mencatat haid, gejala, atau keintiman.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            )
          else
            ...activityItems.map((item) => item.widget),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getFlowLabel(String flow) {
    switch (flow) {
      case 'spotting': return '🌸 Flek';
      case 'light': return '💧 Ringan';
      case 'medium': return '🩸 Sedang';
      case 'heavy': return '🌊 Banyak';
      default: return '⚪ Tidak Ada';
    }
  }

  String _getMoodLabel(String mood) {
    switch (mood) {
      case 'happy': return '😊 Senang';
      case 'calm': return '🌿 Tenang';
      case 'tired': return '😴 Lelah';
      case 'anxious': return '🌧️ Cemas';
      case 'irritable': return '⚡ Sensitif';
      default: return mood;
    }
  }

  String _getSymptomLabel(String symptom) {
    switch (symptom) {
      case 'cramps': return 'Kram Perut';
      case 'headache': return 'Sakit Kepala';
      case 'bloating': return 'Kembung';
      case 'backache': return 'Pegal Pinggang';
      case 'tender_breasts': return 'Payudara Nyeri';
      case 'acne': return 'Jerawat';
      case 'nausea': return 'Mual';
      case 'fatigue': return 'Kelelahan';
      default: return symptom;
    }
  }

  Widget _buildMiniTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ExplainedPhase phase) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          PhaseExplanationSheet.show(context, phase: phase);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.info_outline_rounded, size: 10.5, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntimacyLegendItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          PhaseExplanationSheet.show(context, phase: ExplainedPhase.intimacy);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.intimacyAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.intimacyAccent.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, size: 10, color: AppColors.intimacyAccent),
              const SizedBox(width: 4),
              Text(
                'Intim',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.info_outline_rounded, size: 10.5, color: AppColors.intimacyAccent),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner Panduan Singkat Sesuai Mode Pengguna (Promil vs Tunda Hamil)
  Widget _buildModeGuidanceBanner(AppConfigModel config) {
    if (config.isPregnancyProgram) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.intimacyLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.intimacyAccent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.intimacyAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekomendasi Waktu Promil (Wilcox NEJM & ASRM)',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tanggal bertanda ⭐ (H-2 s/d Day 0) adalah Hari Emas Konsepsi (~36%). Ketuk tanggal untuk detail peluang & ritme hubungan intim.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onPrimaryContainer.withValues(alpha: 0.85),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (config.isNaturalContraception) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.phaseOvulationLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.phaseOvulation.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.phaseOvulation, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panduan Pencegahan Kehamilan (FABM & ACOG)',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPhaseOvulation,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tanggal ungu = Zona merah risiko tinggi (wajib kondom). Tanggal kuning/putih pasca-ovulasi = Zona aman fisiologis (0%). Ketuk tanggal untuk detail.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onPhaseOvulation.withValues(alpha: 0.85),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGoldenLegendItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          MedicalTermHelper.show(context, 'ttc_wilcox');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.intimacyLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.intimacyAccent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 11, color: AppColors.intimacyAccent),
              const SizedBox(width: 4),
              Text(
                'Hari Emas',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                  color: AppColors.intimacyAccent,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.info_outline_rounded, size: 10.5, color: AppColors.intimacyAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafeLegendItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          MedicalTermHelper.show(context, 'fabm');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.phaseFollicularLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.phaseFollicular.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 11, color: AppColors.phaseFollicular),
              const SizedBox(width: 4),
              Text(
                'Aman (0%)',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                  color: AppColors.phaseFollicular,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.info_outline_rounded, size: 10.5, color: AppColors.phaseFollicular),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(List<CycleModel> cycles, AppConfigModel config) {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday; // 1 = Monday
    final weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Nama Hari
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Grid Tanggal
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 baris x 7 hari
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayOffset + 1);
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              final entry = LocalDbService.instance.getEntryForDate(date);
              final hasIntimacy = entry?.hasIntimacy == true;

              // Tentukan fase hari ini berdasarkan siklus terdekat
              final phaseColor = _getColorForDate(date, cycles);
              final isPromil = config.isPregnancyProgram;
              final isContraception = config.isNaturalContraception;
              final matchedCycle = _findCycleForDate(date, cycles);
              final isGolden = (isPromil && matchedCycle != null)
                  ? CycleEngine.getConceptionTimingGuidance(
                      targetDate: date,
                      lastPeriodStartDate: matchedCycle.startDate,
                      cycleLength: matchedCycle.cycleLengthDays > 0 ? matchedCycle.cycleLengthDays : 28,
                      appGoal: config.appGoal,
                    ).isGoldenConceptionDay
                  : false;
              final isSafeLuteal = (isContraception && phaseColor == AppColors.phaseLuteal);

              Color cellBgColor = Colors.transparent;
              Border? cellBorder;

              if (isGolden) {
                cellBgColor = AppColors.intimacyLight;
                cellBorder = Border.all(color: AppColors.intimacyAccent, width: 1.5);
              } else if (isSafeLuteal) {
                cellBgColor = AppColors.phaseFollicularLight;
                cellBorder = Border.all(color: AppColors.phaseFollicular, width: 1.5);
              } else if (phaseColor != null) {
                cellBgColor = phaseColor.withValues(alpha: 0.2);
                cellBorder = Border.all(color: phaseColor.withValues(alpha: 0.8), width: 1.5);
              }

              if (isToday) {
                cellBorder = Border.all(color: AppColors.primary, width: 2);
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _onDateTapped(date, cycles),
                child: Container(
                  decoration: BoxDecoration(
                    color: cellBgColor,
                    shape: BoxShape.circle,
                    border: cellBorder,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${dayOffset + 1}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: isToday || phaseColor != null || isGolden || isSafeLuteal ? FontWeight.w700 : FontWeight.w500,
                              color: isGolden
                                  ? AppColors.intimacyAccent
                                  : (isSafeLuteal
                                      ? AppColors.phaseFollicular
                                      : (phaseColor ?? (isToday ? AppColors.primary : AppColors.textPrimary))),
                              fontSize: 13,
                            ),
                          ),
                          if (isGolden) ...[
                            const SizedBox(width: 1),
                            const Icon(Icons.star_rounded, size: 10, color: AppColors.intimacyAccent),
                          ] else if (isSafeLuteal) ...[
                            const SizedBox(width: 1),
                            const Icon(Icons.shield_outlined, size: 9, color: AppColors.phaseFollicular),
                          ],
                        ],
                      ),
                      if (hasIntimacy)
                        const Icon(Icons.favorite_rounded, size: 8, color: AppColors.intimacyAccent),
                    ],
                  ),
                ),
              );
            },
          ),

          // ==================== INTERNAL DIVIDER & PANDUAN FASE TERPADU (1 BOX) ====================
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: AppColors.surfaceVariant),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PANDUAN FASE SIKLUS',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 9.5,
                  letterSpacing: 0.6,
                  color: AppColors.textTertiary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ketuk untuk edukasi hormon',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 9.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.touch_app_rounded, size: 11, color: AppColors.primary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildLegendItem('Haid', AppColors.phaseMenstrual, ExplainedPhase.menstrual),
                const SizedBox(width: 6),
                _buildLegendItem('Folikular', AppColors.phaseFollicular, ExplainedPhase.follicular),
                const SizedBox(width: 6),
                _buildLegendItem('Masa Subur', AppColors.phaseOvulation, ExplainedPhase.ovulation),
                if (config.isPregnancyProgram) ...[
                  const SizedBox(width: 6),
                  _buildGoldenLegendItem(),
                ],
                if (config.isNaturalContraception) ...[
                  const SizedBox(width: 6),
                  _buildSafeLegendItem(),
                ],
                const SizedBox(width: 6),
                _buildLegendItem('Luteal (PMS)', AppColors.phaseLuteal, ExplainedPhase.luteal),
                const SizedBox(width: 6),
                _buildIntimacyLegendItem(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mencari siklus yang aktif atau menaungi tanggal tertentu
  CycleModel? _findCycleForDate(DateTime date, List<CycleModel> cycles) {
    return CycleEngine.findCycleForDate(date, cycles);
  }

  Color? _getColorForDate(DateTime date, List<CycleModel> cycles) {
    final cycle = CycleEngine.findCycleForDate(date, cycles);
    if (cycle == null) return null;

    // 1. Cek rentang tanggal eksplisit (Cross-Month Continual Range)
    if (cycle.endDate != null) {
      final start = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
      final end = DateTime(cycle.endDate!.year, cycle.endDate!.month, cycle.endDate!.day);
      if (!date.isBefore(start) && !date.isAfter(end)) {
        return AppColors.phaseMenstrual;
      }
    }

    // 2. Cek selisih hari dari startDate
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
    final diff = normalizedDate.difference(normalizedStart).inDays;

    if (diff >= 0) {
      final cycleLength = cycle.cycleLengthDays > 0 ? cycle.cycleLengthDays : 28;
      // Jika siklus sedang berjalan (belum darah berhenti), proyeksikan durasi normal haid 5 hari
      final effectivePeriodDuration = (cycle.isOngoing || cycle.endDate == null)
          ? (cycle.periodDurationDays > 1 ? cycle.periodDurationDays : 5)
          : cycle.periodDurationDays;

      // Estimasi ovulasi dinamis fisiologis: selalu 14 hari sebelum haid berikutnya (ACOG & Guyton-Hall)
      final ovulationDay = (cycleLength - 14).clamp(10, cycleLength > 20 ? cycleLength - 10 : 14);
      final fertileStart = ovulationDay - 5;
      final fertileEnd = ovulationDay + 1;

      if (diff < effectivePeriodDuration) {
        return AppColors.phaseMenstrual; // Menstruasi
      } else if (diff >= effectivePeriodDuration && diff < fertileStart) {
        return AppColors.phaseFollicular; // Folikular
      } else if (diff >= fertileStart && diff <= fertileEnd) {
        return AppColors.phaseOvulation; // Ovulasi / Masa Subur Dinamis
      } else if (diff > fertileEnd && diff < cycleLength) {
        return AppColors.phaseLuteal; // Luteal (PMS) konstan ~14 hari
      }
    }
    return null;
  }

  Widget _buildDecisionFirstHeroCard({
    required BuildContext context,
    required DateTime date,
    required List<CycleModel> cycles,
    required AppConfigModel config,
    required DailyEntryModel? entry,
  }) {
    final phaseColor = _getColorForDate(date, cycles);
    final isPromil = config.isPregnancyProgram;
    final isContraception = config.isNaturalContraception;
    final cycle = _findCycleForDate(date, cycles);

    String badgeText;
    IconData badgeIcon;
    Color themeColor;
    Color lightBgColor;
    String headline;
    String clinicalAdvice;
    String reference;
    String termKey;

    if (cycle != null && isPromil) {
      final cycleLength = cycle.cycleLengthDays > 0 ? cycle.cycleLengthDays : 28;
      final guidance = CycleEngine.getConceptionTimingGuidance(
        targetDate: date,
        lastPeriodStartDate: cycle.startDate,
        cycleLength: cycleLength,
        appGoal: config.appGoal,
      );
      termKey = 'ttc_wilcox';

      if (guidance.isGoldenConceptionDay) {
        badgeText = 'HARI EMAS PROMIL (${guidance.probabilityPercentage.toStringAsFixed(0)}%)';
        badgeIcon = Icons.stars_rounded;
        themeColor = AppColors.intimacyAccent;
        lightBgColor = AppColors.intimacyLight;
        headline = 'Sangat Dianjurkan Berhubungan Intim';
        clinicalAdvice =
            'Puncak peluang konsepsi tertinggi (~${guidance.probabilityPercentage.toStringAsFixed(0)}%). ASRM merekomendasikan hubungan intim tiap 1–2 hari pada jendela ini untuk viabilitas sperma optimal.';
        reference = 'Wilcox et al. (NEJM) • ASRM Practice Committee';
      } else if (guidance.probabilityPercentage > 0) {
        badgeText = 'JENDELA SUBUR PROMIL (${guidance.probabilityPercentage.toStringAsFixed(0)}%)';
        badgeIcon = Icons.auto_awesome_rounded;
        themeColor = AppColors.phaseOvulation;
        lightBgColor = AppColors.phaseOvulationLight;
        headline = 'Waktu Konsepsi Efektif';
        clinicalAdvice =
            'Sperma dapat bertahan hingga 5 hari dalam lendir serviks yang ramah. Hubungan intim hari ini efektif mengawali jendela pembuahan.';
        reference = 'Wilcox et al. (NEJM) • ASRM Practice Committee';
      } else if (phaseColor == AppColors.phaseLuteal) {
        badgeText = 'FASE PASCA-OVULASI';
        badgeIcon = Icons.wb_sunny_outlined;
        themeColor = AppColors.phaseLuteal;
        lightBgColor = AppColors.phaseLutealLight;
        headline = 'Ovulasi Telah Usai • Masa Istirahat';
        clinicalAdvice =
            'Sel telur telah terdegenerasi. Masa pembuahan siklus ini telah usai. Pertahankan nutrisi sehat dan istirahat sambil menunggu evaluasi siklus.';
        reference = 'ACOG Practice Bulletin No. 197';
      } else if (phaseColor == AppColors.phaseMenstrual) {
        badgeText = 'FASE MENSTRUASI';
        badgeIcon = Icons.water_drop_rounded;
        themeColor = AppColors.phaseMenstrual;
        lightBgColor = AppColors.phaseMenstrualLight;
        headline = 'Hari Istirahat Menstruasi';
        clinicalAdvice =
            'Peluang hamil mendekati 0%. Tubuh sedang meluruhkan dinding rahim. Prioritaskan hidrasi dan asupan zat besi.';
        reference = 'POGI & WHO Clinical Care';
      } else {
        badgeText = 'FASE FOLIKULAR AWAL';
        badgeIcon = Icons.spa_rounded;
        themeColor = AppColors.phaseFollicular;
        lightBgColor = AppColors.phaseFollicularLight;
        headline = 'Pematangan Folikel Telur';
        clinicalAdvice =
            'Kadar estrogen mulai meningkat untuk mematangkan sel telur. Persiapkan tubuh dengan nutrisi antioksidan sebelum jendela subur.';
        reference = 'Guyton-Hall Medical Physiology';
      }
    } else if (cycle != null && isContraception) {
      final cycleLength = cycle.cycleLengthDays > 0 ? cycle.cycleLengthDays : 28;
      final guidance = CycleEngine.getConceptionTimingGuidance(
        targetDate: date,
        lastPeriodStartDate: cycle.startDate,
        cycleLength: cycleLength,
        appGoal: config.appGoal,
      );
      termKey = 'fabm';

      if (guidance.probabilityPercentage > 0 || phaseColor == AppColors.phaseOvulation) {
        badgeText = 'ZONA SUBUR (RISIKO TINGGI)';
        badgeIcon = Icons.warning_amber_rounded;
        themeColor = AppColors.phaseOvulation;
        lightBgColor = AppColors.phaseOvulationLight;
        headline = 'Gunakan Pengaman / Hindari Hubungan';
        clinicalAdvice =
            'Risiko konsepsi tinggi (~${guidance.probabilityPercentage.toStringAsFixed(0)}%). Sel telur dan lendir serviks sangat subur. Gunakan metode barier (kondom) bila berhubungan intim.';
        reference = 'WHO Medical Eligibility Criteria & ACOG FABM';
      } else if (phaseColor == AppColors.phaseLuteal) {
        badgeText = 'ZONA AMAN FISIOLOGIS (0%)';
        badgeIcon = Icons.shield_outlined;
        themeColor = AppColors.phaseFollicular;
        lightBgColor = AppColors.phaseFollicularLight;
        headline = 'Aman Tanpa Pengaman (Risiko 0%)';
        clinicalAdvice =
            'Sel telur telah mati (viabilitas 12–24 jam pasca-ovulasi) dan progesteron menebalkan lendir serviks. Hubungan intim tanpa pengaman memiliki risiko konsepsi nol.';
        reference = 'ACOG Practice Bulletin No. 197 & Guyton-Hall';
      } else if (phaseColor == AppColors.phaseMenstrual) {
        badgeText = 'FASE MENSTRUASI';
        badgeIcon = Icons.water_drop_rounded;
        themeColor = AppColors.phaseMenstrual;
        lightBgColor = AppColors.phaseMenstrualLight;
        headline = 'Risiko Sangat Rendah';
        clinicalAdvice =
            'Peluang konsepsi sangat rendah pada siklus reguler. Jaga kebersihan dan higienitas area reproduksi selama menstruasi.';
        reference = 'POGI & WHO Clinical Care';
      } else {
        badgeText = 'FASE PRA-OVULASI AWAL';
        badgeIcon = Icons.spa_rounded;
        themeColor = AppColors.phaseFollicular;
        lightBgColor = AppColors.phaseFollicularLight;
        headline = 'Waspadai Ovulasi Dini';
        clinicalAdvice =
            'Risiko konsepsi rendah namun sperma dapat bertahan hingga 5 hari jika ovulasi maju lebih cepat dari prediksi.';
        reference = 'WHO Family Planning Handbook';
      }
    } else {
      // General Health Tracking
      if (phaseColor == AppColors.phaseOvulation) {
        badgeText = 'STATUS FISIOLOGIS: OVULASI';
        badgeIcon = Icons.auto_awesome_rounded;
        themeColor = AppColors.phaseOvulation;
        lightBgColor = AppColors.phaseOvulationLight;
        headline = 'Puncak Masa Subur';
        clinicalAdvice =
            'Sel telur dilepaskan ke tuba falopi. Hormon LH dan estrogen mencapai puncaknya, energi dan daya tarik tubuh berada pada level tertinggi.';
        reference = 'Guyton-Hall Medical Physiology';
        termKey = 'ovulation_phase';
      } else if (phaseColor == AppColors.phaseMenstrual) {
        badgeText = 'STATUS FISIOLOGIS: MENSTRUASI';
        badgeIcon = Icons.water_drop_rounded;
        themeColor = AppColors.phaseMenstrual;
        lightBgColor = AppColors.phaseMenstrualLight;
        headline = 'Fase Menstruasi Aktif';
        clinicalAdvice =
            'Hormon estrogen dan progesteron berada pada titik terendah. Lapisan endometrium meluruh. Disarankan istirahat cukup dan nutrisi kaya zat besi.';
        reference = 'POGI & Guyton-Hall Physiology';
        termKey = 'dysmenorrhea';
      } else if (phaseColor == AppColors.phaseFollicular) {
        badgeText = 'STATUS FISIOLOGIS: FOLIKULAR';
        badgeIcon = Icons.spa_rounded;
        themeColor = AppColors.phaseFollicular;
        lightBgColor = AppColors.phaseFollicularLight;
        headline = 'Fase Folikular (Energi Meningkat)';
        clinicalAdvice =
            'Estrogen mulai diproduksi ovarium untuk membangun kembali dinding rahim. Suasana hati dan energi fisik cenderung meningkat optimal.';
        reference = 'Guyton-Hall Medical Physiology';
        termKey = 'follicular_phase';
      } else if (phaseColor == AppColors.phaseLuteal) {
        badgeText = 'STATUS FISIOLOGIS: LUTEAL';
        badgeIcon = Icons.wb_sunny_outlined;
        themeColor = AppColors.phaseLuteal;
        lightBgColor = AppColors.phaseLutealLight;
        headline = 'Fase Luteal (Menjelang Menstruasi)';
        clinicalAdvice =
            'Progesteron dominan menjaga ketebalan rahim. Jika sel telur tidak dibuahi, hormon akan turun memicu gejala pra-menstruasi (PMS).';
        reference = 'ACOG & Guyton-Hall Physiology';
        termKey = 'luteal_phase';
      } else {
        badgeText = 'STATUS KALENDER';
        badgeIcon = Icons.calendar_today_rounded;
        themeColor = AppColors.primary;
        lightBgColor = AppColors.primaryContainer;
        headline = 'Pencatatan Harian Siklus';
        clinicalAdvice =
            'Catat gejala fisik, mood, dan aktivitas intimasi untuk meningkatkan akurasi analisis siklus dan prediksi fase tubuh Anda.';
        reference = 'Lunara Cycle Engine';
        termKey = 'hpo_axis';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: themeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: themeColor,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.info_outline_rounded, size: 18, color: themeColor),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: const EdgeInsets.all(12),
                tooltip: 'Info Medis',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  MedicalTermHelper.show(context, termKey);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            clinicalAdvice,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 12, color: themeColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  reference,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showIntimacyDetailSheet(
    BuildContext context,
    DailyEntryModel entry,
    IntimacyAnalysis analysis,
    List<CycleModel> cycles,
  ) {
    HapticFeedback.selectionClick();
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: analysis.badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.favorite_rounded, color: analysis.badgeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: analysis.badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          analysis.statusLabel,
                          style: AppTypography.bodySmall.copyWith(
                            color: analysis.badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(entry.entryDate),
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (analysis.timingContext.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        analysis.timingContext,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (analysis.actionableAdvice.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: analysis.isHighConceptionRisk
                      ? AppColors.intimacyLight
                      : AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: analysis.isHighConceptionRisk ? AppColors.intimacyAccent : AppColors.primary,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          analysis.isHighConceptionRisk
                              ? Icons.warning_amber_rounded
                              : Icons.health_and_safety_rounded,
                          size: 18,
                          color: analysis.isHighConceptionRisk ? AppColors.intimacyAccent : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Panduan Tindakan Klinis & Kontrasepsi',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: analysis.isHighConceptionRisk ? AppColors.intimacyAccent : AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      analysis.actionableAdvice,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (analysis.hygieneTip.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.phaseFollicularLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.phaseFollicular.withValues(alpha: 0.5), width: 0.8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.clean_hands_rounded, size: 18, color: AppColors.phaseFollicular),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Higienitas Reproduksi (ACOG / POGI)',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPhaseFollicular,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            analysis.hygieneTip,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.35,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Ubah Catatan'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      QuickLogSheet.show(
                        context,
                        date: entry.entryDate,
                        onSaved: () => setState(() {}),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarActivityItem {
  final DateTime date;
  final Widget widget;

  const _CalendarActivityItem({
    required this.date,
    required this.widget,
  });
}
