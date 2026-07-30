import 'package:flutter/material.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/models/receipt_template_model.dart';
import '../../shared/widgets/invoice_line_item_editor.dart';

class TemplateEditorSheet extends StatefulWidget {
  final ReceiptTemplateModel template;

  const TemplateEditorSheet({super.key, required this.template});

  static Future<ReceiptTemplateModel?> show(
    BuildContext context,
    ReceiptTemplateModel template,
  ) {
    return showModalBottomSheet<ReceiptTemplateModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TemplateEditorSheet(template: template),
    );
  }

  @override
  State<TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<TemplateEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
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
    final inv = widget.template.sampleInvoice;
    _titleController = TextEditingController(text: widget.template.title);
    _categoryController = TextEditingController(text: widget.template.category);
    _descriptionController = TextEditingController(text: widget.template.description);
    _companyController = TextEditingController(text: inv.companyName);
    _customerController = TextEditingController(text: inv.customerName);
    _invoiceNumController = TextEditingController(text: inv.invoiceNumber);
    _currencyController = TextEditingController(text: inv.currency);
    _taxController = TextEditingController(text: inv.taxPercentage.toString());
    _discountController = TextEditingController(text: inv.discountPercentage.toString());
    _notesController = TextEditingController(text: inv.notes ?? '');
    _tableController = TextEditingController(text: inv.tableNo ?? '');
    _orderTypeController = TextEditingController(text: inv.orderType ?? '');
    _items = inv.items.map((i) => i.copyWith()).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
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

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Item',
        quantity: 1,
        unitPrice: 10.0,
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() => _items.removeAt(index));
    }
  }

  void _save() {
    final updatedInvoice = widget.template.sampleInvoice.copyWith(
      companyName: _companyController.text.trim(),
      customerName: _customerController.text.trim(),
      invoiceNumber: _invoiceNumController.text.trim(),
      currency: _currencyController.text.trim(),
      taxPercentage: double.tryParse(_taxController.text) ?? 0,
      discountPercentage: double.tryParse(_discountController.text) ?? 0,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      tableNo: _tableController.text.trim().isEmpty ? null : _tableController.text.trim(),
      orderType: _orderTypeController.text.trim().isEmpty ? null : _orderTypeController.text.trim(),
      items: List.from(_items),
      date: DateTime.now(),
    );

    final updated = widget.template.copyWith(
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
      sampleInvoice: updatedInvoice,
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Edit Template',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Template Info',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Template Title'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Receipt Data',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(labelText: 'Company Name'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customerController,
                            decoration: const InputDecoration(labelText: 'Customer'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _invoiceNumController,
                            decoration: const InputDecoration(labelText: 'Invoice #'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _currencyController,
                            decoration: const InputDecoration(labelText: 'Currency'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _taxController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Tax %'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Discount %'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tableController,
                            decoration: const InputDecoration(labelText: 'Table No (optional)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _orderTypeController,
                            decoration: const InputDecoration(labelText: 'Order Type (optional)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Line Items',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return InvoiceLineItemEditor(
                        key: ValueKey(item.id),
                        item: item,
                        dense: true,
                        onChanged: (updated) => setState(() => _items[index] = updated),
                        onRemove: _items.length > 1 ? () => _removeItem(index) : null,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
