import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/history_item_model.dart';
import '../../shared/repositories/history_repository.dart';

class NFCScreen extends ConsumerStatefulWidget {
  const NFCScreen({super.key});

  @override
  ConsumerState<NFCScreen> createState() => _NFCScreenState();
}

class _NFCScreenState extends ConsumerState<NFCScreen> {
  bool _isAvailable = false;
  bool _isScanning = false;
  String _nfcStatus = 'Tap "Start Read Session" to scan NFC tag';

  String _nfcUid = 'N/A';
  String _nfcTech = 'N/A';
  String _nfcPayload = 'No tag read yet';

  String _payloadType = 'Text';
  final TextEditingController _writeController =
      TextEditingController(text: 'SUNMI POS Smart NFC Tag Data');

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    final available = await NfcManager.instance.isAvailable();
    setState(() {
      _isAvailable = available;
    });
  }

  void _startNfcRead() {
    setState(() {
      _isScanning = true;
      _nfcStatus = 'Hold SUNMI device near NFC tag...';
    });

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      final ndef = Ndef.from(tag);

      String readPayload = 'No NDEF payload found';
      if (ndef != null && ndef.cachedMessage != null) {
        final records = ndef.cachedMessage!.records;
        if (records.isNotEmpty) {
          readPayload = String.fromCharCodes(records.first.payload);
        }
      }

      setState(() {
        _isScanning = false;
        _nfcStatus = 'NFC Tag Discovered!';
        _nfcUid = 'Tag_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        _nfcTech = ndef != null ? 'NDEF Formatted' : 'ISO-14443 Type A/B';
        _nfcPayload = readPayload;
      });

      // Save to Hive
      await ref.read(historyRepositoryProvider).addHistoryItem(
            HistoryItemModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Read NFC Tag',
              category: 'nfc',
              timestamp: DateTime.now(),
              payload: readPayload,
              subtitle: _nfcTech,
            ),
          );

      NfcManager.instance.stopSession();
    });
  }

  void _startNfcWrite() {
    setState(() {
      _isScanning = true;
      _nfcStatus = 'Approach NFC Tag to write payload...';
    });

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        setState(() {
          _isScanning = false;
          _nfcStatus = 'Error: NFC Tag is not NDEF writable!';
        });
        NfcManager.instance.stopSession(errorMessage: 'Tag not writable');
        return;
      }

      NdefMessage message = NdefMessage([
        NdefRecord.createText(_writeController.text),
      ]);

      try {
        await ndef.write(message);
        setState(() {
          _isScanning = false;
          _nfcStatus = 'Successfully wrote payload to NFC Tag!';
        });

        await ref.read(historyRepositoryProvider).addHistoryItem(
              HistoryItemModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'Wrote NFC Tag',
                category: 'nfc',
                timestamp: DateTime.now(),
                payload: _writeController.text,
              ),
            );

        NfcManager.instance.stopSession();
      } catch (e) {
        setState(() {
          _isScanning = false;
          _nfcStatus = 'Write Failed: $e';
        });
        NfcManager.instance.stopSession(errorMessage: 'Write failed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 6 – NFC Manager'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Card(
              color: _isAvailable
                  ? Colors.green.withOpacity(0.08)
                  : Colors.amber.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isAvailable
                          ? Icons.nfc_rounded
                          : Icons.warning_amber_rounded,
                      color: _isAvailable ? Colors.green : Colors.amber,
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
                                : 'Virtual NFC Engine Active (Simulator Mode)',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            _nfcStatus,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Read Info Panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tag Details & Payload',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(),
                    _buildInfoRow('UID', _nfcUid),
                    _buildInfoRow('Technology', _nfcTech),
                    _buildInfoRow('Payload', _nfcPayload, isBold: true),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _startNfcRead,
                      icon: const Icon(Icons.sensors_rounded),
                      label: Text(_isScanning ? 'Scanning...' : 'Start Read Session'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Write Panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Write to NFC Tag',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _payloadType,
                      decoration: const InputDecoration(labelText: 'Payload Type'),
                      items: ['Text', 'URL', 'Invoice JSON', 'Business Card', 'WiFi']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _payloadType = val;
                            if (val == 'URL') {
                              _writeController.text = 'https://sunmi.com';
                            } else if (val == 'Invoice JSON') {
                              _writeController.text = '{"id":"INV1001","customer":"Ali","total":2500}';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _writeController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Write Data'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryOrange,
                            ),
                            onPressed: _startNfcWrite,
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Write Tag'),
                          ),
                        ),
                      ],
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

  Widget _buildInfoRow(String title, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              val,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
