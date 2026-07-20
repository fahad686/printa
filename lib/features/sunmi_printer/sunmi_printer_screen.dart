import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../native/sunmi_printer_service.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/widgets/status_badge.dart';

class SunmiPrinterScreen extends ConsumerStatefulWidget {
  const SunmiPrinterScreen({super.key});

  @override
  ConsumerState<SunmiPrinterScreen> createState() => _SunmiPrinterScreenState();
}

class _SunmiPrinterScreenState extends ConsumerState<SunmiPrinterScreen> {
  final TextEditingController _textController =
      TextEditingController(text: 'SUNMI V3 Thermal Test Line');

  int _align = 1; // 0: Left, 1: Center, 2: Right
  bool _isBold = true;
  bool _isUnderline = false;
  int _fontSize = 24;

  String _printerStatus = 'Querying...';
  String _paperStatus = 'Querying...';

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final printer = ref.read(sunmiPrinterServiceProvider);
    final status = await printer.getPrinterStatus();
    final paper = await printer.getPaperStatus();

    if (mounted) {
      setState(() {
        _printerStatus = status;
        _paperStatus = paper;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final printer = ref.watch(sunmiPrinterServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 10 – SUNMI Thermal Bench'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshStatus,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hardware Status',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Printer: $_printerStatus • Paper: $_paperStatus',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    StatusBadge.success('PRINTER READY'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Text Printer Test Panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Direct Text Command',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _textController,
                      decoration: const InputDecoration(labelText: 'Text Content'),
                    ),
                    const SizedBox(height: 12),

                    // Styling Controls
                    Row(
                      children: [
                        const Text('Align: '),
                        const SizedBox(width: 8),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 0, label: Text('Left')),
                            ButtonSegment(value: 1, label: Text('Center')),
                            ButtonSegment(value: 2, label: Text('Right')),
                          ],
                          selected: {_align},
                          onSelectionChanged: (val) =>
                              setState(() => _align = val.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        FilterChip(
                          label: const Text('Bold'),
                          selected: _isBold,
                          onSelected: (val) => setState(() => _isBold = val),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Underline'),
                          selected: _isUnderline,
                          onSelected: (val) => setState(() => _isUnderline = val),
                        ),
                        const SizedBox(width: 16),
                        Text('Font: $_fontSize'),
                        Expanded(
                          child: Slider(
                            value: _fontSize.toDouble(),
                            min: 16,
                            max: 36,
                            divisions: 10,
                            activeColor: AppConstants.primaryOrange,
                            onChanged: (v) => setState(() => _fontSize = v.toInt()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await printer.printText(
                          text: _textController.text,
                          align: _align,
                          isBold: _isBold,
                          isUnderline: _isUnderline,
                          fontSize: _fontSize,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Printed text command!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Print Text Line'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Command Grid Bench
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thermal Command Bench',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => printer.printTable(
                            colsText: ['Item', 'Qty', 'Price'],
                            colsWidth: [14, 4, 10],
                            colsAlign: [0, 1, 2],
                          ),
                          icon: const Icon(Icons.table_chart_rounded),
                          label: const Text('Print Table'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => printer.printQRCode(data: 'SUNMI-V3-TEST'),
                          icon: const Icon(Icons.qr_code_rounded),
                          label: const Text('Print QR'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => printer.printBarCode(data: '88920194'),
                          icon: const Icon(Icons.barcode_reader),
                          label: const Text('Print Barcode'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => printer.printText(
                            text: '--------------------------------',
                            align: 1,
                          ),
                          icon: const Icon(Icons.horizontal_rule_rounded),
                          label: const Text('Print Divider'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => printer.feedPaper(lines: 4),
                          icon: const Icon(Icons.keyboard_double_arrow_down_rounded),
                          label: const Text('Feed Paper (4 lines)'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => printer.cutPaper(),
                          icon: const Icon(Icons.content_cut_rounded),
                          label: const Text('Cut Paper'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => printer.printReceipt(InvoiceModel.createSample()),
                          icon: const Icon(Icons.receipt_long_rounded),
                          label: const Text('Print Full Sample Receipt'),
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
}
