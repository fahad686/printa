import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/utils/payload_validator.dart';
import '../../shared/widgets/validation_banner.dart';
import 'nfc_helpers.dart';

class NfcReadScreen extends ConsumerStatefulWidget {
  const NfcReadScreen({super.key});

  @override
  ConsumerState<NfcReadScreen> createState() => _NfcReadScreenState();
}

class _NfcReadScreenState extends ConsumerState<NfcReadScreen> {
  bool _isScanning = false;
  String _status = 'Tap Start Read Session and hold device near tag';
  NfcTagData? _tagData;
  String _readResult = '';

  void _startRead() {
    NfcHelpers.runSession(
      onScanning: (v) => setState(() => _isScanning = v),
      onStatus: (s) => setState(() => _status = s),
      onTag: (tag) async {
        final data = NfcHelpers.captureTagData(tag);
        ref.read(nfcLastReadProvider.notifier).state = data;
        setState(() {
          _tagData = data;
          _status = 'NFC Tag Discovered!';
          _readResult = 'Read at ${DateTime.now().toString().substring(11, 19)}';
        });
        await NfcHelpers.saveHistory(ref,
            title: 'Read NFC Tag',
            payload: data.payload.startsWith('(empty') ? '(empty)' : data.payload,
            subtitle: 'UID: ${data.uid}');
      },
    );
  }

  ValidationResult get _payloadValidation {
    if (_tagData == null || _tagData!.payload.startsWith('(empty')) {
      return const ValidationResult(isValid: false, message: 'No readable payload yet');
    }
    if (_tagData!.payload.trim().startsWith('{')) {
      return PayloadValidator.validateInvoiceJson(_tagData!.payload);
    }
    return ValidationResult.valid;
  }

  void _showQr() {
    final payload = _tagData?.payload ?? '';
    if (payload.isEmpty || payload.startsWith('(empty')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Read a tag with payload first')),
      );
      return;
    }
    final validation = _payloadValidation;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('QR from NFC Payload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValidationBanner(result: validation),
            const SizedBox(height: 12),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: QrImageView(data: payload, version: QrVersions.auto, size: 200),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: payload));
              Navigator.pop(ctx);
            },
            child: const Text('Copy'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Read NFC Tag')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            if (_tagData != null) ...[
              _DetailCard(
                title: 'Tag Details',
                rows: {
                  'UID': _tagData!.uid,
                  'Technology': _tagData!.tech,
                  'Writable': _tagData!.writable,
                  'Capacity': _tagData!.capacity,
                  'Payload': _tagData!.payload,
                },
              ),
              const SizedBox(height: 12),
              ValidationBanner(result: _payloadValidation),
              if (_readResult.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_readResult,
                    style: const TextStyle(
                        color: AppConstants.primaryOrange, fontSize: 12)),
              ],
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _startRead,
                    icon: const Icon(Icons.sensors_rounded),
                    label: Text(_isScanning ? 'Scanning...' : 'Start Read Session'),
                  ),
                ),
                if (_isScanning) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
                    onPressed: () {
                      NfcHelpers.stopSession();
                      setState(() {
                        _isScanning = false;
                        _status = 'Session cancelled';
                      });
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _tagData != null ? _showQr : null,
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Generate QR from Payload'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final Map<String, String> rows;

  const _DetailCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ...rows.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(e.key, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontWeight: e.key == 'Payload' ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
