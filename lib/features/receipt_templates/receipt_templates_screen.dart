import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/utils/payload_validator.dart';
import '../../shared/widgets/validation_banner.dart';
import '../../native/sunmi_printer_service.dart';
import '../../shared/models/receipt_template_model.dart';
import '../../shared/repositories/templates_repository.dart';
import '../../shared/widgets/receipt_preview_widget.dart';
import 'template_editor_sheet.dart';
import 'template_export_helper.dart';

class ReceiptTemplatesScreen extends ConsumerStatefulWidget {
  const ReceiptTemplatesScreen({super.key});

  @override
  ConsumerState<ReceiptTemplatesScreen> createState() =>
      _ReceiptTemplatesScreenState();
}

class _ReceiptTemplatesScreenState extends ConsumerState<ReceiptTemplatesScreen> {
  List<ReceiptTemplateModel> _templates = [];
  ReceiptTemplateModel? _selectedTemplate;
  bool _loading = true;
  bool _sharing = false;
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final repo = ref.read(templatesRepositoryProvider);
    await repo.seedDefaultsIfEmpty();
    final templates = repo.getAllTemplates();
    if (mounted) {
      setState(() {
        _templates = templates;
        _selectedTemplate = templates.isNotEmpty ? templates.first : null;
        _loading = false;
      });
    }
  }

  Future<void> _editTemplate() async {
    final current = _selectedTemplate;
    if (current == null) return;

    final updated = await TemplateEditorSheet.show(context, current);
    if (updated == null) return;

    await ref.read(templatesRepositoryProvider).saveTemplate(updated);
    setState(() {
      final index = _templates.indexWhere((t) => t.id == updated.id);
      if (index >= 0) _templates[index] = updated;
      _selectedTemplate = updated;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template "${updated.title}" saved'),
          backgroundColor: AppConstants.primaryOrange,
        ),
      );
    }
  }

  Future<void> _resetTemplate() async {
    final current = _selectedTemplate;
    if (current == null) return;

    await ref.read(templatesRepositoryProvider).resetTemplate(current.id);
    final restored = ref
        .read(templatesRepositoryProvider)
        .getAllTemplates()
        .firstWhere((t) => t.id == current.id);

    setState(() {
      final index = _templates.indexWhere((t) => t.id == restored.id);
      if (index >= 0) _templates[index] = restored;
      _selectedTemplate = restored;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template reset to default')),
      );
    }
  }

  Future<void> _sharePng() async {
    final current = _selectedTemplate;
    if (current == null || _sharing) return;

    setState(() => _sharing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await TemplateExportHelper.shareAsPng(
        template: current,
        previewKey: _previewKey,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PNG share failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _sharePdf() async {
    final current = _selectedTemplate;
    if (current == null || _sharing) return;

    setState(() => _sharing = true);
    try {
      await TemplateExportHelper.shareAsPdf(current);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF share failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _printTemplate() async {
    final current = _selectedTemplate;
    if (current == null) return;

    final printer = ref.read(sunmiPrinterServiceProvider);
    final isSunmi = await printer.isSunmiHardware();
    final status = await printer.getPrinterStatus();
    await printer.printReceipt(current.sampleInvoice);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSunmi
                ? 'Printed ${current.title} on thermal printer ($status)'
                : 'Printed ${current.title} Template!',
          ),
        ),
      );
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: const Text('Share as PNG'),
              subtitle: const Text('Receipt preview image'),
              onTap: () {
                Navigator.pop(context);
                _sharePng();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Share as PDF'),
              subtitle: const Text('Formatted invoice document'),
              onTap: () {
                Navigator.pop(context);
                _sharePdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedTemplate == null) {
      return const Scaffold(
        body: Center(child: Text('No templates available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 2 – Receipt Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit template',
            onPressed: _editTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset to default',
            onPressed: _resetTemplate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Selector Bar
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final tpl = _templates[index];
                final isSelected = tpl.id == _selectedTemplate!.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tpl.title),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTemplate = tpl);
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Template Details Banner
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedTemplate!.title} (${_selectedTemplate!.category})',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            _selectedTemplate!.description,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ValidationBanner(
                            result: PayloadValidator.validateTemplateQrData(
                              _selectedTemplate!.sampleInvoice.toCompactJsonString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit template',
                      onPressed: _editTemplate,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Real-time Preview Stage
          Expanded(
            child: Container(
              color: Colors.black.withOpacity(0.04),
              child: Center(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _previewKey,
                    child: ReceiptPreviewWidget(
                      invoice: _selectedTemplate!.sampleInvoice,
                      templateType: _selectedTemplate!.type,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(14),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editTemplate,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sharing ? null : _showShareOptions,
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _printTemplate,
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
