import 'package:flutter/material.dart';
import '../constants/medical_constants.dart';
import '../database/models/cycle_model.dart';
import '../theme/app_colors.dart';

/// 4 Fase Fisiologis Siklus Menstruasi (Berdasarkan Guyton & Hall Bab 82)
enum CyclePhase {
  menstrual, // Fase Perdarahan / Menstruasi (Hari 1 s/d durasi haid)
  follicular, // Fase Folikular (Estrogen meningkat, energi pulih)
  ovulation, // Fase Ovulasi (Pelepasan sel telur, masa subur puncak)
  luteal, // Fase Luteal / PMS (Progesteron mendominasi lalu turun)
}

/// Informasi Lengkap Status Fase Hari Ini
class CyclePhaseInfo {
  final CyclePhase phase;
  final int dayOfCycle;
  final int daysUntilNextPeriod;
  final String phaseTitle;
  final String phaseSubtitle;
  final String biologicalSummary;
  final String partnerCareAdvice;
  final Color themeColor;
  final Color lightColor;
  final bool isLate;

  const CyclePhaseInfo({
    required this.phase,
    required this.dayOfCycle,
    required this.daysUntilNextPeriod,
    required this.phaseTitle,
    required this.phaseSubtitle,
    required this.biologicalSummary,
    required this.partnerCareAdvice,
    required this.themeColor,
    required this.lightColor,
    this.isLate = false,
  });
}

/// Mesin Kalkulasi Siklus Menstruasi Lunara
/// Berprinsip 100% Deterministik Medis & Toleran Terhadap Data Bolong (*Smart Gap Handling*)
class CycleEngine {
  CycleEngine._();

  /// Menghitung panjang rata-rata siklus dari riwayat lampau.
  /// Siklus dengan durasi < 21 hari atau > 45 hari (data bolong/lupa catat)
  /// otomatis dikeluarkan dari pembagi rata-rata (*Outlier Filtering*).
  static double calculateAverageCycleLength(List<CycleModel> pastCycles) {
    if (pastCycles.isEmpty) {
      return MedicalConstants.baselineDefaultCycleLength.toDouble();
    }

    // Saring hanya siklus yang fisiologis valid (21 s/d 45 hari) dan bukan outlier
    final validCycles = pastCycles.where((cycle) {
      if (cycle.isOutlier) return false;
      final days = cycle.cycleLengthDays;
      return days >= MedicalConstants.normalMinCycleLength &&
          days <= MedicalConstants.outlierGapThreshold;
    }).toList();

    if (validCycles.isEmpty) {
      return MedicalConstants.baselineDefaultCycleLength.toDouble();
    }

    final totalDays =
        validCycles.fold<int>(0, (sum, c) => sum + c.cycleLengthDays);
    return totalDays / validCycles.length;
  }

  /// Menghitung estimasi tanggal hari pertama menstruasi berikutnya
  static DateTime calculateNextPeriodDate(
    DateTime lastPeriodStartDate,
    double avgCycleLength,
  ) {
    final normalizedStart = DateTime(
      lastPeriodStartDate.year,
      lastPeriodStartDate.month,
      lastPeriodStartDate.day,
    );
    return normalizedStart.add(Duration(days: avgCycleLength.round()));
  }

  /// Menghitung jumlah hari keterlambatan jika tanggal hari ini telah melewati estimasi
  static int calculateDelayDays(DateTime expectedDate, [DateTime? today]) {
    final now = today ?? DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedExpected = DateTime(
      expectedDate.year,
      expectedDate.month,
      expectedDate.day,
    );

    if (normalizedNow.isAfter(normalizedExpected)) {
      return normalizedNow.difference(normalizedExpected).inDays;
    }
    return 0;
  }

