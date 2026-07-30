import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/history_item_model.dart';
import '../../shared/repositories/history_repository.dart';
import 'pdf_helper.dart';

class PhotoToPdfScreen extends ConsumerStatefulWidget {
  const PhotoToPdfScreen({super.key});

  @override
  ConsumerState<PhotoToPdfScreen> createState() => _PhotoToPdfScreenState();
}

class _PhotoToPdfScreenState extends ConsumerState<PhotoToPdfScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController =
      TextEditingController(text: 'photos_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
  final List<String> _photoPaths = [];
  String _pageFormatType = 'A4';
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  PdfPageFormat _pageFormat() {
    switch (_pageFormatType) {
      case 'Letter':
        return PdfPageFormat.letter;
      case 'Fit Photo':
        // Square-ish page that adapts well to most photos.
        return const PdfPageFormat(
          10 * PdfPageFormat.cm,
          10 * PdfPageFormat.cm,
          marginAll: 8,
        );
      default:
        return PdfPageFormat.a4;
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;
      setState(() {
        _photoPaths.addAll(images.map((x) => x.path));
      });
    } catch (e) {
      _snack('Could not pick images: $e');
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (shot == null) return;
      setState(() => _photoPaths.add(shot.path));
    } catch (e) {
      _snack('Could not open camera: $e');
    }
  }

  void _removeAt(int index) {
    setState(() => _photoPaths.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final path = _photoPaths.removeAt(oldIndex);
      _photoPaths.insert(newIndex, path);
    });
  }

  String get _fileName => '${PdfHelper.sanitizeFileName(_nameController.text, fallback: 'photos')}.pdf';

  Future<Uint8List> _buildPdf() {
    return PdfHelper.generatePhotosPdf(
      _photoPaths,
      pageFormat: _pageFormat(),
      title: _fileName,
    );
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && success != null) _snack(success);
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _ensureHasPhotos() {
    if (_photoPaths.isEmpty) {
      _snack('Add at least one photo first');
      return false;
    }
    return true;
  }

  void _viewPdf() {
    if (!_ensureHasPhotos()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoPdfPreviewScreen(
          fileName: _fileName,
          builder: _buildPdf,
        ),
      ),
    );
  }

  Future<void> _sharePdf() async {
    if (!_ensureHasPhotos()) return;
    await _run(() async {
      final bytes = await _buildPdf();
      await PdfHelper.sharePdfBytes(
        bytes,
        fileName: _fileName,
        text: _fileName,
      );
    });
  }

  Future<void> _saveHistory() async {
    if (!_ensureHasPhotos()) return;
    await _run(() async {
      await ref.read(historyRepositoryProvider).addHistoryItem(
            HistoryItemModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: _fileName,
              category: 'pdf',
              timestamp: DateTime.now(),
              payload: _fileName,
              subtitle: '${_photoPaths.length} photo(s) • $_pageFormatType',
            ),
          );
    }, success: 'Saved to history');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhotos = _photoPaths.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo to PDF'),
        actions: [
          if (hasPhotos)
            IconButton(
              tooltip: 'Clear all',
              onPressed: () => setState(() => _photoPaths.clear()),
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: theme.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'PDF file name',
                    suffixText: '.pdf',
                    prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Page:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'A4', label: Text('A4')),
                          ButtonSegment(value: 'Letter', label: Text('Letter')),
                          ButtonSegment(value: 'Fit Photo', label: Text('Fit')),
                        ],
                        selected: {_pageFormatType},
                        onSelectionChanged: (val) =>
                            setState(() => _pageFormatType = val.first),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _captureFromCamera,
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: hasPhotos ? _buildPhotoList(theme) : _buildEmptyState(theme),
          ),
          _buildBottomBar(theme, hasPhotos),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 56,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 14),
            Text(
              'No photos yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Add photos from your gallery or camera.\nDrag to reorder — each photo becomes a page.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoList(ThemeData theme) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _photoPaths.length,
      onReorder: _reorder,
      itemBuilder: (context, index) {
        final path = _photoPaths[index];
        return Card(
          key: ValueKey(path),
          margin: const EdgeInsets.only(bottom: 10),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(path),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 52,
                  height: 52,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_rounded),
                ),
              ),
            ),
            title: Text(
              'Page ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              path.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: theme.hintColor),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => _removeAt(index),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4, right: 4),
                    child: Icon(Icons.drag_handle_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool hasPhotos) {
    return Material(
      elevation: 8,
      color: theme.cardColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasPhotos && !_busy ? _viewPdf : null,
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasPhotos && !_busy ? _saveHistory : null,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasPhotos && !_busy ? _sharePdf : null,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPdfPreviewScreen extends StatelessWidget {
  final String fileName;
  final Future<Uint8List> Function() builder;

  const _PhotoPdfPreviewScreen({
    required this.fileName,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: PdfPreview(
        build: (_) => builder(),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: fileName,
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: AppConstants.primaryOrange),
        ),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not render PDF\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
