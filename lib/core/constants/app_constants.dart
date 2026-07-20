import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Printa';
  static const String appVersion = '1.0.0';
  static const String appTagline =
      'Built for handheld POS & thermal printers';
  static const String logoAsset = 'assets/images/printa_logo.png';

  // About / Developer
  static const String developerName = 'Fahad Ali';
  static const String developerTitle = 'Senior Mobile App Consultant';
  static const String aboutSummary =
      'Printa helps teams design, preview, and print receipts, QR codes, '
      'barcodes, NFC tags, and PDF invoices on handheld POS devices with '
      'built-in thermal printers.';
  static const String aboutCredit =
      'Designed and developed by Fahad Ali, Senior Mobile App Consultant — '
      'crafting reliable mobile experiences for retail and POS workflows.';

  // Hive Box Names
  static const String settingsBox = 'settings_box';
  static const String historyBox = 'history_box';
  static const String templatesBox = 'templates_box';

  // Default Business Specs
  static const String defaultBusinessName = 'Printa Tech Solutions';
  static const String defaultCurrency = 'USD';
  static const double defaultTaxRate = 10.0; // 10%
  static const double defaultDiscount = 0.0;
  static const int defaultPaperWidth = 58; // 58mm default for handheld POS

  // Brand palette — Printa orange throughout the app
  static const Color primaryOrange = Color(0xFFFF6600);
  static const Color orangeDark = Color(0xFFE55A00);
  static const Color orangeDeep = Color(0xFFCC4E00);
  static const Color orangeLight = Color(0xFFFF8533);
  static const Color orangeSoft = Color(0xFFFFE8D9);
  static const Color orangeMuted = Color(0xFFFFB380);

  static const Color darkBg = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1E1E22);
  static const Color darkCard = Color(0xFF26262B);

  static const Color lightBg = Color(0xFFFFF8F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFF1E8);

  static LinearGradient get brandGradient => const LinearGradient(
        colors: [primaryOrange, orangeDark, orangeDeep],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get brandGradientSoft => LinearGradient(
        colors: [
          primaryOrange.withOpacity(0.18),
          primaryOrange.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
