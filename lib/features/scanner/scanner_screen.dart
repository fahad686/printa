import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../native/sunmi_printer_service.dart';
import '../../native/sunmi_scanner_service.dart';
import '../../shared/models/history_item_model.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/repositories/history_repository.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  String? _scannedValue;
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue != _scannedValue) {
        setState(() {
          _scannedValue = barcode.rawValue;
        });
        _saveToHistory(_scannedValue!);
        break;
      }
    }
  }

  Future<void> _saveToHistory(String val) async {
    await ref.read(historyRepositoryProvider).addHistoryItem(
          HistoryItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Scanned Code',
            category: 'scan',
            timestamp: DateTime.now(),
            payload: val,
          ),
        );
  }

  void _copyToClipboard() {
    if (_scannedValue != null) {
      Clipboard.setData(ClipboardData(text: _scannedValue!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied raw value to clipboard!')),
      );
    }
  }

  Future<void> _openUrl() async {
    if (_scannedValue != null && _scannedValue!.startsWith('http')) {
      final uri = Uri.parse(_scannedValue!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _generateAndPrintReceipt() async {
    if (_scannedValue == null) return;

    InvoiceModel inv;
    try {
      inv = InvoiceModel.fromCompactJsonString(_scannedValue!);
    } catch (_) {
      inv = InvoiceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        companyName: 'Scanned Data Sales',
        customerName: 'Customer',
        invoiceNumber: 'SCN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        date: DateTime.now(),
        items: [
          InvoiceItem(
            id: '1',
            name: _scannedValue!,
            quantity: 1,
            unitPrice: 19.99,
          ),
        ],
      );
    }

    final printer = ref.read(sunmiPrinterServiceProvider);
    await printer.printReceipt(inv);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printed receipt for ${_scannedValue!}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerService = ref.watch(sunmiScannerServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 5 – Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Viewport
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _cameraController,
                  onDetect: _onDetect,
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
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await scannerService.triggerHardwareScan();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Triggered hardware laser scanner!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.barcode_reader),
                    label: const Text('Trigger Hardware Scanner'),
                  ),
                ),
              ],
            ),
          ),

          // Scanned Result Actions Panel
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scanned Output:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      _scannedValue ?? 'Point camera at any QR or Barcode...',
                      style: TextStyle(
                        fontSize: 13,
                        color: _scannedValue != null
                            ? Theme.of(context).textTheme.bodyMedium?.color
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openUrl,
                          icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                          label: const Text('Open URL'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generateAndPrintReceipt,
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text('Receipt'),
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
    );
  }
}
