import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/repositories/settings_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _businessNameController;
  late TextEditingController _currencyController;
  late TextEditingController _taxController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _businessNameController = TextEditingController(text: settings.businessName);
    _currencyController = TextEditingController(text: settings.defaultCurrency);
    _taxController =
        TextEditingController(text: settings.defaultTaxPercentage.toString());
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _currencyController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.watch(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Theme Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appearance & Theme',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'light', label: Text('Light')),
                        ButtonSegment(value: 'dark', label: Text('Dark Mode')),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (val) {
                        settingsNotifier.updateThemeMode(val.first);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Printer Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hardware Printer Width',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 58, label: Text('58 mm (Standard V3)')),
                        ButtonSegment(value: 80, label: Text('80 mm (Wide)')),
                      ],
                      selected: {settings.printerWidth},
                      onSelectionChanged: (val) {
                        settingsNotifier.updatePrinterWidth(val.first);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Business Default Profile
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Business Defaults',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(labelText: 'Default Business Name'),
                      onChanged: (val) {
                        settingsNotifier.updateSettings(
                          settings.copyWith(businessName: val),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _currencyController,
                            decoration:
                                const InputDecoration(labelText: 'Default Currency Symbol'),
                            onChanged: (val) {
                              settingsNotifier.updateSettings(
                                settings.copyWith(defaultCurrency: val),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _taxController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Default Tax %'),
                            onChanged: (val) {
                              final t = double.tryParse(val) ?? 10.0;
                              settingsNotifier.updateSettings(
                                settings.copyWith(defaultTaxPercentage: t),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
