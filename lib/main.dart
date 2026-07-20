import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/repositories/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error handler — logs instead of crashing to black screen
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[FLUTTER_ERROR] ${details.exceptionAsString()}');
    debugPrint('[FLUTTER_ERROR] Stack: ${details.stack}');
    FlutterError.presentError(details);
  };

  // Initialize Hive Local Storage
  debugPrint('[MAIN] Initializing Hive...');
  await Hive.initFlutter();

  // Open boxes with individual guards so one failure doesn't kill the app
  for (final boxName in [
    AppConstants.settingsBox,
    AppConstants.historyBox,
    AppConstants.templatesBox,
  ]) {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox<String>(boxName);
      }
      debugPrint('[MAIN] Hive box opened: $boxName');
    } catch (e) {
      debugPrint('[MAIN] WARNING: Failed to open Hive box "$boxName": $e');
      // Delete and recreate corrupt box
      try {
        await Hive.deleteBoxFromDisk(boxName);
        await Hive.openBox<String>(boxName);
        debugPrint('[MAIN] Hive box recreated: $boxName');
      } catch (e2) {
        debugPrint('[MAIN] CRITICAL: Could not recreate box "$boxName": $e2');
      }
    }
  }

  debugPrint('[MAIN] Starting PrintaApp...');
  runApp(
    const ProviderScope(
      child: PrintaApp(),
    ),
  );
}

class PrintaApp extends ConsumerWidget {
  const PrintaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode == 'light' ? ThemeMode.light : ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
