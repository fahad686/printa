import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'SUNMI Hardware Test Suite';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String settingsBox = 'settings_box';
  static const String historyBox = 'history_box';
  static const String templatesBox = 'templates_box';

  // Default Business Specs
  static const String defaultBusinessName = 'SUNMI POS Tech Solutions';
  static const String defaultCurrency = 'USD';
  static const double defaultTaxRate = 10.0; // 10%
  static const double defaultDiscount = 0.0;
  static const int defaultPaperWidth = 58; // 58mm default for SUNMI V3

  // Colors
  static const Color primaryOrange = Color(0xFFFF6600); // Signature SUNMI brand orange
  static const Color darkBg = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1E1E22);
  static const Color darkCard = Color(0xFF26262B);
  
  static const Color lightBg = Color(0xFFF6F7F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F2F5);
}
