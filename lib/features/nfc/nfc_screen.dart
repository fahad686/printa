import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import 'nfc_helpers.dart';

class NFCScreen extends ConsumerStatefulWidget {
  const NFCScreen({super.key});

  @override
  ConsumerState<NFCScreen> createState() => _NFCScreenState();
}

class _NFCScreenState extends ConsumerState<NFCScreen> {
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    final available = await NfcHelpers.checkAvailability();
    if (mounted) setState(() => _isAvailable = available);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 6 – NFC Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Re-check NFC',
            onPressed: _checkNfc,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppConstants.primaryOrange.withOpacity(0.10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isAvailable ? Icons.nfc_rounded : Icons.warning_amber_rounded,
                    color: AppConstants.primaryOrange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAvailable
                              ? 'NFC Chip Available & Active'
                              : 'NFC Unavailable (check Android Settings)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Text(
                          'Choose an action below',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'NFC Operations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _NfcMenuTile(
            icon: Icons.sensors_rounded,
            color: AppConstants.primaryOrange,
            title: 'Read NFC Tag',
            subtitle: 'Scan tag, view UID, technology & payload',
            onTap: () => context.push('/nfc/read'),
          ),
          _NfcMenuTile(
            icon: Icons.edit_rounded,
            color: AppConstants.orangeDark,
            title: 'Write NFC Tag',
            subtitle: 'Write a new payload to a tag',
            onTap: () => context.push('/nfc/write'),
          ),
          _NfcMenuTile(
            icon: Icons.update_rounded,
            color: AppConstants.orangeLight,
            title: 'Update NFC Tag',
            subtitle: 'Replace existing tag data with new payload',
            onTap: () => context.push('/nfc/update'),
          ),
          _NfcMenuTile(
            icon: Icons.delete_forever_rounded,
            color: AppConstants.orangeDeep,
            title: 'Delete Tag Details',
            subtitle: 'Erase stored payload from a tag',
            onTap: () => context.push('/nfc/delete'),
          ),
        ],
      ),
    );
  }
}

class _NfcMenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NfcMenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: color),
        onTap: onTap,
      ),
    );
  }
}
