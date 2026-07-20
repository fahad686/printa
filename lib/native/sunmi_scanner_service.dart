import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sunmiScannerServiceProvider = Provider<SunmiScannerService>((ref) {
  return SunmiScannerService();
});

class SunmiScannerService {
  static const MethodChannel _channel = MethodChannel('com.sunmi.hardware/scanner');

  Future<String> getScannerStatus() async {
    try {
      final String? status = await _channel.invokeMethod<String>('getScannerStatus');
      return status ?? 'CAMERA_ONLY';
    } catch (_) {
      return 'CAMERA_ONLY';
    }
  }

  Future<bool> triggerHardwareScan() async {
    try {
      final bool? res = await _channel.invokeMethod<bool>('sendScan');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
