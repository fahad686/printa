import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../native/sunmi_printer_service.dart';
import '../../shared/models/history_item_model.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/models/receipt_template_model.dart';
import '../../shared/repositories/history_repository.dart';
import '../../shared/widgets/receipt_preview_widget.dart';
import '../pdf_generator/pdf_helper.dart';

class ReceiptBuilderScreen extends ConsumerStatefulWidget {
  const ReceiptBuilderScreen({super.key});

  @override
  ConsumerState<ReceiptBuilderScreen> createState() => _ReceiptBuilderScreenState();
}

class _ReceiptBuilderScreenState extends ConsumerState<ReceiptBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyController;
  late TextEditingController _customerController;
  late TextEditingController _invoiceNumController;
  late TextEditingController _currencyController;
  late TextEditingController _taxController;
  late TextEditingController _discountController;

  final List<InvoiceItem> _items = [
    InvoiceItem(id: '1', name: 'POS Thermal Printer Roll', quantity: 2, unitPrice: 12.50),
    InvoiceItem(id: '2', name: 'NFC Smart Card Tags', quantity: 5, unitPrice: 3.00),
  ];

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: AppConstants.defaultBusinessName);
    _customerController = TextEditingController(text: 'Walk-in Customer');
    _invoiceNumController = TextEditingController(
        text: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    _currencyController = TextEditingController(text: '\$');
    _taxController = TextEditingController(text: '10.0');
    _discountController = TextEditingController(text: '0.0');
  }

  @override
  void dispose() {
    _companyController.dispose();
    _customerController.dispose();
    _invoiceNumController.dispose();
    _currencyController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  InvoiceModel _buildInvoiceFromForm() {
    final tax = double.tryParse(_taxController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    return InvoiceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      companyName: _companyController.text,
      customerName: _customerController.text,
      invoiceNumber: _invoiceNumController.text,
      date: DateTime.now(),
      currency: _currencyController.text,
      taxPercentage: tax,
      discountPercentage: discount,
      items: List.from(_items),
    );
  }

  void _addItem() {
    setState(() {
      _items.add(
        InvoiceItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'New Product',
          quantity: 1,
          unitPrice: 10.0,
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  void _showPreviewDialog(InvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Receipt Preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ReceiptPreviewWidget(
                    invoice: invoice,
                    templateType: ReceiptTemplateType.simpleInvoice,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printReceipt(InvoiceModel invoice) async {
    final printer = ref.read(sunmiPrinterServiceProvider);
    final isPrinted = await printer.printReceipt(invoice);

    // Record history
    final historyRepo = ref.read(historyRepositoryProvider);
    await historyRepo.addHistoryItem(
      HistoryItemModel(
        id: invoice.id,
        title: 'Printed Receipt #${invoice.invoiceNumber}',
        category: 'receipt',
        timestamp: DateTime.now(),
        payload: invoice.toCompactJsonString(),
        subtitle: '${invoice.currency}${invoice.grandTotal.toStringAsFixed(2)} - ${invoice.customerName}',
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPrinted
              ? 'Receipt sent to thermal printer successfully!'
              : 'Printed via thermal engine fallback'),
          backgroundColor: AppConstants.primaryOrange,
        ),
      );
    }
  }

  Future<void> _generateAndSharePdf(InvoiceModel invoice, {bool printPdf = false}) async {
    final pdfBytes = await PdfHelper.generateInvoicePdf(invoice);
    if (printPdf) {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } else {
      await Share.shareXFiles(
        [
          XFile.fromData(
            pdfBytes,
            name: 'Invoice_${invoice.invoiceNumber}.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        text: 'Invoice ${invoice.invoiceNumber} for ${invoice.customerName}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _buildInvoiceFromForm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 1 – Receipt Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye_rounded),
            tooltip: 'Preview',
            onPressed: () => _showPreviewDialog(invoice),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Business Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Business & Invoice Details',
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
                                  decoration: const InputDecoration(labelText: 'Customer Name'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _invoiceNumController,
                                  decoration: const InputDecoration(labelText: 'Invoice No.'),
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
                                  decoration: const InputDecoration(labelText: 'Currency Symbol'),
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
                                  decoration: const InputDecoration(labelText: 'Discount %'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Dynamic Items List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dynamic Line Items',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: item.name,
                                decoration: const InputDecoration(labelText: 'Item Name'),
                                onChanged: (val) {
                                  _items[index] = item.copyWith(name: val);
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue: item.quantity.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Qty'),
                                onChanged: (val) {
                                  final q = int.tryParse(val) ?? 1;
                                  _items[index] = item.copyWith(quantity: q);
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: item.unitPrice.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Price'),
                                onChanged: (val) {
                                  final p = double.tryParse(val) ?? 0.0;
                                  _items[index] = item.copyWith(unitPrice: p);
                                  setState(() {});
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  // Totals Summary Box
                  Card(
                    color: AppConstants.primaryOrange.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTotalRow('Subtotal', '${invoice.currency}${invoice.rawSubtotal.toStringAsFixed(2)}'),
                          _buildTotalRow('Discount', '-${invoice.currency}${invoice.discountAmount.toStringAsFixed(2)}'),
                          _buildTotalRow('Tax', '+${invoice.currency}${invoice.taxAmount.toStringAsFixed(2)}'),
                          const Divider(),
                          _buildTotalRow(
                            'Grand Total',
                            '${invoice.currency}${invoice.grandTotal.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _printReceipt(invoice),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Print'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _generateAndSharePdf(invoice, printPdf: true),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('PDF'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: 'Share PDF',
                    onPressed: () => _generateAndSharePdf(invoice),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 17 : 14)),
        ],
      ),
    );
  }
}
