import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/history_item_model.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/repositories/history_repository.dart';
import '../../shared/widgets/signature_canvas_widget.dart';
import 'pdf_helper.dart';

class PDFGeneratorScreen extends ConsumerStatefulWidget {
  const PDFGeneratorScreen({super.key});

  @override
  ConsumerState<PDFGeneratorScreen> createState() => _PDFGeneratorScreenState();
}

class _PDFGeneratorScreenState extends ConsumerState<PDFGeneratorScreen> {
  String _pageFormatType = 'A4';
  late InvoiceModel _invoice;

  @override
  void initState() {
    super.initState();
    _invoice = InvoiceModel.createSample();
  }

  PdfPageFormat _getPdfPageFormat() {
    switch (_pageFormatType) {
      case '58mm Roll':
        return const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity);
      case '80mm Roll':
        return const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity);
      case 'Letter':
        return PdfPageFormat.letter;
      default:
        return PdfPageFormat.a4;
    }
  }

  Future<void> _sharePdf() async {
    final pdfBytes = await PdfHelper.generateInvoicePdf(
      _invoice,
      pageFormat: _getPdfPageFormat(),
    );

    await Share.shareXFiles(
      [
        XFile.fromData(
          pdfBytes,
          name: 'Invoice_${_invoice.invoiceNumber}.pdf',
          mimeType: 'application/pdf',
        )
      ],
      text: 'PDF Invoice ${_invoice.invoiceNumber}',
    );
  }

  Future<void> _saveToHistory() async {
    await ref.read(historyRepositoryProvider).addHistoryItem(
          HistoryItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'PDF Invoice ${_invoice.invoiceNumber}',
            category: 'pdf',
            timestamp: DateTime.now(),
            payload: _invoice.toCompactJsonString(),
            subtitle: 'Format: $_pageFormatType',
          ),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved PDF Invoice record to Hive history!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 9 – PDF Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveToHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Paper Format Controls
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                const Text('Page Format: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'A4', label: Text('A4')),
                      ButtonSegment(value: '58mm Roll', label: Text('58mm')),
                      ButtonSegment(value: '80mm Roll', label: Text('80mm')),
                    ],
                    selected: {_pageFormatType},
                    onSelectionChanged: (val) {
                      setState(() {
                        _pageFormatType = val.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // PDF Interactive Preview
          Expanded(
            child: PdfPreview(
              build: (format) => PdfHelper.generateInvoicePdf(
                _invoice,
                pageFormat: _getPdfPageFormat(),
              ),
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              initialPageFormat: _getPdfPageFormat(),
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: AppConstants.primaryOrange),
              ),
            ),
          ),

          // Digital Signature Drawer
          const Padding(
            padding: EdgeInsets.all(12),
            child: SignatureCanvasWidget(),
          ),
        ],
      ),
    );
  }
}
