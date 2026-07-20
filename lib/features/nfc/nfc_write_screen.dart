import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/utils/payload_validator.dart';
import '../../shared/widgets/validation_banner.dart';
import 'nfc_helpers.dart';

class NfcWriteScreen extends ConsumerStatefulWidget {
  const NfcWriteScreen({super.key});

  @override
  ConsumerState<NfcWriteScreen> createState() => _NfcWriteScreenState();
}

class _NfcWriteScreenState extends ConsumerState<NfcWriteScreen> {
  bool _isScanning = false;
  String _status = 'Enter data and tap Write Tag';
  String _payloadType = 'Text';
  String _writeResult = '';
  String _lastUid = 'N/A';
  final _controller = TextEditingController(text: 'Printa Smart NFC Tag Data');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ValidationResult get _validation {
    if (_payloadType == 'Invoice JSON') {
      return PayloadValidator.validateInvoiceJson(_controller.text);
    }
    if (_payloadType == 'URL') {
      return PayloadValidator.validateQrPayload('URL', _controller.text);
    }
    if (_controller.text.trim().isEmpty) {
      return const ValidationResult(isValid: false, message: 'Payload cannot be empty');
    }
    return ValidationResult.valid;
  }

  void _write() {
    final validation = _validation;
    if (!validation.isValid) {
      setState(() => _status = validation.message);
      return;
    }

    NfcHelpers.runSession(
      onScanning: (v) => setState(() => _isScanning = v),
      onStatus: (s) => setState(() => _status = s),
      onTag: (tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          setState(() {
            _status = 'Tag is not NDEF writable';
            _writeResult = 'Failed — not writable';
          });
          return;
        }
        await ndef.write(NfcHelpers.buildMessage(
          text: _controller.text.trim(),
          payloadType: _payloadType,
        ));
        final uid = NfcHelpers.extractUid(tag);
        setState(() {
          _lastUid = uid;
          _status = 'Successfully wrote payload!';
          _writeResult = 'Wrote to UID $uid';
        });
        await NfcHelpers.saveHistory(ref, title: 'Wrote NFC Tag', payload: _controller.text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write NFC Tag')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _payloadType,
              decoration: const InputDecoration(labelText: 'Payload Type'),
              items: ['Text', 'URL', 'Invoice JSON']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _payloadType = val;
                  if (val == 'URL') {
                    _controller.text = 'https://printa.app';
                  } else if (val == 'Invoice JSON') {
                    _controller.text =
                        '{"id":"INV1001","inv_num":"INV1001","customer":"Ali","total":2500}';
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Write Data'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ValidationBanner(result: _validation),
            if (_writeResult.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Last: $_writeResult (UID: $_lastUid)',
                  style: const TextStyle(
                      color: AppConstants.primaryOrange, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryOrange),
              onPressed: _isScanning || !_validation.isValid ? null : _write,
              icon: const Icon(Icons.edit_rounded),
              label: Text(_isScanning ? 'Waiting for tag...' : 'Write Tag'),
            ),
          ],
        ),
      ),
    );
  }
}
