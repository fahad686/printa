import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'nfc_helpers.dart';

class NfcDeleteScreen extends ConsumerStatefulWidget {
  const NfcDeleteScreen({super.key});

  @override
  ConsumerState<NfcDeleteScreen> createState() => _NfcDeleteScreenState();
}

class _NfcDeleteScreenState extends ConsumerState<NfcDeleteScreen> {
  bool _isScanning = false;
  String _status = 'Tap Erase Tag Details and hold device near tag';
  String _deleteResult = '';

  void _erase() {
    NfcHelpers.runSession(
      onScanning: (v) => setState(() => _isScanning = v),
      onStatus: (s) => setState(() => _status = s),
      onTag: (tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          setState(() => _status = 'Tag is not NDEF writable');
          return;
        }
        final previous = NfcHelpers.decodeMessage(ndef.cachedMessage);
        await ndef.write(NfcHelpers.emptyMessage());
        final uid = NfcHelpers.extractUid(tag);
        setState(() {
          _status = 'Tag details erased successfully';
          _deleteResult = previous.isEmpty
              ? 'Erased empty tag (UID: $uid)'
              : 'Erased "$previous" from UID $uid';
        });
        await NfcHelpers.saveHistory(ref,
            title: 'Erased NFC Tag', payload: '(erased)', subtitle: 'UID: $uid');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Tag Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This removes stored payload. The tag stays usable and can be written again.',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(_status, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (_deleteResult.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_deleteResult,
                  style: TextStyle(color: Colors.redAccent.shade200, fontSize: 12)),
            ],
            const Spacer(),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: _isScanning ? null : _erase,
              icon: const Icon(Icons.delete_forever_rounded),
              label: Text(_isScanning ? 'Waiting for tag...' : 'Erase Tag Details'),
            ),
          ],
        ),
      ),
    );
  }
}
