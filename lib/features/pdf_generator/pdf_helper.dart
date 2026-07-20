import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../shared/models/invoice_model.dart';

class PdfHelper {
  static Future<Uint8List> generateInvoicePdf(
    InvoiceModel invoice, {
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    // PdfPreview / roll formats must use finite height — Spacer fails with unbounded height.
    final safeFormat = pageFormat.height.isFinite
        ? pageFormat
        : PdfPageFormat(
            pageFormat.width,
            200 * PdfPageFormat.mm,
            marginAll: pageFormat.marginLeft,
          );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: safeFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          invoice.companyName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Official Sales Receipt & Tax Invoice',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INV #: ${invoice.invoiceNumber}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.Text(
                        'Date: ${invoice.date.toString().substring(0, 10)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),

              pw.Text(
                'Billed To: ${invoice.customerName}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              ),
              if (invoice.tableNo != null)
                pw.Text('Table: ${invoice.tableNo}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 12),

              pw.TableHelper.fromTextArray(
                headers: ['Item Description', 'Qty', 'Unit Price', 'Subtotal'],
                data: invoice.items.map((item) {
                  return [
                    item.name,
                    '${item.quantity}',
                    '${invoice.currency}${item.unitPrice.toStringAsFixed(2)}',
                    '${invoice.currency}${item.subtotal.toStringAsFixed(2)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellAlignment: pw.Alignment.centerLeft,
              ),

              pw.SizedBox(height: 12),
              pw.Divider(),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Subtotal: ${invoice.currency}${invoice.rawSubtotal.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    if (invoice.discountPercentage > 0)
                      pw.Text(
                        'Discount (${invoice.discountPercentage.toStringAsFixed(0)}%): -${invoice.currency}${invoice.discountAmount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (invoice.taxPercentage > 0)
                      pw.Text(
                        'Tax (${invoice.taxPercentage.toStringAsFixed(0)}%): +${invoice.currency}${invoice.taxAmount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Grand Total: ${invoice.currency}${invoice.grandTotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Generated by Printa',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Developed by Fahad Ali — Senior Mobile App Consultant',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
