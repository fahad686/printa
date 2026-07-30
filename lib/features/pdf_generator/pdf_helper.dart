import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../shared/models/invoice_model.dart';

class PdfHelper {
  /// True when page is thermal-roll width (58/80mm class).
  static bool isRollFormat(PdfPageFormat format) =>
      format.width <= 90 * PdfPageFormat.mm;

  static PdfPageFormat normalizeFormat(PdfPageFormat pageFormat) {
    final width = pageFormat.width;
    final height = pageFormat.height.isFinite && pageFormat.height > 0
        ? pageFormat.height
        : 297 * PdfPageFormat.mm;

    if (isRollFormat(pageFormat)) {
      // Tight margins so 58/80mm content still fits.
      return PdfPageFormat(
        width,
        height,
        marginAll: 3 * PdfPageFormat.mm,
      );
    }

    return PdfPageFormat(
      width,
      height,
      marginAll: pageFormat.marginLeft > 0
          ? pageFormat.marginLeft
          : 12 * PdfPageFormat.mm,
    );
  }

  static Future<Uint8List> generateInvoicePdf(
    InvoiceModel invoice, {
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    Uint8List? signaturePng,
  }) async {
    final safeFormat = normalizeFormat(pageFormat);
    final pdf = pw.Document(
      title: 'Invoice ${invoice.invoiceNumber}',
      author: 'Printa',
    );

    final roll = isRollFormat(safeFormat);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: safeFormat,
        maxPages: 20,
        build: (context) => [
          if (roll)
            ..._buildRollContent(invoice, signaturePng)
          else
            ..._buildA4Content(invoice, signaturePng),
        ],
      ),
    );

    return pdf.save();
  }

  static List<pw.Widget> _buildA4Content(
    InvoiceModel invoice,
    Uint8List? signaturePng,
  ) {
    return [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                pw.SizedBox(height: 2),
                pw.Text(
                  'Official Sales Receipt & Tax Invoice',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
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
                'Date: ${_formatDate(invoice.date)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (invoice.orderType != null)
                pw.Text(
                  invoice.orderType!,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 14),
      pw.Divider(thickness: 1),
      pw.SizedBox(height: 8),
      pw.Text(
        'Billed To: ${invoice.customerName}',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      ),
      if (invoice.tableNo != null)
        pw.Text('Table: ${invoice.tableNo}', style: const pw.TextStyle(fontSize: 10)),
      pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(
        headers: const ['Item Description', 'Qty', 'Unit Price', 'Subtotal'],
        data: invoice.items
            .map(
              (item) => [
                item.name,
                '${item.quantity}',
                _money(invoice.currency, item.unitPrice),
                _money(invoice.currency, item.subtotal),
              ],
            )
            .toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellAlignment: pw.Alignment.centerLeft,
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1.4),
          3: const pw.FlexColumnWidth(1.4),
        },
      ),
      pw.SizedBox(height: 12),
      pw.Divider(),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.SizedBox(
          width: 200,
          child: _totalsBlock(invoice, fontSize: 10, totalSize: 13),
        ),
      ),
      if (invoice.notes != null && invoice.notes!.trim().isNotEmpty) ...[
        pw.SizedBox(height: 14),
        pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 9)),
      ],
      if (signaturePng != null) ...[
        pw.SizedBox(height: 18),
        pw.Text('Customer Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 70,
          width: 180,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          padding: const pw.EdgeInsets.all(4),
          child: pw.Image(pw.MemoryImage(signaturePng), fit: pw.BoxFit.contain),
        ),
      ],
      pw.SizedBox(height: 24),
      pw.Divider(),
      pw.SizedBox(height: 8),
      pw.Center(
        child: pw.Text(
          'Generated by Printa',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      pw.SizedBox(height: 3),
      pw.Center(
        child: pw.Text(
          'Developed by Fahad Ali - Senior Mobile App Consultant',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ),
    ];
  }

  static List<pw.Widget> _buildRollContent(
    InvoiceModel invoice,
    Uint8List? signaturePng,
  ) {
    return [
      pw.Center(
        child: pw.Text(
          invoice.companyName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Center(
        child: pw.Text(
          'TAX INVOICE',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Text('INV: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 8)),
      pw.Text('Date: ${_formatDate(invoice.date)}', style: const pw.TextStyle(fontSize: 8)),
      pw.Text('Customer: ${invoice.customerName}', style: const pw.TextStyle(fontSize: 8)),
      if (invoice.tableNo != null)
        pw.Text('Table: ${invoice.tableNo}', style: const pw.TextStyle(fontSize: 8)),
      if (invoice.orderType != null)
        pw.Text(invoice.orderType!, style: const pw.TextStyle(fontSize: 8)),
      pw.SizedBox(height: 6),
      pw.Divider(thickness: 0.6),
      ...invoice.items.map((item) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.name,
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${item.quantity} x ${_money(invoice.currency, item.unitPrice)}',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.Text(
                    _money(invoice.currency, item.subtotal),
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
      pw.Divider(thickness: 0.6),
      _totalsBlock(invoice, fontSize: 8, totalSize: 10),
      if (invoice.notes != null && invoice.notes!.trim().isNotEmpty) ...[
        pw.SizedBox(height: 6),
        pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 7)),
      ],
      if (signaturePng != null) ...[
        pw.SizedBox(height: 8),
        pw.Text('Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 3),
        pw.Container(
          height: 40,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Image(pw.MemoryImage(signaturePng), fit: pw.BoxFit.contain),
        ),
      ],
      pw.SizedBox(height: 10),
      pw.Center(
        child: pw.Text(
          'Generated by Printa',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
        ),
      ),
    ];
  }

  static pw.Widget _totalsBlock(
    InvoiceModel invoice, {
    required double fontSize,
    required double totalSize,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _totalRow('Subtotal', _money(invoice.currency, invoice.rawSubtotal), fontSize),
        if (invoice.discountPercentage > 0)
          _totalRow(
            'Discount (${invoice.discountPercentage.toStringAsFixed(0)}%)',
            '-${_money(invoice.currency, invoice.discountAmount)}',
            fontSize,
          ),
        if (invoice.taxPercentage > 0)
          _totalRow(
            'Tax (${invoice.taxPercentage.toStringAsFixed(0)}%)',
            '+${_money(invoice.currency, invoice.taxAmount)}',
            fontSize,
          ),
        pw.SizedBox(height: 3),
        _totalRow(
          'TOTAL',
          _money(invoice.currency, invoice.grandTotal),
          totalSize,
          bold: true,
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, String value, double fontSize, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static String _money(String currency, double amount) =>
      '$currency${amount.toStringAsFixed(2)}';

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Writes bytes to a temp file then shares — reliable on Android (unlike fromData alone).
  static Future<void> sharePdfBytes(
    Uint8List pdfBytes, {
    required String fileName,
    String? text,
  }) async {
    final safeName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(pdfBytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: safeName)],
      text: text,
    );
  }

  /// Builds a PDF from a list of image file paths — one photo per page, fit to page.
  static Future<Uint8List> generatePhotosPdf(
    List<String> imagePaths, {
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    String? title,
  }) async {
    final pdf = pw.Document(title: title ?? 'Photos', author: 'Printa');

    for (final path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(16),
          build: (context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    if (imagePaths.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) => pw.Center(
            child: pw.Text('No photos selected'),
          ),
        ),
      );
    }

    return pdf.save();
  }

  /// Sanitizes a user-entered name into a safe PDF file name (no extension).
  static String sanitizeFileName(String name, {String fallback = 'document'}) {
    final cleaned = name
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? fallback : cleaned;
  }

  /// Renders signature stroke points into a transparent PNG for embedding in PDFs.
  static Future<Uint8List?> signaturePointsToPng(
    List<Offset?> points, {
    Size size = const Size(360, 140),
  }) async {
    if (points.whereType<Offset>().isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, paint);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
