import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../models/history_item_model.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

class HistoryRepository {
  Box<String>? _box;

  Box<String> get box {
    if (_box == null || !_box!.isOpen) {
      _box = Hive.box<String>(AppConstants.historyBox);
    }
    return _box!;
  }

  Future<void> addHistoryItem(HistoryItemModel item) async {
    await box.put(item.id, item.toJsonString());
  }

  List<HistoryItemModel> getAllHistory() {
    final rawList = box.values.toList();
    final items = rawList.map((s) => HistoryItemModel.fromJsonString(s)).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  List<HistoryItemModel> getByCategory(String category) {
    return getAllHistory().where((item) => item.category == category).toList();
  }

  List<HistoryItemModel> searchHistory(String query) {
    if (query.trim().isEmpty) return getAllHistory();
    final q = query.toLowerCase();
    return getAllHistory().where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.payload.toLowerCase().contains(q) ||
          (item.subtitle?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> deleteHistoryItem(String id) async {
    await box.delete(id);
  }

  Future<void> clearAll() async {
    await box.clear();
  }
}
