import 'dart:convert';
import '../../core/constants/app_constants.dart';

class AppSettingsModel {
  final String themeMode; // 'system', 'light', 'dark'
  final int printerWidth; // 58 or 80
  final String defaultCurrency;
  final String businessName;
  final String? businessLogo;
  final double defaultTaxPercentage;
  final String defaultTemplateId;

  AppSettingsModel({
    this.themeMode = 'dark',
    this.printerWidth = AppConstants.defaultPaperWidth,
    this.defaultCurrency = AppConstants.defaultCurrency,
    this.businessName = AppConstants.defaultBusinessName,
    this.businessLogo,
    this.defaultTaxPercentage = AppConstants.defaultTaxRate,
    this.defaultTemplateId = 'tpl_restaurant',
  });

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'printerWidth': printerWidth,
        'defaultCurrency': defaultCurrency,
        'businessName': businessName,
        'businessLogo': businessLogo,
        'defaultTaxPercentage': defaultTaxPercentage,
        'defaultTemplateId': defaultTemplateId,
      };

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => AppSettingsModel(
        themeMode: json['themeMode'] ?? 'dark',
        printerWidth: (json['printerWidth'] as num?)?.toInt() ?? 58,
        defaultCurrency: json['defaultCurrency'] ?? 'USD',
        businessName: json['businessName'] ?? AppConstants.defaultBusinessName,
        businessLogo: json['businessLogo'],
        defaultTaxPercentage:
            (json['defaultTaxPercentage'] as num?)?.toDouble() ?? 10.0,
        defaultTemplateId: json['defaultTemplateId'] ?? 'tpl_restaurant',
      );

  String toJsonString() => jsonEncode(toJson());

  factory AppSettingsModel.fromJsonString(String str) =>
      AppSettingsModel.fromJson(jsonDecode(str));

  AppSettingsModel copyWith({
    String? themeMode,
    int? printerWidth,
    String? defaultCurrency,
    String? businessName,
    String? businessLogo,
    double? defaultTaxPercentage,
    String? defaultTemplateId,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      printerWidth: printerWidth ?? this.printerWidth,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      businessName: businessName ?? this.businessName,
      businessLogo: businessLogo ?? this.businessLogo,
      defaultTaxPercentage: defaultTaxPercentage ?? this.defaultTaxPercentage,
      defaultTemplateId: defaultTemplateId ?? this.defaultTemplateId,
    );
  }
}
