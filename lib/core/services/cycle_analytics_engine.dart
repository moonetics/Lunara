import 'package:flutter/material.dart';
import '../constants/medical_constants.dart';
import '../database/models/cycle_model.dart';
import '../database/models/daily_entry_model.dart';
import '../theme/app_colors.dart';

/// Titik data riwayat siklus untuk grafik batang
class CycleHistoryPoint {
  final String cycleId;
  final DateTime startDate;
  final DateTime? endDate;
  final int cycleLengthDays;
  final int periodDurationDays;
  final String label;
  final bool isOngoing;
  final bool isOutlier;

  const CycleHistoryPoint({
    required this.cycleId,
    required this.startDate,
    this.endDate,
    required this.cycleLengthDays,
    required this.periodDurationDays,
    required this.label,
    required this.isOngoing,
    required this.isOutlier,
  });
}

/// Frekuensi kemunculan gejala fisik
class SymptomFrequencyItem {
  final String symptomKey;
  final String label;
  final int occurrenceCount;
  final double percentage; // 0.0 - 100.0

  const SymptomFrequencyItem({
    required this.symptomKey,
    required this.label,
    required this.occurrenceCount,
    required this.percentage,
  });
}

/// Distribusi suasana hati (mood)
class MoodFrequencyItem {
  final String moodKey;
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const MoodFrequencyItem({
    required this.moodKey,
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

/// Hasil komprehensif analisis statistik siklus
class CycleAnalyticsResult {
  final double averageCycleLength;
  final int shortestCycleLength;
  final int longestCycleLength;
  final int variabilityDays;
  final String regularityCode;
  final String regularityTitle;
  final String regularityDescription;
  final Color regularityColor;
  final Color regularityBgColor;
  final double averagePeriodDuration;
  final int totalCyclesRecorded;
  final List<CycleHistoryPoint> cycleHistory;
  final List<SymptomFrequencyItem> topSymptoms;
  final List<MoodFrequencyItem> topMoods;
  final int totalIntimacyDays;
  final int protectedIntimacyDays;
  final int unprotectedIntimacyDays;
  final int totalEntriesLogged;
  final int ignoredGapCyclesCount;
  final bool hasCycleData;
  final bool hasPeriodData;

  const CycleAnalyticsResult({
    required this.averageCycleLength,
    required this.shortestCycleLength,
    required this.longestCycleLength,
    required this.variabilityDays,
    required this.regularityCode,
    required this.regularityTitle,
    required this.regularityDescription,
    required this.regularityColor,
    required this.regularityBgColor,
    required this.averagePeriodDuration,
    required this.totalCyclesRecorded,
    required this.cycleHistory,
    required this.topSymptoms,
    required this.topMoods,
    required this.totalIntimacyDays,
    required this.protectedIntimacyDays,
    required this.unprotectedIntimacyDays,
    required this.totalEntriesLogged,
    required this.ignoredGapCyclesCount,
    this.hasCycleData = false,
    this.hasPeriodData = false,
  });
}

/// Engine Analisis Siklus Berdasarkan Standar Emas ACOG Practice Bulletin No. 219
class CycleAnalyticsEngine {
  CycleAnalyticsEngine._();

  static CycleAnalyticsResult calculate({
    required List<CycleModel> cycles,
    required List<DailyEntryModel> entries,
  }) {
    // 1. Urutkan siklus dari terlama ke terbaru untuk grafik kronologis
    final sortedCycles = List<CycleModel>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Filter siklus valid untuk kalkulasi statistik:
    // Abaikan jeda bolong (isUnrecordedGap) dan outlier > 45 hari atau < 15 hari
    final validCompletedCycles = sortedCycles.where((c) {
      if (c.isUnrecordedGap) return false;
      if (c.isOutlier) return false;
      return c.cycleLengthDays >= 15 && c.cycleLengthDays <= MedicalConstants.outlierGapThreshold;
    }).toList();

    final ignoredGapCyclesCount = sortedCycles.where((c) {
      if (c.isOngoing) return false;
      return c.isUnrecordedGap || c.isOutlier || c.cycleLengthDays > MedicalConstants.outlierGapThreshold;
    }).length;

    double avgLength = MedicalConstants.baselineDefaultCycleLength.toDouble();
    int minLength = MedicalConstants.baselineDefaultCycleLength;
    int maxLength = MedicalConstants.baselineDefaultCycleLength;
    int variability = 0;

    String regCode = 'insufficient_data';
    String regTitle = 'Membutuhkan Data Tambahan';
    String regDesc =
        'Catat minimal 2 siklus untuk menganalisis tren variasi dan keteraturan fisiologis secara akurat.';
    Color regColor = AppColors.textSecondary;
    Color regBgColor = AppColors.surfaceVariant;

    if (validCompletedCycles.isNotEmpty) {
      final totalDays = validCompletedCycles.fold<int>(0, (sum, c) => sum + c.cycleLengthDays);
      avgLength = totalDays / validCompletedCycles.length;

      final lengths = validCompletedCycles.map((c) => c.cycleLengthDays).toList();
      lengths.sort();
      minLength = lengths.first;
      maxLength = lengths.last;
      variability = maxLength - minLength;

      if (validCompletedCycles.length >= 2) {
        if (variability <= 4) {
          regCode = 'very_regular';
          regTitle = 'Siklus Sangat Teratur';
          regDesc =
              'Variasi antar siklus hanya ±$variability hari. Keseimbangan poros hipotalamus-hipofisis-ovarium Anda berjalan sangat stabil dan konsisten.';
          regColor = AppColors.phaseFollicular;
          regBgColor = AppColors.phaseFollicularLight;
        } else if (variability <= 9) {
          regCode = 'regular';
          regTitle = 'Siklus Teratur (Standar Emas ACOG)';
          regDesc =
              'Variasi $variability hari berada dalam batas fisiologis normal reproduksi wanita (< 9 hari menurut ACOG Practice Bulletin No. 219).';
          regColor = AppColors.phaseFollicular;
          regBgColor = AppColors.phaseFollicularLight;
        } else if (variability <= 14) {
          regCode = 'moderate';
          regTitle = 'Variasi Fisiologis Ringan';
          regDesc =
              'Variasi $variability hari masih tergolong wajar. Fluktuasi ini umumnya dipicu oleh adaptasi stres harian, kualitas tidur, nutrisi, atau kelelahan.';
          regColor = AppColors.phaseLuteal;
          regBgColor = AppColors.phaseLutealLight;
        } else {
          regCode = 'irregular';
          regTitle = 'Siklus Fluktuatif';
          regDesc =
              'Selisih siklus mencapai $variability hari (melebihi variasi normal 9 hari). Jika fluktuasi berlanjut beberapa bulan ke depan, disarankan berkonsultasi ke dokter Sp.OG.';
          regColor = AppColors.phaseMenstrual;
          regBgColor = AppColors.phaseMenstrualLight;
        }
      } else {
        regTitle = 'Data Terbatas (1 Siklus)';
        regDesc =
            'Baru 1 siklus terekam ($minLength hari). Tambahkan siklus berikutnya untuk menghitung variabilitas dan skor keteraturan.';
        regColor = AppColors.primary;
        regBgColor = AppColors.primaryContainer;
      }
    }

    // 2. Durasi haid rata-rata
    final cyclesWithPeriod = sortedCycles.where((c) => c.periodDurationDays > 0).toList();
    double avgPeriodDuration = MedicalConstants.baselinePeriodDuration.toDouble();
    if (cyclesWithPeriod.isNotEmpty) {
      final totalPeriodDays = cyclesWithPeriod.fold<int>(0, (sum, c) => sum + c.periodDurationDays);
      avgPeriodDuration = totalPeriodDays / cyclesWithPeriod.length;
    }

    // 3. Titik grafik riwayat (ambil hingga 6-8 siklus valid/ongoing terakhir)
    // Saring jeda lupa catat (>45 hari) agar tidak merusak visualisasi dan skala grafik
    final validChartCycles = sortedCycles.where((c) {
      if (c.isOngoing) return true;
      if (c.isUnrecordedGap || c.isOutlier) return false;
      return c.cycleLengthDays >= 15 && c.cycleLengthDays <= MedicalConstants.outlierGapThreshold;
    }).toList();

    final historyList = <CycleHistoryPoint>[];
    final displayCycles = validChartCycles.length > 8
        ? validChartCycles.sublist(validChartCycles.length - 8)
        : validChartCycles;

    for (final c in displayCycles) {
      final label = _formatMonthYear(c.startDate);
      historyList.add(
        CycleHistoryPoint(
          cycleId: c.cycleId,
          startDate: c.startDate,
          endDate: c.endDate,
          cycleLengthDays: c.cycleLengthDays > 0 ? c.cycleLengthDays : 28,
          periodDurationDays: c.periodDurationDays > 0 ? c.periodDurationDays : 5,
          label: label,
          isOngoing: c.isOngoing,
          isOutlier: false,
        ),
      );
    }

    // 4. Analisis Gejala Fisik Terbanyak
    final symptomCounts = <String, int>{};

    for (final entry in entries) {
      for (final s in entry.symptoms) {
        if (s.trim().isNotEmpty) {
          symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
        }
      }
    }

    final topSymptoms = <SymptomFrequencyItem>[];
    final totalEntriesCount = entries.length;

    symptomCounts.forEach((key, count) {
      final percentage = totalEntriesCount > 0
          ? ((count / totalEntriesCount) * 100).clamp(0.0, 100.0)
          : 0.0;
      topSymptoms.add(
        SymptomFrequencyItem(
          symptomKey: key,
          label: _mapSymptomLabel(key),
          occurrenceCount: count,
          percentage: double.parse(percentage.toStringAsFixed(1)),
        ),
      );
    });

    // Urutkan gejala dari yang paling sering dialami
    topSymptoms.sort((a, b) => b.occurrenceCount.compareTo(a.occurrenceCount));

    // 5. Analisis Distribusi Suasana Hati (Mood)
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      if (entry.mood.trim().isNotEmpty) {
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }
    }

    final topMoods = <MoodFrequencyItem>[];
    moodCounts.forEach((key, count) {
      final percentage = totalEntriesCount > 0
          ? ((count / totalEntriesCount) * 100).clamp(0.0, 100.0)
          : 0.0;
      topMoods.add(
        MoodFrequencyItem(
          moodKey: key,
          label: _mapMoodLabel(key),
          count: count,
          percentage: double.parse(percentage.toStringAsFixed(1)),
          color: _mapMoodColor(key),
        ),
      );
    });

    topMoods.sort((a, b) => b.count.compareTo(a.count));

    // 6. Analisis Keintiman
    int totalIntimacy = 0;
    int protectedIntimacy = 0;
    int unprotectedIntimacy = 0;

    for (final entry in entries) {
      if (entry.hasIntimacy) {
        totalIntimacy++;
        if (entry.usedProtection == true) {
          protectedIntimacy++;
        } else if (entry.usedProtection == false) {
          unprotectedIntimacy++;
        }
      }
    }

    return CycleAnalyticsResult(
      averageCycleLength: double.parse(avgLength.toStringAsFixed(1)),
      shortestCycleLength: minLength,
      longestCycleLength: maxLength,
      variabilityDays: variability,
      regularityCode: regCode,
      regularityTitle: regTitle,
      regularityDescription: regDesc,
      regularityColor: regColor,
      regularityBgColor: regBgColor,
      averagePeriodDuration: double.parse(avgPeriodDuration.toStringAsFixed(1)),
      totalCyclesRecorded: sortedCycles.length,
      cycleHistory: historyList,
      topSymptoms: topSymptoms,
      topMoods: topMoods,
      totalIntimacyDays: totalIntimacy,
      protectedIntimacyDays: protectedIntimacy,
      unprotectedIntimacyDays: unprotectedIntimacy,
      totalEntriesLogged: totalEntriesCount,
      ignoredGapCyclesCount: ignoredGapCyclesCount,
      hasCycleData: validCompletedCycles.isNotEmpty,
      hasPeriodData: cyclesWithPeriod.isNotEmpty,
    );
  }

  static String _mapSymptomLabel(String key) {
    switch (key) {
      case 'cramps':
        return 'Kram Perut (Dismenore)';
      case 'headache':
        return 'Sakit Kepala';
      case 'bloating':
        return 'Perut Kembung';
      case 'backache':
        return 'Pegal Pinggang';
      case 'tender_breasts':
        return 'Nyeri Payudara';
      case 'acne':
        return 'Jerawat Hormonal';
      default:
        return key;
    }
  }

  static String _mapMoodLabel(String key) {
    switch (key) {
      case 'happy':
        return '😊 Senang';
      case 'calm':
        return '🌿 Tenang';
      case 'tired':
        return '😴 Lelah';
      case 'anxious':
        return '🌧️ Cemas';
      case 'irritable':
        return '⚡ Sensitif';
      default:
        return key;
    }
  }

  static Color _mapMoodColor(String key) {
    switch (key) {
      case 'happy':
        return AppColors.phaseFollicular;
      case 'calm':
        return AppColors.phaseFollicular;
      case 'tired':
        return AppColors.phaseLuteal;
      case 'anxious':
        return AppColors.phaseOvulation;
      case 'irritable':
        return AppColors.phaseMenstrual;
      default:
        return AppColors.primary;
    }
  }

  static String _formatMonthYear(DateTime date) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final monthName = monthNames[date.month - 1];
    final yearSuffix = date.year.toString().length >= 2
        ? date.year.toString().substring(date.year.toString().length - 2)
        : date.year.toString();
    return '$monthName $yearSuffix';
  }
}
