import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/invoice_model.dart';

/// Shared draft invoice for the PDF Generator multi-screen flow.
final pdfDraftInvoiceProvider = StateProvider<InvoiceModel>((ref) {
  return InvoiceModel.createSample();
});

final pdfPageFormatProvider = StateProvider<String>((ref) => 'A4');
