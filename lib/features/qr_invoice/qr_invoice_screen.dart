import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../native/sunmi_printer_service.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/widgets/receipt_preview_widget.dart';

class QRInvoiceScreen extends ConsumerStatefulWidget {
  const QRInvoiceScreen({super.key});

  @override
  ConsumerState<QRInvoiceScreen> createState() => _QRInvoiceScreenState();
}

class _QRInvoiceScreenState extends ConsumerState<QRInvoiceScreen> {
  late InvoiceModel _invoice;
  bool _isScannerOpen = false;
  String _transferStatus = 'Offline QR Transfer Mode Ready';
  String? _lastFailedPayload;

  @override
  void initState() {
    super.initState();
    _invoice = InvoiceModel.createSample();
  }

  void _onQrDetected(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      try {
        final reconstructed = InvoiceModel.fromCompactJsonString(raw);
        HapticFeedback.successNotification();
        setState(() {
          _invoice = reconstructed;
          _isScannerOpen = false;
          _lastFailedPayload = null;
          _transferStatus =
              'QR Scanned! Reconstructed Invoice #${reconstructed.invoiceNumber}';
        });
        break;
      } catch (_) {
        if (_lastFailedPayload != raw) {
          _lastFailedPayload = raw;
          HapticFeedback.errorNotification();
          setState(() {
            _transferStatus = 'Invalid QR — not a Printa invoice payload';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 8 – QR to Receipt Transfer'),
      ),
      body: Column(
        children: [
          // Banner Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppConstants.primaryOrange.withOpacity(0.12),
            child: Row(
              children: [
                const Icon(Icons.sync_alt_rounded, color: AppConstants.primaryOrange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _transferStatus,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Control Switch
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isScannerOpen = !_isScannerOpen;
                      });
                    },
                    icon: Icon(_isScannerOpen ? Icons.close_rounded : Icons.qr_code_scanner_rounded),
                    label: Text(_isScannerOpen ? 'Close Scanner' : 'Scan Invoice QR'),
                  ),
                ),
              ],
            ),
          ),

          // Main Area
          Expanded(
            child: _isScannerOpen
                ? Stack(
                    children: [
                      MobileScanner(
                        onDetect: _onQrDetected,
                      ),
                      Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange, width: 3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Encoded Invoice QR Code (Scan with another device)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        QrImageView(
                          data: _invoice.toCompactJsonString(),
                          version: QrVersions.auto,
                          size: 160,
                        ),
                        const SizedBox(height: 16),
                        ReceiptPreviewWidget(invoice: _invoice),
                      ],
                    ),
                  ),
          ),

          // Print Bar
          Container(
            padding: const EdgeInsets.all(14),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final printer = ref.read(sunmiPrinterServiceProvider);
                      await printer.printReceipt(_invoice);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Printed Transfer Invoice #${_invoice.invoiceNumber}!',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print Reconstructed Receipt'),
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
