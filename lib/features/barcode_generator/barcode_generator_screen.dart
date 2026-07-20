import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../native/sunmi_printer_service.dart';
import '../../shared/models/history_item_model.dart';
import '../../shared/repositories/history_repository.dart';

class BarcodeGeneratorScreen extends ConsumerStatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  ConsumerState<BarcodeGeneratorScreen> createState() =>
      _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends ConsumerState<BarcodeGeneratorScreen> {
  String _selectedSymbology = 'Code128';
  final TextEditingController _codeController =
      TextEditingController(text: 'SUNMI-992014');

  final Map<String, Barcode> _barcodeMap = {
    'Code128': Barcode.code128(),
    'Code39': Barcode.code39(),
    'EAN13': Barcode.ean13(),
    'EAN8': Barcode.ean8(),
    'UPC-A': Barcode.upcA(),
    'PDF417': Barcode.pdf417(),
    'Data Matrix': Barcode.dataMatrix(),
  };

  void _onSymbologyChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedSymbology = val;
      switch (val) {
        case 'EAN13':
          _codeController.text = '9780201379624';
          break;
        case 'EAN8':
          _codeController.text = '96385074';
          break;
        case 'UPC-A':
          _codeController.text = '012345678905';
          break;
        default:
          _codeController.text = 'SUNMI-992014';
      }
    });
  }

  Future<void> _printBarcode() async {
    final printer = ref.read(sunmiPrinterServiceProvider);
    await printer.printBarCode(data: _codeController.text);

    await ref.read(historyRepositoryProvider).addHistoryItem(
          HistoryItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Barcode ($_selectedSymbology)',
            category: 'barcode',
            timestamp: DateTime.now(),
            payload: _codeController.text,
          ),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode printed on SUNMI device!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final barcode = _barcodeMap[_selectedSymbology] ?? Barcode.code128();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 4 – Barcode Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barcode Display Stage
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: BarcodeWidget(
                        barcode: barcode,
                        data: _codeController.text.isEmpty
                            ? '123456'
                            : _codeController.text,
                        color: Colors.black,
                        drawText: true,
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Format: $_selectedSymbology',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSymbology,
                      decoration: const InputDecoration(labelText: 'Symbology'),
                      items: _barcodeMap.keys.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: _onSymbologyChanged,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _codeController,
                      decoration:
                          const InputDecoration(labelText: 'Barcode Content / SKU'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _printBarcode,
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print Barcode'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Share.share(_codeController.text),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share Code'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