  /// Menghitung fase fisiologis aktif hari ini beserta panduan perlakuan
  static CyclePhaseInfo getCurrentPhase(
    DateTime lastPeriodStartDate,
    double avgCycleLength, {
    int periodDuration = MedicalConstants.baselinePeriodDuration,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedStart = DateTime(
      lastPeriodStartDate.year,
      lastPeriodStartDate.month,
      lastPeriodStartDate.day,
    );

    // Hari ke-N dalam siklus (1-indexed)
    final diffDays = normalizedNow.difference(normalizedStart).inDays;
    final dayOfCycle = diffDays >= 0 ? diffDays + 1 : 1;

    final expectedNextDate = calculateNextPeriodDate(normalizedStart, avgCycleLength);
    final delayDays = calculateDelayDays(expectedNextDate, normalizedNow);
    final isLate = delayDays > 0;
    final daysUntilNextPeriod = isLate ? 0 : (avgCycleLength.round() - dayOfCycle + 1).clamp(0, 99);

    // Estimasi ovulasi: Selalu 14 hari sebelum haid berikutnya (Fase Luteal konstan 14 hari - Guyton & Hall)
    final ovulationDay = (avgCycleLength - 14).round().clamp(8, 30);

    // 1. Fase Menstruasi (Hari 1 s/d durasi perdarahan haid)
    if (dayOfCycle <= periodDuration) {
      return CyclePhaseInfo(
        phase: CyclePhase.menstrual,
        dayOfCycle: dayOfCycle,
        daysUntilNextPeriod: daysUntilNextPeriod,
        phaseTitle: 'Fase Menstruasi',
        phaseSubtitle: 'Hari ke-$dayOfCycle dari siklus',
        biologicalSummary:
            'Dinding rahim meluruh akibat penurunan tajam progesteron. Tubuh membutuhkan istirahat dan hidrasi yang cukup untuk mengimbangi pengeluaran zat besi.',
        partnerCareAdvice:
            'Sediakan kompres hangat untuk meredakan kram perut, tawarkan minuman jahe/cokelat hangat, dan ambil inisiatif meringankan pekerjaan fisiknya.',
        themeColor: AppColors.phaseMenstrual,
        lightColor: AppColors.phaseMenstrualLight,
        isLate: false,
      );
    }

    // 2. Fase Folikular (Pasca haid s/d 2 hari sebelum ovulasi)
    if (dayOfCycle < (ovulationDay - 1)) {
      return CyclePhaseInfo(
        phase: CyclePhase.follicular,
        dayOfCycle: dayOfCycle,
        daysUntilNextPeriod: daysUntilNextPeriod,
        phaseTitle: 'Fase Folikular',
        phaseSubtitle: 'Hari ke-$dayOfCycle dari siklus',
        biologicalSummary:
            'Hormon estrogen sedang meningkat untuk mematangkan sel telur. Tingkat energi, stamina tubuh, dan suasana hati umumnya berada dalam kondisi prima.',
        partnerCareAdvice:
            'Waktu yang sangat baik untuk mengajak dia jalan-jalan, berolahraga bersama, atau mendiskusikan rencana masa depan karena energinya sedang tinggi.',
        themeColor: AppColors.phaseFollicular,
        lightColor: AppColors.phaseFollicularLight,
        isLate: false,
      );
    }

    // 3. Fase Ovulasi (Jendela 3 hari: H-1, Hari H, H+1 ovulasi)
    if (dayOfCycle >= (ovulationDay - 1) && dayOfCycle <= (ovulationDay + 1)) {
      return CyclePhaseInfo(
        phase: CyclePhase.ovulation,
        dayOfCycle: dayOfCycle,
        daysUntilNextPeriod: daysUntilNextPeriod,
        phaseTitle: 'Fase Ovulasi',
        phaseSubtitle: 'Hari ke-$dayOfCycle (Puncak Masa Subur)',
        biologicalSummary:
            'Lonjakan hormon LH memicu pelepasan sel telur matang dari ovarium. Suhu basal tubuh sedikit naik dan daya tarik serta rasa percaya diri memuncak.',
        partnerCareAdvice:
            'Mood dan keintiman sedang di puncaknya. Berikan apresiasi dan perhatian ekstra untuk mempererat ikatan emosional kalian.',
        themeColor: AppColors.phaseOvulation,
        lightColor: AppColors.phaseOvulationLight,
        isLate: false,
      );
    }

    // 4. Fase Luteal / Pra-Menstruasi (Setelah ovulasi s/d akhir siklus atau jika telat)
    return CyclePhaseInfo(
      phase: CyclePhase.luteal,
      dayOfCycle: dayOfCycle,
      daysUntilNextPeriod: daysUntilNextPeriod,
      phaseTitle: isLate ? 'Siklus Terlambat ($delayDays Hari)' : 'Fase Luteal (PMS)',
      phaseSubtitle: isLate
          ? 'Melewati estimasi $delayDays hari'
          : 'Est. Haid: $daysUntilNextPeriod hari lagi',
      biologicalSummary: isLate
          ? 'Menstruasi belum tiba melewati perkiraan. Faktor stres akut, pola makan, atau kelelahan sering menunda ovulasi sebelumnya.'
          : 'Kadar progesteron mulai menurun jika sel telur tidak dibuahi. Penurunan hormon ini rentan memicu kelelahan, kembung, dan sensitivitas emosional.',
      partnerCareAdvice: isLate
          ? 'Tetap tenang dan jangan tunjukkan kepanikan. Sikap tenangmu akan meredakan stresnya, karena stres justru membuat haid semakin tertunda.'
          : 'Jangan tersinggung jika nada bicaranya sedikit berubah atau sensitif. Siapkan camilan favoritnya dan dengarkan ceritanya tanpa memotong.',
      themeColor: isLate ? AppColors.warning : AppColors.phaseLuteal,
      lightColor: isLate ? AppColors.warningLight : AppColors.phaseLutealLight,
      isLate: isLate,
    );
  }

  /// Menilai apakah jarak antara dua tanggal haid merupakan siklus normal atau data bolong
  static bool isOutlierGap(DateTime previousStart, DateTime nextStart) {
    final diff = nextStart.difference(previousStart).inDays;
    return diff < MedicalConstants.normalMinCycleLength ||
        diff > MedicalConstants.outlierGapThreshold;
  }

  /// Mencari siklus yang aktif atau menaungi tanggal tertentu
  static CycleModel? findCycleForDate(DateTime date, List<CycleModel> cycles) {
    if (cycles.isEmpty) return null;
    final sorted = List<CycleModel>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final normalizedDate = DateTime(date.year, date.month, date.day);
    CycleModel? candidate;
    for (final c in sorted) {
      final normalizedStart = DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
      if (!normalizedStart.isAfter(normalizedDate)) {
        candidate = c;
      } else {
        break;
      }
    }
    return candidate;
  }

  /// Menilai apakah suatu tanggal jatuh dalam jendela masa subur (Fertile Window)
  /// Sesuai ACOG: Masa subur terjadi sekitar 5 hari sebelum ovulasi hingga 1 hari setelah ovulasi.
  /// Hari ovulasi fisiologis diperkirakan pada (panjang siklus - 14 hari).
  static bool isDateInFertileWindow(
    DateTime targetDate,
    DateTime lastPeriodStartDate,
    int cycleLength,
  ) {
    final normalizedTarget = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final normalizedStart = DateTime(lastPeriodStartDate.year, lastPeriodStartDate.month, lastPeriodStartDate.day);

    final ovulationDayNumber = (cycleLength - 14).clamp(10, cycleLength > 20 ? cycleLength - 10 : 14);
    final ovulationDate = normalizedStart.add(Duration(days: ovulationDayNumber - 1));

    final fertileWindowStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileWindowEnd = ovulationDate.add(const Duration(days: 1));

    return !normalizedTarget.isBefore(fertileWindowStart) && !normalizedTarget.isAfter(fertileWindowEnd);
  }

  /// Memberikan analisis konsepsi & status proteksi untuk aktivitas intim
  static IntimacyAnalysis getIntimacyConceptionAnalysis({
    required DateTime intimacyDate,
    required DateTime lastPeriodStartDate,
    required int cycleLength,
    required bool hasProtection,
    bool? isFertileWindow,
    String? appGoal,
  }) {
    final normalizedTarget = DateTime(intimacyDate.year, intimacyDate.month, intimacyDate.day);
    final normalizedStart = DateTime(lastPeriodStartDate.year, lastPeriodStartDate.month, lastPeriodStartDate.day);
    final ovulationDayNumber = (cycleLength - 14).clamp(10, cycleLength > 20 ? cycleLength - 10 : 14);
    final ovulationDate = normalizedStart.add(Duration(days: ovulationDayNumber - 1));
    final diffFromOvulation = normalizedTarget.difference(ovulationDate).inDays;

    final inFertile = isFertileWindow ??
        isDateInFertileWindow(intimacyDate, lastPeriodStartDate, cycleLength);

    final isContraceptionGoal = appGoal == 'natural_contraception';
    final isPregnancyGoal = appGoal == 'pregnancy_program';

    String timingContext;
    if (diffFromOvulation == 0) {
      timingContext = 'Hari H Perkiraan Ovulasi (Puncak Kesuburan)';
    } else if (diffFromOvulation < 0 && diffFromOvulation >= -5) {
      timingContext = 'H$diffFromOvulation Sebelum Ovulasi (Viabilitas Sperma Aktif)';
    } else if (diffFromOvulation == 1) {
      timingContext = 'H+1 Pasca-Ovulasi (Jendela Penutupan Masa Subur)';
    } else if (diffFromOvulation < -5) {
      timingContext = 'Fase Folikular (Pra-Ovulasi)';
    } else {
      timingContext = 'Fase Luteal (Pasca-Ovulasi)';
    }

    const hygieneTip =
        'Segera buang air kecil (BAK) dalam 15 menit pasca-intim untuk membilas uretra dan mencegah Infeksi Saluran Kemih (ISK) sesuai panduan ACOG & POGI.';

    if (inFertile) {
      if (hasProtection) {
        final advice = isPregnancyGoal
            ? 'CATATAN PROMIL: Anda mencatat menggunakan pengaman di masa subur. Bila sedang aktif merencanakan kehamilan, berhubungan tanpa pengaman pada jendela ini memaksimalkan peluang konsepsi (ASRM).'
            : 'Proteksi kondom/pengaman efektif hingga ~98% jika terpasang sempurna sejak awal. Pastikan pengaman utuh dan tidak terlepas.';

        return IntimacyAnalysis(
          isHighConceptionRisk: false,
          statusLabel: 'Masa Subur (Terproteksi)',
          description: 'Aktivitas terjadi dalam jendela ovulasi dengan pengaman. Risiko konsepsi minimal.',
          badgeColor: AppColors.phaseOvulation,
          actionableAdvice: advice,
          hygieneTip: hygieneTip,
          timingContext: timingContext,
        );
      } else {
        final advice = isContraceptionGoal
            ? 'PERINGATAN KONTRASEPSI: Berada di puncak masa subur tanpa pengaman. Jika kehamilan tidak direncanakan, pertimbangkan opsi kontrasepsi darurat (morning-after pill) dalam 72 jam (Konsensus POGI/ACOG). Lakukan tes kehamilan jika haid berikutnya terlambat.'
            : (isPregnancyGoal
                ? 'WAKTU EMAS PROMIL: Berada di jendela kesuburan tertinggi (probabilitas konsepsi ~36% menurut Wilcox et al., NEJM). ASRM merekomendasikan hubungan intim setiap 1–2 hari sekali (selang-seling). Sperma segar kini siap menyambut sel telur!'
                : 'PELUANG KONSEPSI TINGGI: Berada di waktu paling optimal untuk pembuahan jika Anda merencanakan kehamilan. Lakukan tes kehamilan (test pack) saat hari pertama terlambat haid.');

        return IntimacyAnalysis(
          isHighConceptionRisk: true,
          statusLabel: isPregnancyGoal ? 'Hari Emas Konsepsi (Promil)' : 'Peluang Konsepsi Tinggi',
          description: isPregnancyGoal
              ? 'Aktivitas optimal tanpa pengaman di jendela masa subur puncak.'
              : 'Aktivitas tanpa pengaman terjadi di jendela masa subur. Disarankan tes kehamilan (test pack) jika nanti terjadi keterlambatan haid.',
          badgeColor: AppColors.intimacyAccent,
          actionableAdvice: advice,
          hygieneTip: hygieneTip,
          timingContext: timingContext,
        );
      }
    } else {
      if (hasProtection) {
        return IntimacyAnalysis(
          isHighConceptionRisk: false,
          statusLabel: 'Terproteksi (Fase Aman)',
          description: 'Aktivitas dengan pengaman di luar jendela ovulasi utama.',
          badgeColor: AppColors.phaseFollicular,
          actionableAdvice:
              'Perlindungan ganda: risiko kehamilan sangat minimal karena berada di luar masa subur sekaligus menggunakan pengaman.',
          hygieneTip: hygieneTip,
          timingContext: timingContext,
        );
      } else {
        final advice = isContraceptionGoal
            ? 'FASE RENDAH RISIKO: Berada di luar estimasi ovulasi kalender. Namun perlu diingat fluktuasi hormon atau stres bisa menggeser ovulasi sewaktu-waktu.'
            : (isPregnancyGoal
                ? 'DI LUAR JENDELA OVULASI: Peluang konsepsi hari ini rendah karena sel telur belum/sudah selesai berovulasi. Terus pantau siklus Anda.'
                : 'DI LUAR MASA SUBUR: Peluang konsepsi relatif rendah secara fisiologis karena sel telur belum atau sudah selesai dilepaskan.');

        return IntimacyAnalysis(
          isHighConceptionRisk: false,
          statusLabel: 'Tanpa Pengaman (Di Luar Masa Subur)',
          description: 'Aktivitas di luar estimasi masa subur. Peluang konsepsi relatif rendah secara fisiologis.',
          badgeColor: AppColors.phaseLuteal,
          actionableAdvice: advice,
          hygieneTip: hygieneTip,
          timingContext: timingContext,
        );
      }
    }
  }

  /// Memberikan panduan waktu konsepsi harian (Hari Emas vs Hari Aman)
  /// Berdasarkan riset ASRM Practice Committee (2017/2022) dan Wilcox et al. (NEJM 1995)
  static ConceptionTimingGuidance getConceptionTimingGuidance({
    required DateTime targetDate,
    required DateTime lastPeriodStartDate,
    required int cycleLength,
    String? appGoal,
  }) {
    final normalizedTarget = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final normalizedStart = DateTime(lastPeriodStartDate.year, lastPeriodStartDate.month, lastPeriodStartDate.day);
    final ovulationDayNumber = (cycleLength - 14).clamp(10, cycleLength > 20 ? cycleLength - 10 : 14);
    final ovulationDate = normalizedStart.add(Duration(days: ovulationDayNumber - 1));
    final diffFromOvulation = normalizedTarget.difference(ovulationDate).inDays;

    final isPromil = appGoal == 'pregnancy_program';
    final isContraception = appGoal == 'natural_contraception';

    int probability;
    if (diffFromOvulation == -2) {
      probability = 36;
    } else if (diffFromOvulation == -1) {
      probability = 34;
    } else if (diffFromOvulation == 0) {
      probability = 36;
    } else if (diffFromOvulation == -3) {
      probability = 14;
    } else if (diffFromOvulation == -4) {
      probability = 16;
    } else if (diffFromOvulation == -5) {
      probability = 10;
    } else if (diffFromOvulation == 1) {
      probability = 4;
    } else {
      probability = 0;
    }

    final isGolden = diffFromOvulation >= -2 && diffFromOvulation <= 0;
    final isSafe = diffFromOvulation >= 2;

    String headline;
    String advice;
    Color badgeColor;

    if (isGolden) {
      headline = 'Hari Emas Konsepsi (~$probability%)';
      badgeColor = AppColors.intimacyAccent;
      if (isPromil) {
        advice = 'Waktu paling optimal untuk berhubungan intim bila merencanakan kehamilan (Puncak Wilcox NEJM). ASRM menganjurkan frekuensi setiap 1–2 hari sekali.';
      } else if (isContraception) {
        advice = 'Zona Merah: Risiko kehamilan sangat tinggi (~$probability%). Wajib gunakan pengaman (kondom) bila ingin menunda kehamilan.';
      } else {
        advice = 'Puncak masa subur siklus menstruasi. Peluang pembuahan tertinggi dalam 1 bulan.';
      }
    } else if (diffFromOvulation >= -5 && diffFromOvulation < -2) {
      headline = 'Jendela Subur Aktif (~$probability%)';
      badgeColor = AppColors.phaseOvulation;
      if (isPromil) {
        advice = 'Sperma dapat bertahan hingga 5 hari di serviks. Berhubungan intim di fase ini mulai efektif menyambut ovulasi.';
      } else if (isContraception) {
        advice = 'Zona Waspada: Hubungan tanpa pengaman di hari ini berisiko karena sperma mampu bertahan hidup sampai ovulasi.';
      } else {
        advice = 'Memasuki jendela masa subur fisiologis.';
      }
    } else if (isSafe) {
      headline = 'Zona Aman Fisiologis (0%)';
      badgeColor = AppColors.phaseFollicular;
      if (isContraception) {
        advice = 'Zona Bebas Pengaman (ACOG): Sel telur telah berdegenerasi dan progesteron mengentalkan lendir serviks. Peluang kehamilan secara biologis mendekati 0%.';
      } else if (isPromil) {
        advice = 'Jendela ovulasi siklus ini telah selesai. Tetap jaga pola makan dan istirahat menjelang evaluasi haid berikutnya.';
      } else {
        advice = 'Fase Luteal pasca-ovulasi dengan risiko konsepsi sangat rendah.';
      }
    } else {
      headline = 'Fase Folikular Awal';
      badgeColor = AppColors.textSecondary;
      advice = 'Masa sebelum jendela subur aktif. Hormon estrogen sedang mempersiapkan folikel sel telur.';
    }

    return ConceptionTimingGuidance(
      probabilityPercentage: probability,
      isGoldenConceptionDay: isGolden,
      isAbsoluteSafeDay: isSafe,
      timingHeadline: headline,
      recommendation: advice,
      badgeColor: badgeColor,
      daysToOvulation: diffFromOvulation,
    );
  }
}

/// Model Rangkuman Analisis Keintiman Klinis
class IntimacyAnalysis {
  final bool isHighConceptionRisk;
  final String statusLabel;
  final String description;
  final Color badgeColor;
  final String actionableAdvice;
  final String hygieneTip;
  final String timingContext;

  const IntimacyAnalysis({
    required this.isHighConceptionRisk,
    required this.statusLabel,
    required this.description,
    required this.badgeColor,
    this.actionableAdvice = '',
    this.hygieneTip = '',
    this.timingContext = '',
  });
}

/// Model Panduan Waktu Konsepsi & Kesuburan (Hari Emas vs Hari Aman)
class ConceptionTimingGuidance {
  final int probabilityPercentage;
  final bool isGoldenConceptionDay;
  final bool isAbsoluteSafeDay;
  final String timingHeadline;
  final String recommendation;
  final Color badgeColor;
  final int daysToOvulation;

  const ConceptionTimingGuidance({
    required this.probabilityPercentage,
    required this.isGoldenConceptionDay,
    required this.isAbsoluteSafeDay,
    required this.timingHeadline,
    required this.recommendation,
    required this.badgeColor,
    required this.daysToOvulation,
  });
}
