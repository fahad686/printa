import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/custom_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../native/device_info_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceInfoAsync = ref.watch(deviceInfoServiceProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.primaryOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.print_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'SUNMI Test Suite',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            FutureBuilder<DeviceMetrics>(
              future: deviceInfoAsync.getDeviceMetrics(),
              builder: (context, snapshot) {
                final metrics = snapshot.data;
                final isSunmi = metrics?.isSunmiHardware ?? false;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryOrange,
                        Colors.deepOrangeAccent.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryOrange.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.developer_board_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSunmi ? 'SUNMI V3 Active' : 'Virtual Engine Active',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Printer: ${metrics?.printerStatus ?? 'READY'} • Bat: ${metrics?.batteryLevel ?? 100}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge.success(isSunmi ? 'SUNMI HW' : 'VIRTUAL',
                          icon: isSunmi
                              ? Icons.verified_rounded
                              : Icons.laptop_chromebook_rounded),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            const Text(
              'Hardware & Testing Modules',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Grid Dashboard
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                _buildDashboardTile(
                  context,
                  title: 'Receipt Builder',
                  subtitle: 'Module 1',
                  icon: Icons.receipt_long_rounded,
                  color: Colors.orange,
                  route: '/receipt-builder',
                ),
                _buildDashboardTile(
                  context,
                  title: 'Templates',
                  subtitle: 'Module 2 • 8 Presets',
                  icon: Icons.dashboard_customize_rounded,
                  color: Colors.indigo,
                  route: '/receipt-templates',
                ),
                _buildDashboardTile(
                  context,
                  title: 'QR Generator',
                  subtitle: 'Module 3',
                  icon: Icons.qr_code_2_rounded,
                  color: Colors.teal,
                  route: '/qr-generator',
                ),
                _buildDashboardTile(
                  context,
                  title: 'Barcode Gen',
                  subtitle: 'Module 4 • 7 Format',
                  icon: Icons.qr_code_scanner_rounded,
                  color: Colors.blue,
                  route: '/barcode-generator',
                ),
                _buildDashboardTile(
                  context,
                  title: 'Scanner',
                  subtitle: 'Module 5 • Laser/Cam',
                  icon: Icons.center_focus_strong_rounded,
                  color: Colors.purple,
                  route: '/scanner',
                ),
                _buildDashboardTile(
                  context,
                  title: 'NFC Manager',
                  subtitle: 'Module 6 • Read/Write',
                  icon: Icons.nfc_rounded,
                  color: Colors.pink,
                  route: '/nfc',
                ),
                _buildDashboardTile(
                  context,
                  title: 'Invoice in NFC',
                  subtitle: 'Module 7 • Tap Sync',
                  icon: Icons.tap_and_play_rounded,
                  color: Colors.cyan,
                  route: '/nfc-invoice',
                ),
                _buildDashboardTile(
                  context,
                  title: 'QR to Receipt',
                  subtitle: 'Module 8 • Transfer',
                  icon: Icons.sync_alt_rounded,
                  color: Colors.deepOrange,
                  route: '/qr-invoice',
                ),
                _buildDashboardTile(
                  context,
                  title: 'PDF Generator',
                  subtitle: 'Module 9 • A4/58/80mm',
                  icon: Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent,
                  route: '/pdf-generator',
                ),
                _buildDashboardTile(
                  context,
                  title: 'SUNMI Printer',
                  subtitle: 'Module 10 • Bench',
                  icon: Icons.print_rounded,
                  color: Colors.amber.shade800,
                  route: '/sunmi-printer',
                ),
                _buildDashboardTile(
                  context,
                  title: 'History Box',
                  subtitle: 'Module 11 • Database',
                  icon: Icons.storage_rounded,
                  color: Colors.green,
                  route: '/history',
                ),
                _buildDashboardTile(
                  context,
                  title: 'Device Info',
                  subtitle: 'Module 12 • Hardware',
                  icon: Icons.perm_device_information_rounded,
                  color: Colors.blueGrey,
                  route: '/device-info',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(10),
      onTap: () => context.push(route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
