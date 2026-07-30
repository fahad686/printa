import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/widgets/invoice_line_item_editor.dart';
import 'pdf_flow_providers.dart';

/// Step 1 — edit invoice details before generating a PDF.
class PdfEditScreen extends ConsumerStatefulWidget {
  const PdfEditScreen({super.key});

  @override
  ConsumerState<PdfEditScreen> createState() => _PdfEditScreenState();
}

class _PdfEditScreenState extends ConsumerState<PdfEditScreen> {
  late TextEditingController _companyController;
  late TextEditingController _customerController;
  late TextEditingController _invoiceNumController;
  late TextEditingController _currencyController;
  late TextEditingController _taxController;
  late TextEditingController _discountController;
  late TextEditingController _notesController;
  late TextEditingController _tableController;
  late TextEditingController _orderTypeController;
  late List<InvoiceItem> _items;

  @override
  void initState() {
    super.initState();
    final inv = ref.read(pdfDraftInvoiceProvider);
    _companyController = TextEditingController(text: inv.companyName);
    _customerController = TextEditingController(text: inv.customerName);
    _invoiceNumController = TextEditingController(text: inv.invoiceNumber);
    _currencyController = TextEditingController(text: inv.currency);
    _taxController = TextEditingController(text: inv.taxPercentage.toString());
    _discountController =
        TextEditingController(text: inv.discountPercentage.toString());
    _notesController = TextEditingController(text: inv.notes ?? '');
    _tableController = TextEditingController(text: inv.tableNo ?? '');
    _orderTypeController = TextEditingController(text: inv.orderType ?? '');
    _items = inv.items.map((i) => i.copyWith()).toList();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _customerController.dispose();
    _invoiceNumController.dispose();
    _currencyController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    _tableController.dispose();
    _orderTypeController.dispose();
    super.dispose();
  }

  InvoiceModel _buildInvoice() {
    final notes = _notesController.text.trim();
    final table = _tableController.text.trim();
    final orderType = _orderTypeController.text.trim();
    return InvoiceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      companyName: _companyController.text.trim().isEmpty
          ? 'Printa Store'
          : _companyController.text.trim(),
      customerName: _customerController.text.trim().isEmpty
          ? 'Customer'
          : _customerController.text.trim(),
      invoiceNumber: _invoiceNumController.text.trim().isEmpty
          ? 'INV-001'
          : _invoiceNumController.text.trim(),
      date: DateTime.now(),
      currency: _currencyController.text.trim().isEmpty
          ? '\$'
          : _currencyController.text.trim(),
      taxPercentage: double.tryParse(_taxController.text) ?? 0,
      discountPercentage: double.tryParse(_discountController.text) ?? 0,
      items: List.from(_items),
      notes: notes.isEmpty ? null : notes,
      tableNo: table.isEmpty ? null : table,
      orderType: orderType.isEmpty ? null : orderType,
    );
  }

  void _persistDraft() {
    ref.read(pdfDraftInvoiceProvider.notifier).state = _buildInvoice();
  }

  void _continueToPreview() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item')),
      );
      return;
    }
    _persistDraft();
    context.push('/pdf-generator/preview');
  }

  void _resetSample() {
    final sample = InvoiceModel.createSample();
    ref.read(pdfDraftInvoiceProvider.notifier).state = sample;
    setState(() {
      _companyController.text = sample.companyName;
      _customerController.text = sample.customerName;
      _invoiceNumController.text = sample.invoiceNumber;
      _currencyController.text = sample.currency;
      _taxController.text = sample.taxPercentage.toString();
      _discountController.text = sample.discountPercentage.toString();
      _notesController.text = sample.notes ?? '';
      _tableController.text = sample.tableNo ?? '';
      _orderTypeController.text = sample.orderType ?? '';
      _items = sample.items.map((i) => i.copyWith()).toList();
    });
  }

  void _addItem() {
    setState(() {
      _items.add(
        InvoiceItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'New Item',
          quantity: 1,
          unitPrice: 10,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _buildInvoice();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Generator'),
        actions: [
          IconButton(
            tooltip: 'Load sample',
            onPressed: _resetSample,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _StepHeader(step: 1, total: 2, label: 'Edit invoice details'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invoice header',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _companyController,
                          decoration: const InputDecoration(labelText: 'Company Name'),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _customerController,
                                decoration:
                                    const InputDecoration(labelText: 'Customer'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _invoiceNumController,
                                decoration:
                                    const InputDecoration(labelText: 'Invoice #'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _currencyController,
                                decoration:
                                    const InputDecoration(labelText: 'Currency'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _taxController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Tax %'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'Discount %'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tableController,
                                decoration:
                                    const InputDecoration(labelText: 'Table No'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _orderTypeController,
                                decoration:
                                    const InputDecoration(labelText: 'Order Type'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Notes'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Line items',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return InvoiceLineItemEditor(
                    key: ValueKey(item.id),
                    item: item,
                    onChanged: (updated) => setState(() => _items[index] = updated),
                    onRemove: _items.length > 1
                        ? () => setState(() => _items.removeAt(index))
                        : null,
                  );
                }),
                const SizedBox(height: 8),
                Card(
                  color: AppConstants.primaryOrange.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _totalRow(
                          'Subtotal',
                          '${invoice.currency}${invoice.rawSubtotal.toStringAsFixed(2)}',
                        ),
                        _totalRow(
                          'Discount',
                          '-${invoice.currency}${invoice.discountAmount.toStringAsFixed(2)}',
                        ),
                        _totalRow(
                          'Tax',
                          '+${invoice.currency}${invoice.taxAmount.toStringAsFixed(2)}',
                        ),
                        const Divider(),
                        _totalRow(
                          'Grand Total',
                          '${invoice.currency}${invoice.grandTotal.toStringAsFixed(2)}',
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _continueToPreview,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continue to PDF Preview'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  final int total;
  final String label;

  const _StepHeader({
    required this.step,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppConstants.primaryOrange,
            foregroundColor: Colors.white,
            child: Text(
              '$step',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $step of $total',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
