import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/floating_pill_nav_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    FloatingPillNavItem(
      icon: Icons.grid_view_rounded,
      label: 'DASHBOARD',
    ),
    FloatingPillNavItem(
      icon: Icons.qr_code_scanner_rounded,
      label: 'SCANNER',
    ),
    FloatingPillNavItem(
      icon: Icons.nfc_rounded,
      label: 'NFC',
    ),
    FloatingPillNavItem(
      icon: Icons.view_list_rounded,
      label: 'HISTORY',
    ),
    FloatingPillNavItem(
      icon: Icons.settings_rounded,
      label: 'SETTINGS',
    ),
  ];

  /// Extra space so tab content clears the floating pill.
  static const double navClearance = 88;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      extendBody: true,
      body: MediaQuery(
        data: media.copyWith(
          padding: media.padding.copyWith(
            bottom: media.padding.bottom + navClearance,
          ),
          viewPadding: media.viewPadding.copyWith(
            bottom: media.viewPadding.bottom + navClearance,
          ),
        ),
        child: navigationShell,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: FloatingPillNavBar(
            currentIndex: navigationShell.currentIndex,
            items: _items,
            onTap: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        ),
      ),
    );
  }
}
