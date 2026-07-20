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
      TextEditingController(text: 'Thermal printer test line');

  int _align = 1;
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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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

  bool get _isReady =>
      _printerStatus.toUpperCase().contains('READY') ||
      _printerStatus == '1';

  @override
  Widget build(BuildContext context) {
    final printer = ref.watch(sunmiPrinterServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Test Bench'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh status',
            onPressed: _refreshStatus,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hardware Status',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Printer: $_printerStatus',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Paper: $_paperStatus',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _isReady
                          ? StatusBadge.success('READY')
                          : StatusBadge.warning('CHECK'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

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
                      decoration: const InputDecoration(
                        labelText: 'Text Content',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Alignment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            label: Text('Left'),
                            icon: Icon(Icons.format_align_left, size: 16),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text('Center'),
                            icon: Icon(Icons.format_align_center, size: 16),
                          ),
                          ButtonSegment(
                            value: 2,
                            label: Text('Right'),
                            icon: Icon(Icons.format_align_right, size: 16),
                          ),
                        ],
                        selected: {_align},
                        onSelectionChanged: (val) => setState(() => _align = val.first),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilterChip(
                          label: const Text('Bold'),
                          selected: _isBold,
                          onSelected: (val) => setState(() => _isBold = val),
                        ),
                        FilterChip(
                          label: const Text('Underline'),
                          selected: _isUnderline,
                          onSelected: (val) => setState(() => _isUnderline = val),
                        ),
                        Chip(label: Text('Font $_fontSize')),
                      ],
                    ),
                    Slider(
                      value: _fontSize.toDouble(),
                      min: 16,
                      max: 36,
                      divisions: 10,
                      label: '$_fontSize',
                      activeColor: AppConstants.primaryOrange,
                      onChanged: (v) => setState(() => _fontSize = v.toInt()),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
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
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

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
                    const SizedBox(height: 4),
                    Text(
                      'Quick actions for tables, codes, feed & cut',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => printer.printTable(
                            colsText: ['Item', 'Qty', 'Price'],
                            colsWidth: [14, 4, 10],
                            colsAlign: [0, 1, 2],
                          ),
                          icon: const Icon(Icons.table_chart_rounded, size: 18),
                          label: const Text('Table'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => printer.printQRCode(data: 'PRINTA-TEST'),
                          icon: const Icon(Icons.qr_code_rounded, size: 18),
                          label: const Text('QR'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => printer.printBarCode(data: '88920194'),
                          icon: const Icon(Icons.barcode_reader, size: 18),
                          label: const Text('Barcode'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => printer.printText(
                            text: '--------------------------------',
                            align: 1,
                          ),
                          icon: const Icon(Icons.horizontal_rule_rounded, size: 18),
                          label: const Text('Divider'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => printer.feedPaper(lines: 4),
                          icon: const Icon(Icons.keyboard_double_arrow_down_rounded, size: 18),
                          label: const Text('Feed'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => printer.cutPaper(),
                          icon: const Icon(Icons.content_cut_rounded, size: 18),
                          label: const Text('Cut'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => printer.printReceipt(InvoiceModel.createSample()),
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('Print Full Sample Receipt'),
                      ),
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
