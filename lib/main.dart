import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/repositories/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Local Storage
  //hive data
  await Hive.initFlutter();
  await Hive.openBox<String>(AppConstants.settingsBox);
  await Hive.openBox<String>(AppConstants.historyBox);
  await Hive.openBox<String>(AppConstants.templatesBox);

  runApp(
    const ProviderScope(
      child: SunmiApp(),
    ),
  );
}

class SunmiApp extends ConsumerWidget {
  const SunmiApp({super.key});

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
