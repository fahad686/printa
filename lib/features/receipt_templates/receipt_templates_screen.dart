import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../native/sunmi_printer_service.dart';
import '../../shared/models/receipt_template_model.dart';
import '../../shared/widgets/receipt_preview_widget.dart';

class ReceiptTemplatesScreen extends ConsumerStatefulWidget {
  const ReceiptTemplatesScreen({super.key});

  @override
  ConsumerState<ReceiptTemplatesScreen> createState() => _ReceiptTemplatesScreenState();
}

class _ReceiptTemplatesScreenState extends ConsumerState<ReceiptTemplatesScreen> {
  late List<ReceiptTemplateModel> _templates;
  late ReceiptTemplateModel _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _templates = ReceiptTemplateModel.defaultTemplates;
    _selectedTemplate = _templates.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 2 – Receipt Templates'),
      ),
      body: Column(
        children: [
          // Horizontal Selector Bar
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final tpl = _templates[index];
                final isSelected = tpl.id == _selectedTemplate.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tpl.title),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTemplate = tpl;
                        });
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Template Details Banner
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedTemplate.title} (${_selectedTemplate.category})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            _selectedTemplate.description,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Real-time Preview Stage
          Expanded(
            child: Container(
              color: Colors.black.withOpacity(0.04),
              child: Center(
                child: SingleChildScrollView(
                  child: ReceiptPreviewWidget(
                    invoice: _selectedTemplate.sampleInvoice,
                    templateType: _selectedTemplate.type,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(14),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final printer = ref.read(sunmiPrinterServiceProvider);
                      final isSunmi = await printer.isSunmiHardware();
                      final status = await printer.getPrinterStatus();
                      await printer.printReceipt(_selectedTemplate.sampleInvoice);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isSunmi
                                  ? 'Printed ${_selectedTemplate.title} on SUNMI V3 ($status)'
                                  : 'Printed ${_selectedTemplate.title} Template!',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: Text('Print ${_selectedTemplate.title}'),
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
