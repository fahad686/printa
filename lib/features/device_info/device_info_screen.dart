import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../native/device_info_service.dart';
import '../../shared/widgets/status_badge.dart';

class DeviceInfoScreen extends ConsumerWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceInfoService = ref.watch(deviceInfoServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 12 – Device Information'),
      ),
      body: FutureBuilder<DeviceMetrics>(
        future: deviceInfoService.getDeviceMetrics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppConstants.primaryOrange),
            );
          }

          final metrics = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // System Summary Banner
                Card(
                  color: AppConstants.primaryOrange.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: AppConstants.primaryOrange,
                          child: Icon(Icons.tablet_android_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${metrics.manufacturer} ${metrics.model}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Android ${metrics.androidVersion} (API ${metrics.sdkInt})',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge.success(
                          metrics.isSunmiHardware ? 'SUNMI HARDWARE' : 'VIRTUAL MOCK',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Hardware Capabilities List
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hardware Specifications & Modules',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Divider(),
                        _buildMetricRow('Device Name', metrics.deviceName),
                        _buildMetricRow('Model', metrics.model),
                        _buildMetricRow('Manufacturer', metrics.manufacturer),
                        _buildMetricRow('Android Version', metrics.androidVersion),
                        _buildMetricRow('Battery Level', '${metrics.batteryLevel}%'),
                        _buildMetricRow(
                            'RAM Total / Free', '${metrics.ramTotalMb}MB / ${metrics.ramFreeMb}MB'),
                        _buildMetricRow('Printer Status', metrics.printerStatus,
                            highlight: true),
                        _buildMetricRow('Paper Status', metrics.paperStatus),
                        _buildMetricRow('Printer Width', '${metrics.printerWidth} mm (2-inch)'),
                        _buildMetricRow(
                            'NFC Chip', metrics.isNfcAvailable ? 'Available' : 'N/A'),
                        _buildMetricRow('Laser Scanner',
                            metrics.isScannerAvailable ? 'Available / Camera Fallback' : 'N/A'),
                        _buildMetricRow('SUNMI SDK Version', AppConstants.appVersion),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: highlight ? AppConstants.primaryOrange : null,
            ),
          ),
        ],
      ),
    );
  }
}
