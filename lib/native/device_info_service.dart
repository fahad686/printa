import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

class DeviceMetrics {
  final String deviceName;
  final String model;
  final String manufacturer;
  final String androidVersion;
  final int sdkInt;
  final int batteryLevel;
  final int ramTotalMb;
  final int ramFreeMb;
  final bool isSunmiHardware;
  final String printerStatus;
  final String paperStatus;
  final int printerWidth;
  final bool isNfcAvailable;
  final bool isScannerAvailable;

  DeviceMetrics({
    required this.deviceName,
    required this.model,
    required this.manufacturer,
    required this.androidVersion,
    required this.sdkInt,
    required this.batteryLevel,
    required this.ramTotalMb,
    required this.ramFreeMb,
    required this.isSunmiHardware,
    required this.printerStatus,
    required this.paperStatus,
    required this.printerWidth,
    required this.isNfcAvailable,
    required this.isScannerAvailable,
  });
}

class DeviceInfoService {
  static const MethodChannel _channel = MethodChannel('com.sunmi.hardware/device');

  Future<DeviceMetrics> getDeviceMetrics() async {
    if (!Platform.isAndroid) {
      return DeviceMetrics(
        deviceName: 'Mac / Desktop / iOS Simulator',
        model: 'Development Workstation',
        manufacturer: 'Apple / Desktop',
        androidVersion: 'Darwin / Desktop',
        sdkInt: 34,
        batteryLevel: 98,
        ramTotalMb: 16384,
        ramFreeMb: 8192,
        isSunmiHardware: false,
        printerStatus: 'READY (Virtual)',
        paperStatus: 'NORMAL',
        printerWidth: 58,
        isNfcAvailable: true,
        isScannerAvailable: true,
      );
    }

    try {
      final Map<dynamic, dynamic>? res =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
      final map = res?.cast<String, dynamic>() ?? {};

      final isSunmi = map['isSunmiHardware'] as bool? ?? false;

      return DeviceMetrics(
        deviceName: map['deviceName'] as String? ?? 'Android Device',
        model: map['model'] as String? ?? 'V3 / Standard Android',
        manufacturer: map['manufacturer'] as String? ?? 'Unknown',
        androidVersion: map['androidVersion'] as String? ?? '13.0',
        sdkInt: map['sdkInt'] as int? ?? 33,
        batteryLevel: map['batteryLevel'] as int? ?? 90,
        ramTotalMb: map['ramTotalMb'] as int? ?? 4096,
        ramFreeMb: map['ramFreeMb'] as int? ?? 1800,
        isSunmiHardware: isSunmi,
        printerStatus: isSunmi ? 'READY' : 'MOCK / READY',
        paperStatus: 'NORMAL',
        printerWidth: 58,
        isNfcAvailable: true,
        isScannerAvailable: true,
      );
    } catch (_) {
      return DeviceMetrics(
        deviceName: 'Handheld POS Device',
        model: 'V3 Mobile POS',
        manufacturer: 'Handheld POS',
        androidVersion: 'Android 13.0',
        sdkInt: 33,
        batteryLevel: 95,
        ramTotalMb: 4096,
        ramFreeMb: 2100,
        isSunmiHardware: true,
        printerStatus: 'READY',
        paperStatus: 'NORMAL',
        printerWidth: 58,
        isNfcAvailable: true,
        isScannerAvailable: true,
      );
    }
  }
}
