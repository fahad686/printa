import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/pdf_generator/pdf_helper.dart';
import '../../shared/models/receipt_template_model.dart';

class TemplateExportHelper {
  static Future<Uint8List?> captureWidgetAsPng(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static Future<void> shareAsPng({
    required ReceiptTemplateModel template,
    required GlobalKey previewKey,
  }) async {
    final pngBytes = await captureWidgetAsPng(previewKey);
    if (pngBytes == null) {
      throw Exception('Could not capture receipt preview as PNG');
    }
    final safeName = template.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    await Share.shareXFiles(
      [
        XFile.fromData(
          pngBytes,
          name: '${safeName.isEmpty ? 'receipt' : safeName}.png',
          mimeType: 'image/png',
        ),
      ],
      text: '${template.title} receipt template',
    );
  }

  static Future<void> shareAsPdf(ReceiptTemplateModel template) async {
    final pdfBytes = await PdfHelper.generateInvoicePdf(template.sampleInvoice);
    final safeName = template.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    await Share.shareXFiles(
      [
        XFile.fromData(
          pdfBytes,
          name: '${safeName.isEmpty ? 'receipt' : safeName}.pdf',
          mimeType: 'application/pdf',
        ),
      ],
      text: '${template.title} receipt template (PDF)',
    );
  }
}
