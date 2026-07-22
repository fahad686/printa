import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
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
  String? _scanFormat;
  bool _isDialogOpen = false;
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  bool get _isUrl {
    final v = _scannedValue;
    if (v == null) return false;
    return v.startsWith('http://') || v.startsWith('https://');
  }

  String get _dataTypeLabel {
    final v = _scannedValue;
    if (v == null) return 'Waiting';
    if (_isUrl) return 'URL';
    if (v.contains('{') && v.contains('}')) return 'JSON / Invoice';
    if (RegExp(r'^\d+$').hasMatch(v)) return 'Numeric';
    return 'Text';
  }

  IconData get _dataTypeIcon {
    switch (_dataTypeLabel) {
      case 'URL':
        return Icons.link_rounded;
      case 'JSON / Invoice':
        return Icons.receipt_long_rounded;
      case 'Numeric':
        return Icons.pin_rounded;
      case 'Text':
        return Icons.text_snippet_rounded;
      default:
        return Icons.qr_code_2_rounded;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isDialogOpen) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw == _scannedValue) continue;

      HapticFeedback.successNotification();
      final format = barcode.format.name;
      setState(() {
        _scannedValue = raw;
        _scanFormat = format;
      });
      _saveToHistory(raw);
      _showScanResultDialog(raw, format);
      break;
    }
  }

  Future<void> _showScanResultDialog(String value, String format) async {
    if (!mounted) return;
    _isDialogOpen = true;
    await _cameraController.stop();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppConstants.primaryOrange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Scan Successful',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                format.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.35,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppConstants.primaryOrange.withOpacity(0.2),
                      ),
                    ),
                    child: SelectableText(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );

    _isDialogOpen = false;
    if (mounted) {
      await _cameraController.start();
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
    if (_scannedValue == null) return;
    Clipboard.setData(ClipboardData(text: _scannedValue!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _openUrl() async {
    if (!_isUrl) return;
    final uri = Uri.parse(_scannedValue!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        invoiceNumber:
            'SCN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
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

  void _clearScan() {
    setState(() {
      _scannedValue = null;
      _scanFormat = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scannerService = ref.watch(sunmiScannerServiceProvider);
    final theme = Theme.of(context);
    final hasScan = _scannedValue != null;

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
                      border: Border.all(
                        color: AppConstants.primaryOrange,
                        width: 3,
                      ),
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
                      if (!mounted) return;
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
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: hasScan ? _buildResultPanel(theme) : _buildEmptyPanel(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 40,
            color: theme.colorScheme.primary.withOpacity(0.45),
          ),
          const SizedBox(height: 12),
          Text(
            'Ready to scan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Point the camera at a QR code or barcode.\nResults will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.orangeSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_dataTypeIcon, size: 16, color: AppConstants.primaryOrange),
                    const SizedBox(width: 6),
                    Text(
                      _dataTypeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              if (_scanFormat != null) ...[
                const SizedBox(width: 8),
                Text(
                  _scanFormat!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.hintColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                tooltip: 'Clear',
                visualDensity: VisualDensity.compact,
                onPressed: _clearScan,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryOrange.withOpacity(0.18),
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _scannedValue!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                  onPressed: _isUrl ? _openUrl : null,
                  icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                  label: const Text('Open'),
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
    );
  }
}
