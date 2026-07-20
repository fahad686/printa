import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/utils/payload_validator.dart';
import '../../shared/widgets/validation_banner.dart';
import 'nfc_helpers.dart';

class NfcUpdateScreen extends ConsumerStatefulWidget {
  const NfcUpdateScreen({super.key});

  @override
  ConsumerState<NfcUpdateScreen> createState() => _NfcUpdateScreenState();
}

class _NfcUpdateScreenState extends ConsumerState<NfcUpdateScreen> {
  bool _isScanning = false;
  String _status = 'Enter new data and tap Update Tag';
  String _updateResult = '';
  String _oldPayload = '';
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final last = ref.read(nfcLastReadProvider);
    if (last != null && !last.payload.startsWith('(empty')) {
      _controller.text = last.payload;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ValidationResult get _validation {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return const ValidationResult(isValid: false, message: 'New payload cannot be empty');
    }
    if (text.startsWith('{')) {
      return PayloadValidator.validateInvoiceJson(text);
    }
    if (text.startsWith('http')) {
      return PayloadValidator.validateQrPayload('URL', text);
    }
    return ValidationResult.valid;
  }

  void _update() {
    if (!_validation.isValid) {
      setState(() => _status = _validation.message);
      return;
    }

    NfcHelpers.runSession(
      onScanning: (v) => setState(() => _isScanning = v),
      onStatus: (s) => setState(() => _status = s),
      onTag: (tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          setState(() => _status = 'Tag is not NDEF writable');
          return;
        }
        final oldPayload = NfcHelpers.decodeMessage(ndef.cachedMessage);
        final payloadType = _controller.text.trim().startsWith('http') ? 'URL' : 'Text';
        await ndef.write(NfcHelpers.buildMessage(
          text: _controller.text.trim(),
          payloadType: payloadType,
        ));
        setState(() {
          _oldPayload = oldPayload;
          _status = 'Tag updated successfully!';
          _updateResult = oldPayload.isEmpty
              ? 'Updated (was empty)'
              : 'Was: "$oldPayload" → "${_controller.text}"';
        });
        await NfcHelpers.saveHistory(ref,
            title: 'Updated NFC Tag',
            payload: _controller.text,
            subtitle: oldPayload.isEmpty ? null : 'Was: $oldPayload');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastRead = ref.watch(nfcLastReadProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Update NFC Tag')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (lastRead != null) ...[
              const SizedBox(height: 8),
              Text('Last read UID: ${lastRead.uid}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'New Data',
                suffixIcon: lastRead != null && !lastRead.payload.startsWith('(empty')
                    ? IconButton(
                        icon: const Icon(Icons.download_rounded),
                        tooltip: 'Load from last read',
                        onPressed: () => setState(() => _controller.text = lastRead.payload),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ValidationBanner(result: _validation),
            if (_updateResult.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_updateResult,
                  style: const TextStyle(
                      color: AppConstants.primaryOrange, fontSize: 12)),
              if (_oldPayload.isNotEmpty)
                Text('Previous: $_oldPayload',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryOrange,
              ),
              onPressed: _isScanning || !_validation.isValid ? null : _update,
              icon: const Icon(Icons.update_rounded),
              label: Text(_isScanning ? 'Waiting for tag...' : 'Update Tag'),
            ),
          ],
        ),
      ),
    );
  }
}
