import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../core/constants/app_constants.dart';
import '../../native/sunmi_printer_service.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/widgets/receipt_preview_widget.dart';

class NFCInvoiceScreen extends ConsumerStatefulWidget {
  const NFCInvoiceScreen({super.key});

  @override
  ConsumerState<NFCInvoiceScreen> createState() => _NFCInvoiceScreenState();
}

class _NFCInvoiceScreenState extends ConsumerState<NFCInvoiceScreen> {
  late InvoiceModel _currentInvoice;
  String _status = 'Ready to encode or read invoice via NFC';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _currentInvoice = InvoiceModel.createSample();
  }

  void _writeInvoiceToNfc() {
    setState(() {
      _isBusy = true;
      _status = 'Approach device to NFC tag to store invoice...';
    });

    final jsonStr = _currentInvoice.toCompactJsonString();

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      HapticFeedback.successNotification();
      final ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        setState(() {
          _isBusy = false;
          _status = 'NFC Tag is not writable!';
        });
        NfcManager.instance.stopSession();
        return;
      }

      final message = NdefMessage([NdefRecord.createText(jsonStr)]);
      try {
        await ndef.write(message);
        setState(() {
          _isBusy = false;
          _status = 'Invoice successfully encoded onto NFC Tag!';
        });
        NfcManager.instance.stopSession();
      } catch (e) {
        setState(() {
          _isBusy = false;
          _status = 'Write error: $e';
        });
        NfcManager.instance.stopSession();
      }
    });
  }

  void _readInvoiceFromNfc() {
    setState(() {
      _isBusy = true;
      _status = 'Hold device near encoded NFC tag to read...';
    });

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      HapticFeedback.successNotification();
      final ndef = Ndef.from(tag);
      String readJson = '';

      if (ndef != null && ndef.cachedMessage != null) {
        final records = ndef.cachedMessage!.records;
        if (records.isNotEmpty) {
          readJson = String.fromCharCodes(records.first.payload);
        }
      }

      if (readJson.isNotEmpty) {
        try {
          final reconstructed = InvoiceModel.fromCompactJsonString(readJson);
          setState(() {
            _currentInvoice = reconstructed;
            _isBusy = false;
            _status = 'NFC Read Success! Reconstructed Invoice #${reconstructed.invoiceNumber}';
          });
        } catch (_) {
          setState(() {
            _isBusy = false;
            _status = 'Tag read, but invalid JSON format: $readJson';
          });
        }
      } else {
        setState(() {
          _isBusy = false;
          _status = 'No NDEF payload found on tag.';
        });
      }

      NfcManager.instance.stopSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 7 – Invoice in NFC'),
      ),
      body: Column(
        children: [
          // Banner Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: AppConstants.primaryOrange.withOpacity(0.12),
            child: Row(
              children: [
                Icon(
                  Icons.nfc_rounded,
                  color: AppConstants.primaryOrange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBusy ? null : _writeInvoiceToNfc,
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Write to Tag'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _readInvoiceFromNfc,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Read & Rebuild'),
                  ),
                ),
              ],
            ),
          ),

          // Reconstructed Invoice Preview Stage
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ReceiptPreviewWidget(
                  invoice: _currentInvoice,
                ),
              ),
            ),
          ),

          // Print Bottom Action
          Container(
            padding: const EdgeInsets.all(14),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final printer = ref.read(sunmiPrinterServiceProvider);
                      await printer.printReceipt(_currentInvoice);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Printed NFC Reconstructed Invoice #${_currentInvoice.invoiceNumber}!',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print Reconstructed Invoice'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
