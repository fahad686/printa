import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/utils/payload_validator.dart';
import '../../shared/widgets/validation_banner.dart';
import '../../native/sunmi_printer_service.dart';
import '../../shared/models/history_item_model.dart';
import '../../shared/repositories/history_repository.dart';

class QRGeneratorScreen extends ConsumerStatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  ConsumerState<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends ConsumerState<QRGeneratorScreen> {
  final GlobalKey _qrKey = GlobalKey();
  final FocusNode _payloadFocus = FocusNode();
  String _qrType = 'Plain Text';
  final TextEditingController _inputController =
      TextEditingController(text: 'https://printa.app');

  double _qrSize = 200.0;
  Color _fgColor = Colors.black;
  Color _bgColor = Colors.white;
  bool _sharing = false;

  void _dismissKeyboard() {
    _payloadFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  final List<String> _types = [
    'Plain Text',
    'URL',
    'Invoice JSON',
    'WiFi',
    'Phone Number',
    'Email',
    'vCard',
    'UPI / Payment',
  ];

  @override
  void dispose() {
    _payloadFocus.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? type) {
    if (type == null) return;
    _dismissKeyboard();
    setState(() {
      _qrType = type;
      switch (type) {
        case 'URL':
          _inputController.text = 'https://printa.app';
          break;
        case 'Invoice JSON':
          _inputController.text = '{"inv":"INV-909","total":150.0,"cust":"Alice"}';
          break;
        case 'WiFi':
          _inputController.text = 'WIFI:S:MyCafe_5G;T:WPA;P:Password123;;';
          break;
        case 'Phone Number':
          _inputController.text = 'tel:+18005550199';
          break;
        case 'Email':
          _inputController.text = 'mailto:support@printa.app?subject=Inquiry';
          break;
        case 'vCard':
          _inputController.text =
              'BEGIN:VCARD\nVERSION:3.0\nN:Smith;John\nORG:Printa Tech\nTEL:+18005550199\nEND:VCARD';
          break;
        case 'UPI / Payment':
          _inputController.text =
              'upi://pay?pa=printa@bank&pn=PrintaTech&am=50.00&cu=USD';
          break;
        default:
          _inputController.text = 'Hello Printa POS';
      }
    });
  }

  void _pickColor(bool isFg) {
    _dismissKeyboard();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select ${isFg ? "Foreground" : "Background"} Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: isFg ? _fgColor : _bgColor,
            onColorChanged: (color) {
              setState(() {
                if (isFg) {
                  _fgColor = color;
                } else {
                  _bgColor = color;
                }
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _printQr() async {
    _dismissKeyboard();
    final validation =
        PayloadValidator.validateQrPayload(_qrType, _inputController.text);
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.message)),
      );
      return;
    }

    final printer = ref.read(sunmiPrinterServiceProvider);
    await printer.printQRCode(data: _inputController.text);

    await ref.read(historyRepositoryProvider).addHistoryItem(
          HistoryItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'QR Code ($_qrType)',
            category: 'qr',
            timestamp: DateTime.now(),
            payload: _inputController.text,
          ),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code sent to thermal printer!')),
      );
    }
  }

  Future<ui.Image?> _captureQrImage() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    return boundary.toImage(pixelRatio: 3.0);
  }

  Future<void> _shareQrImage() async {
    _dismissKeyboard();
    final validation =
        PayloadValidator.validateQrPayload(_qrType, _inputController.text);
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.message)),
      );
      return;
    }
    if (_sharing) return;

    setState(() => _sharing = true);
    try {
      // Let the frame settle so RepaintBoundary is painted.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final image = await _captureQrImage();
      if (image == null) {
        throw Exception('Could not capture QR image');
      }

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Could not encode QR PNG');
      }

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final safeType = _qrType.replaceAll(RegExp(r'[^\w]+'), '_').toLowerCase();
      final file = File(
        '${dir.path}/printa_qr_${safeType}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: 'printa_qr_$safeType.png')],
        text: 'QR ($_qrType): ${_inputController.text}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share QR failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _sharePayload() async {
    _dismissKeyboard();
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    await Share.share(text, subject: 'QR Payload ($_qrType)');
  }

  @override
  Widget build(BuildContext context) {
    final validation =
        PayloadValidator.validateQrPayload(_qrType, _inputController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 3 – QR Generator'),
        actions: [
          IconButton(
            tooltip: 'Share QR image',
            onPressed: validation.isValid && !_sharing ? _shareQrImage : null,
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismissKeyboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: _inputController.text.isEmpty
                              ? 'Printa'
                              : _inputController.text,
                          version: QrVersions.auto,
                          size: _qrSize,
                          backgroundColor: _bgColor,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: _fgColor,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: _fgColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Format: $_qrType',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _qrType,
                      decoration: const InputDecoration(labelText: 'Data Type'),
                      items: _types.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: _onTypeChanged,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _inputController,
                      focusNode: _payloadFocus,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: _dismissKeyboard,
                      onTapOutside: (_) => _dismissKeyboard(),
                      decoration: InputDecoration(
                        labelText: 'Payload Data',
                        suffixIcon: IconButton(
                          tooltip: 'Hide keyboard',
                          onPressed: _dismissKeyboard,
                          icon: const Icon(Icons.keyboard_hide_rounded),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    ValidationBanner(result: validation),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Size: ${_qrSize.toInt()} px'),
                              Slider(
                                value: _qrSize,
                                min: 120,
                                max: 280,
                                activeColor: AppConstants.primaryOrange,
                                onChangeStart: (_) => _dismissKeyboard(),
                                onChanged: (val) =>
                                    setState(() => _qrSize = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _pickColor(true),
                          icon: Icon(Icons.circle, color: _fgColor),
                          label: const Text('Foreground'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _pickColor(false),
                          icon: Icon(Icons.circle, color: _bgColor),
                          label: const Text('Background'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: validation.isValid ? _printQr : null,
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print QR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        validation.isValid && !_sharing ? _shareQrImage : null,
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Share QR'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _inputController.text.trim().isEmpty
                    ? null
                    : _sharePayload,
                icon: const Icon(Icons.text_snippet_rounded),
                label: const Text('Share Payload Text'),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
