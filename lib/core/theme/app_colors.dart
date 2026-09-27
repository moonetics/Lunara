import 'package:flutter/material.dart';

/// Palet Warna Terapeutik Lunara
/// Dirancang sesuai standar 'frontend-design' & 'flutter-design-system':
/// Menghindari gradien ungu/neon klise; menggunakan warna bumi alami,
/// menenangkan, terapeutik, dan ramah aksesibilitas (kontras tinggi).
class AppColors {
  AppColors._();

  // Warna Utama (Soft Blush Rose & Calm Pink)
  static const Color primary = Color(0xFFE28298);
  static const Color primaryLight = Color(0xFFF9DCE3);
  static const Color primaryDark = Color(0xFFB8556D);
  static const Color primaryContainer = Color(0xFFFCECEF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF5A1E2B);

  // Aksen Fase Siklus (Kontras Tinggi & Menenangkan)
  // 1. Menstruasi: Deep Berry Rose (penanda perdarahan alami yang tegas)
  static const Color phaseMenstrual = Color(0xFFE05275);
  static const Color phaseMenstrualLight = Color(0xFFFDEEF1);
  static const Color onPhaseMenstrual = Color(0xFF5A1E2B);

  // 2. Folikular: Sage Mint Herbal (pemulihan estrogen & kontras segar terhadap pink)
  static const Color phaseFollicular = Color(0xFF4D8B70);
  static const Color phaseFollicularLight = Color(0xFFEDF5F1);
  static const Color onPhaseFollicular = Color(0xFF1B3D2F);

  // 3. Ovulasi: Amethyst Orchid (puncak kesuburan/masa subur yang anggun)
  static const Color phaseOvulation = Color(0xFF845EC2);
  static const Color phaseOvulationLight = Color(0xFFF4EFFB);
  static const Color onPhaseOvulation = Color(0xFF381F63);

  // 4. Luteal / PMS: Warm Golden Amber (lonjakan progesteron & persiapan haid)
  static const Color phaseLuteal = Color(0xFFD9822B);
  static const Color phaseLutealLight = Color(0xFFFEF4E8);
  static const Color onPhaseLuteal = Color(0xFF5E3609);

  // Aksen Khusus Aktivitas Intim / Seksual
  static const Color intimacyAccent = Color(0xFFE05375);
  static const Color intimacyLight = Color(0xFFFDE8ED);

  // Latar Belakang & Permukaan (Calm Rose Milk Cream)
  static const Color background = Color(0xFFFFFDFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFBF4F6);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // Tipografi & Kontras Teks (Sesuai Standar WCAG 4.5:1+)
  static const Color textPrimary = Color(0xFF2D2326);   // Deep Charcoal Rose (tegas & nyaman)
  static const Color textSecondary = Color(0xFF7D6E72); // Soft Taupe (informasi pendukung)
  static const Color textTertiary = Color(0xFFA69A9E);  // Muted Taupe (caption)

  // Batas & Garis Pemisah Halus
  static const Color border = Color(0xFFF4E4E8);
  static const Color borderSubtle = Color(0xFFFAECEF);

  // Tanda Bahaya & Status Medis
  static const Color redFlag = Color(0xFFDC2626);       // Alert klinis dokter Sp.OG
  static const Color redFlagLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Mode Pasangan (Companion Accent)
  static const Color companionBadge = Color(0xFF5D4E53);
  static const Color companionHighlight = Color(0xFFE2E8F0);
}
