import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printa/features/pdf_generator/pdf_helper.dart';
import 'package:printa/shared/models/invoice_model.dart';

void main() {
  test('generate A4 pdf', () async {
    final bytes = await PdfHelper.generateInvoicePdf(
      InvoiceModel.createSample(),
      pageFormat: PdfPageFormat.a4,
    );
    expect(bytes.length, greaterThan(100));
    expect(bytes[0], 0x25); // %
    expect(bytes[1], 0x50); // P
    expect(bytes[2], 0x44); // D
    expect(bytes[3], 0x46); // F
  });

  test('generate 58mm pdf', () async {
    final bytes = await PdfHelper.generateInvoicePdf(
      InvoiceModel.createSample(),
      pageFormat: const PdfPageFormat(58 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
    );
    expect(bytes.length, greaterThan(100));
  });

  test('generate 80mm pdf', () async {
    final bytes = await PdfHelper.generateInvoicePdf(
      InvoiceModel.createSample(),
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
    );
    expect(bytes.length, greaterThan(100));
  });
}
