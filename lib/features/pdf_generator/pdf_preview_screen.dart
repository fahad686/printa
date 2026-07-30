import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/history_item_model.dart';
import '../../shared/repositories/history_repository.dart';
import '../../shared/widgets/signature_canvas_widget.dart';
import 'pdf_flow_providers.dart';
import 'pdf_helper.dart';

/// Step 2 — choose format, sign, preview, then print/share/save.
class PdfPreviewScreen extends ConsumerStatefulWidget {
  const PdfPreviewScreen({super.key});

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  Uint8List? _signaturePng;
  bool _busy = false;
  int _previewVersion = 0;

  PdfPageFormat _formatFor(String type) {
    switch (type) {
      case '58mm Roll':
        return const PdfPageFormat(
          58 * PdfPageFormat.mm,
          200 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm,
        );
      case '80mm Roll':
        return const PdfPageFormat(
          80 * PdfPageFormat.mm,
          220 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm,
        );
      case 'Letter':
        return PdfPageFormat.letter;
      default:
        return PdfPageFormat.a4;
    }
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) {
    final invoice = ref.read(pdfDraftInvoiceProvider);
    return PdfHelper.generateInvoicePdf(
      invoice,
      pageFormat: format,
      signaturePng: _signaturePng,
    );
  }

  Future<void> _refreshSignature(List<Offset?> points) async {
    final png = await PdfHelper.signaturePointsToPng(points);
    if (!mounted) return;
    setState(() {
      _signaturePng = png;
      _previewVersion++;
    });
  }

  Future<void> _runGuarded(
    Future<void> Function() action, {
    String? success,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && success != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final invoice = ref.read(pdfDraftInvoiceProvider);
    final format = _formatFor(ref.read(pdfPageFormatProvider));
    await _runGuarded(() async {
      final bytes = await _buildPdf(format);
      await PdfHelper.sharePdfBytes(
        bytes,
        fileName: 'Invoice_${invoice.invoiceNumber}.pdf',
        text: 'PDF Invoice ${invoice.invoiceNumber}',
      );
    });
  }

  Future<void> _print() async {
    final invoice = ref.read(pdfDraftInvoiceProvider);
    await _runGuarded(() async {
      await Printing.layoutPdf(
        onLayout: (_) => _buildPdf(_formatFor(ref.read(pdfPageFormatProvider))),
        name: 'Invoice_${invoice.invoiceNumber}',
      );
    });
  }

  Future<void> _saveHistory() async {
    final invoice = ref.read(pdfDraftInvoiceProvider);
    final formatType = ref.read(pdfPageFormatProvider);
    await _runGuarded(() async {
      await ref.read(historyRepositoryProvider).addHistoryItem(
            HistoryItemModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'PDF Invoice ${invoice.invoiceNumber}',
              category: 'pdf',
              timestamp: DateTime.now(),
              payload: invoice.toCompactJsonString(),
              subtitle: 'Format: $formatType',
            ),
          );
    }, success: 'Saved PDF invoice to history');
  }

  @override
  Widget build(BuildContext context) {
    final invoice = ref.watch(pdfDraftInvoiceProvider);
    final formatType = ref.watch(pdfPageFormatProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        actions: [
          IconButton(
            tooltip: 'Edit invoice',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: theme.cardColor,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppConstants.primaryOrange,
                  foregroundColor: Colors.white,
                  child: Text(
                    '2',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 2 of 2',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.hintColor,
                        ),
                      ),
                      Text(
                        '${invoice.invoiceNumber} · ${invoice.currency}${invoice.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'A4', label: Text('A4')),
                ButtonSegment(value: '58mm Roll', label: Text('58mm')),
                ButtonSegment(value: '80mm Roll', label: Text('80mm')),
              ],
              selected: {formatType},
              onSelectionChanged: (val) {
                ref.read(pdfPageFormatProvider.notifier).state = val.first;
                setState(() => _previewVersion++);
              },
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                PdfPreview(
                  key: ValueKey('$formatType-$_previewVersion'),
                  build: (_) => _buildPdf(_formatFor(formatType)),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  initialPageFormat: _formatFor(formatType),
                  pdfFileName: 'Invoice_${invoice.invoiceNumber}.pdf',
                  onError: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Could not render PDF\n$error',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => setState(() => _previewVersion++),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryOrange,
                    ),
                  ),
                ),
                if (_busy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            elevation: 6,
            color: theme.cardColor,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExpansionTile(
                    leading: const Icon(
                      Icons.draw_rounded,
                      color: AppConstants.primaryOrange,
                    ),
                    title: const Text(
                      'Customer Signature',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Text(
                      _signaturePng == null
                          ? 'Optional — expand to sign'
                          : 'Signature included in PDF',
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: SignatureCanvasWidget(
                          onSignatureChanged: _refreshSignature,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _print,
                            icon: const Icon(Icons.print_rounded, size: 18),
                            label: const Text('Print'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _saveHistory,
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text('Save'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _busy ? null : _share,
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('Share'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
