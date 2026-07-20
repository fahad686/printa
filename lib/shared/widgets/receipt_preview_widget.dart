import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/invoice_model.dart';
import '../models/receipt_template_model.dart';

class ReceiptPreviewWidget extends StatelessWidget {
  final InvoiceModel invoice;
  final ReceiptTemplateType templateType;
  final bool isDarkTheme;
  final double paperWidthMm;

  const ReceiptPreviewWidget({
    super.key,
    required this.invoice,
    this.templateType = ReceiptTemplateType.simpleInvoice,
    this.isDarkTheme = false,
    this.paperWidthMm = 58,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = (templateType == ReceiptTemplateType.darkTheme || isDarkTheme)
        ? const Color(0xFF18181B)
        : Colors.white;
    final textColor = (templateType == ReceiptTemplateType.darkTheme || isDarkTheme)
        ? Colors.white
        : Colors.black87;
    final subTextColor = (templateType == ReceiptTemplateType.darkTheme || isDarkTheme)
        ? Colors.white60
        : Colors.black54;

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      width: paperWidthMm == 80 ? 340 : 280,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Company Header
            Text(
              invoice.companyName.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),

            if (invoice.tableNo != null || invoice.orderType != null) ...[
              Text(
                '${invoice.orderType ?? ''} ${invoice.tableNo != null ? '• ${invoice.tableNo}' : ''}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
            ],

            Text(
              'Date: ${dateFormat.format(invoice.date)}',
              style: TextStyle(color: subTextColor, fontSize: 11),
            ),
            Text(
              'Inv #: ${invoice.invoiceNumber}',
              style: TextStyle(color: subTextColor, fontSize: 11),
            ),
            Text(
              'Customer: ${invoice.customerName}',
              style: TextStyle(color: subTextColor, fontSize: 11),
            ),

            const SizedBox(height: 12),
            _buildDashedLine(subTextColor),
            const SizedBox(height: 8),

            // Item Headers
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('ITEM',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('QTY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('TOTAL',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildDashedLine(subTextColor),
            const SizedBox(height: 8),

            // Item Rows
            ...invoice.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.name,
                        style: TextStyle(color: textColor, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'x${item.quantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${invoice.currency}${item.subtotal.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),
            _buildDashedLine(subTextColor),
            const SizedBox(height: 8),

            // Calculation Breakdown
            _buildSummaryRow(
                'Subtotal:',
                '${invoice.currency}${invoice.rawSubtotal.toStringAsFixed(2)}',
                textColor,
                subTextColor),
            if (invoice.discountPercentage > 0)
              _buildSummaryRow(
                  'Discount (${invoice.discountPercentage.toStringAsFixed(0)}%):',
                  '-${invoice.currency}${invoice.discountAmount.toStringAsFixed(2)}',
                  textColor,
                  subTextColor),
            if (invoice.taxPercentage > 0)
              _buildSummaryRow(
                  'Tax (${invoice.taxPercentage.toStringAsFixed(0)}%):',
                  '+${invoice.currency}${invoice.taxAmount.toStringAsFixed(2)}',
                  textColor,
                  subTextColor),

            const SizedBox(height: 6),
            _buildDashedLine(subTextColor),
            const SizedBox(height: 8),

            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL PAYABLE:',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${invoice.currency}${invoice.grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${invoice.notes}',
                style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 14),

            // QR Code & Barcode Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                QrImageView(
                  data: invoice.toCompactJsonString(),
                  version: QrVersions.auto,
                  size: 70.0,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: textColor,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: textColor,
                  ),
                ),
                SizedBox(
                  width: 110,
                  height: 45,
                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: invoice.invoiceNumber,
                    color: textColor,
                    drawText: true,
                    style: TextStyle(color: textColor, fontSize: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Text(
              'Thank you for your business!',
              style: TextStyle(
                  color: subTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, String value, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: subTextColor, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDashedLine(Color color) {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? color.withOpacity(0.4) : Colors.transparent,
            height: 1,
          ),
        ),
      ),
    );
  }
}
