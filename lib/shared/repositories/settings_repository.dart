import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../models/app_settings_model.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsModel>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});

class SettingsNotifier extends StateNotifier<AppSettingsModel> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(_repo.getSettings());

  Future<void> updateSettings(AppSettingsModel newSettings) async {
    state = newSettings;
    await _repo.saveSettings(newSettings);
  }

  Future<void> updateThemeMode(String themeMode) async {
    final updated = state.copyWith(themeMode: themeMode);
    await updateSettings(updated);
  }

  Future<void> updatePrinterWidth(int width) async {
    final updated = state.copyWith(printerWidth: width);
    await updateSettings(updated);
  }

  Future<void> completeOnboarding() async {
    final updated = state.copyWith(onboardingCompleted: true);
    await updateSettings(updated);
  }
}

class SettingsRepository {
  Box<String>? _box;

  Box<String> get box {
    if (_box == null || !_box!.isOpen) {
      _box = Hive.box<String>(AppConstants.settingsBox);
    }
    return _box!;
  }

  AppSettingsModel getSettings() {
    final raw = box.get('app_settings');
    if (raw != null) {
      try {
        return AppSettingsModel.fromJsonString(raw);
      } catch (_) {
        return AppSettingsModel();
      }
    }
    return AppSettingsModel();
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    await box.put('app_settings', settings.toJsonString());
  }
}
