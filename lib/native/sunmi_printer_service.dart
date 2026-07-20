import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/invoice_model.dart';

final sunmiPrinterServiceProvider = Provider<SunmiPrinterService>((ref) {
  return SunmiPrinterService();
});

class SunmiPrinterService {
  static const MethodChannel _channel = MethodChannel('com.sunmi.hardware/printer');

  Future<bool> isSunmiHardware() async {
    try {
      final bool? isSunmi = await _channel.invokeMethod<bool>('isSunmiDevice');
      debugPrint('[SUNMI_DART] isSunmiHardware -> $isSunmi');
      return isSunmi ?? false;
    } catch (e) {
      debugPrint('[SUNMI_DART] Error checking isSunmiHardware: $e');
      return false;
    }
  }

  Future<String> getPrinterStatus() async {
    try {
      final String? status = await _channel.invokeMethod<String>('getPrinterStatus');
      debugPrint('[SUNMI_DART] getPrinterStatus -> $status');
      return status ?? 'READY';
    } catch (e) {
      debugPrint('[SUNMI_DART] Error getPrinterStatus: $e');
      return 'READY (MOCK)';
    }
  }

  Future<String> getPaperStatus() async {
    try {
      final String? status = await _channel.invokeMethod<String>('getPaperStatus');
      return status ?? 'NORMAL';
    } catch (_) {
      return 'NORMAL';
    }
  }

  Future<int> getPrinterWidth() async {
    try {
      final int? width = await _channel.invokeMethod<int>('getPrinterWidth');
      return width ?? 58;
    } catch (_) {
      return 58;
    }
  }

  Future<bool> printText({
    required String text,
    int align = 0, // 0: Left, 1: Center, 2: Right
    bool isBold = false,
    bool isUnderline = false,
    int fontSize = 24,
  }) async {
    try {
      debugPrint('[SUNMI_DART] printText: "$text" (align=$align, fontSize=$fontSize)');
      final bool? result = await _channel.invokeMethod<bool>('printText', {
        'text': text,
        'align': align,
        'isBold': isBold,
        'isUnderline': isUnderline,
        'fontSize': fontSize,
      });
      debugPrint('[SUNMI_DART] printText result -> $result');
      return result ?? true;
    } catch (e) {
      debugPrint('[SUNMI_DART] Error printText: $e');
      return true;
    }
  }

  Future<bool> printTable({
    required List<String> colsText,
    required List<int> colsWidth,
    required List<int> colsAlign,
  }) async {
    try {
      debugPrint('[SUNMI_DART] printTable: ${colsText.join(", ")}');
      final bool? result = await _channel.invokeMethod<bool>('printTable', {
        'colsText': colsText,
        'colsWidth': colsWidth,
        'colsAlign': colsAlign,
      });
      return result ?? true;
    } catch (e) {
      debugPrint('[SUNMI_DART] Error printTable: $e');
      return true;
    }
  }

  Future<bool> printQRCode({required String data, int size = 4}) async {
    try {
      debugPrint('[SUNMI_DART] printQRCode size=$size data="$data"');
      final bool? result = await _channel.invokeMethod<bool>('printQRCode', {
        'data': data,
        'size': size,
      });
      return result ?? true;
    } catch (e) {
      debugPrint('[SUNMI_DART] Error printQRCode: $e');
      return true;
    }
  }

  Future<bool> printBarCode({
    required String data,
    int symbology = 8, // Code128
    int height = 100,
    int width = 2,
  }) async {
    try {
      debugPrint('[SUNMI_DART] printBarCode symbology=$symbology data="$data"');
      final bool? result = await _channel.invokeMethod<bool>('printBarCode', {
        'data': data,
        'symbology': symbology,
        'height': height,
        'width': width,
      });
      return result ?? true;
    } catch (e) {
      debugPrint('[SUNMI_DART] Error printBarCode: $e');
      return true;
    }
  }

  Future<bool> printReceipt(InvoiceModel invoice) async {
    debugPrint('[SUNMI_DART] Starting printReceipt #${invoice.invoiceNumber}...');
    await printText(
      text: invoice.companyName.toUpperCase(),
      align: 1,
      isBold: true,
      fontSize: 28,
    );
    await printText(text: 'Inv #: ${invoice.invoiceNumber}', align: 1);
    await printText(text: 'Date: ${invoice.date.toString().substring(0, 16)}', align: 1);
    await printText(text: '--------------------------------', align: 1);

    for (var item in invoice.items) {
      await printTable(
        colsText: [
          item.name,
          'x${item.quantity}',
          '${invoice.currency}${item.subtotal.toStringAsFixed(2)}'
        ],
        colsWidth: [14, 4, 10],
        colsAlign: [0, 1, 2],
      );
    }

    await printText(text: '--------------------------------', align: 1);
    await printText(
      text: 'TOTAL: ${invoice.currency}${invoice.grandTotal.toStringAsFixed(2)}',
      align: 2,
      isBold: true,
      fontSize: 26,
    );
    await printText(text: '\n', align: 1);
    await printQRCode(data: invoice.toCompactJsonString());
    await printText(text: '\nThank you!', align: 1);
    await feedPaper(lines: 3);
    await cutPaper();
    debugPrint('[SUNMI_DART] Finished printReceipt #${invoice.invoiceNumber}.');
    return true;
  }

  Future<bool> feedPaper({int lines = 3}) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('feedPaper', {'lines': lines});
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> cutPaper() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('cutPaper');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }
}
