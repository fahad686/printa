import 'package:flutter/material.dart';
import '../models/invoice_model.dart';

/// Editable line-item row with its own controllers so edits don't stomp each other.
class InvoiceLineItemEditor extends StatefulWidget {
  final InvoiceItem item;
  final ValueChanged<InvoiceItem> onChanged;
  final VoidCallback? onRemove;
  final bool dense;

  const InvoiceLineItemEditor({
    super.key,
    required this.item,
    required this.onChanged,
    this.onRemove,
    this.dense = false,
  });

  @override
  State<InvoiceLineItemEditor> createState() => _InvoiceLineItemEditorState();
}

class _InvoiceLineItemEditorState extends State<InvoiceLineItemEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _qtyController = TextEditingController(text: '${widget.item.quantity}');
    _priceController = TextEditingController(text: widget.item.unitPrice.toString());
  }

  @override
  void didUpdateWidget(covariant InvoiceLineItemEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _nameController.text = widget.item.name;
      _qtyController.text = '${widget.item.quantity}';
      _priceController.text = widget.item.unitPrice.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.item.copyWith(
        name: _nameController.text,
        quantity: int.tryParse(_qtyController.text) ?? 1,
        unitPrice: double.tryParse(_priceController.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = widget.dense ? 10.0 : 12.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item'),
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qty'),
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
                onChanged: (_) => _emit(),
              ),
            ),
            if (widget.onRemove != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: widget.onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
