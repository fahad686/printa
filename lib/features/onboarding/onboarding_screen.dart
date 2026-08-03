import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/repositories/settings_repository.dart';

class _OnboardPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool showLogo;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    this.showLogo = false,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.print_rounded,
      showLogo: true,
      title: 'Print receipts instantly',
      subtitle: 'Thermal printing',
      description:
          'Design and send receipts to your handheld POS thermal printer in one tap — tables, totals, QR, and barcodes included.',
    ),
    _OnboardPage(
      icon: Icons.dashboard_customize_rounded,
      title: 'Templates that fit your business',
      subtitle: '8 ready-made styles',
      description:
          'Restaurant, retail, pharmacy, courier, and more. Edit sample data, preview live, then share as PNG or PDF.',
    ),
    _OnboardPage(
      icon: Icons.qr_code_2_rounded,
      title: 'QR, barcodes & scanning',
      subtitle: 'Generate & capture',
      description:
          'Create validated QR and barcode payloads, print them on paper, or scan with the camera and hardware laser.',
    ),
    _OnboardPage(
      icon: Icons.nfc_rounded,
      title: 'NFC tags',
      subtitle: 'Read · Write · Update · Erase',
      description:
          'Store data on NFC tags, update payloads, and erase details from the NFC Manager.',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(settingsNotifierProvider.notifier).completeOnboarding();
    if (mounted) context.go('/');
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLast = _index == _pages.length - 1;
    const accent = AppConstants.primaryOrange;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppConstants.darkBg,
                    const Color(0xFF1A120E),
                    AppConstants.darkBg,
                  ]
                : [
                    AppConstants.orangeSoft,
                    AppConstants.lightBg,
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    if (_index > 0)
                      IconButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, color: accent),
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          const Spacer(flex: 1),
                          if (p.showLogo)
                            Container(
                              width: 104,
                              height: 104,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.28),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  AppConstants.logoAsset,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: AppConstants.brandGradientSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent.withOpacity(0.28),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(p.icon, size: 56, color: accent),
                            ),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p.subtitle.toUpperCase(),
                              style: const TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            p.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            p.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black.withOpacity(0.65),
                            ),
                          ),
                          const Spacer(flex: 2),
                        ],
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? accent : accent.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _next,
                        child: Text(
                          isLast ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (isLast) ...[
                      const SizedBox(height: 12),
                      Text(
                        'By ${AppConstants.developerName} · ${AppConstants.developerTitle}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: accent.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
