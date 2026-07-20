import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../models/receipt_template_model.dart';

final templatesRepositoryProvider = Provider<TemplatesRepository>((ref) {
  return TemplatesRepository();
});

class TemplatesRepository {
  Box<String>? _box;

  Box<String> get box {
    if (_box == null || !_box!.isOpen) {
      _box = Hive.box<String>(AppConstants.templatesBox);
    }
    return _box!;
  }

  List<ReceiptTemplateModel> getAllTemplates() {
    if (box.isEmpty) {
      return ReceiptTemplateModel.defaultTemplates;
    }
    return box.values
        .map((s) => ReceiptTemplateModel.fromJsonString(s))
        .toList();
  }

  Future<void> seedDefaultsIfEmpty() async {
    if (box.isNotEmpty) return;
    for (final tpl in ReceiptTemplateModel.defaultTemplates) {
      await box.put(tpl.id, tpl.toJsonString());
    }
  }

  Future<void> saveTemplate(ReceiptTemplateModel template) async {
    await box.put(template.id, template.toJsonString());
  }

  Future<void> resetTemplate(String id) async {
    final original = ReceiptTemplateModel.defaultTemplates
        .where((t) => t.id == id)
        .firstOrNull;
    if (original != null) {
      await box.put(id, original.toJsonString());
    }
  }

  Future<void> resetAll() async {
    await box.clear();
    await seedDefaultsIfEmpty();
  }
}
