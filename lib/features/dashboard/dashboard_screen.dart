import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../native/device_info_service.dart';

// ─── Module descriptor ───────────────────────────────────────────────────────

class _Module {
  const _Module({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
}

// ─── Quick action descriptor ──────────────────────────────────────────────────

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.route,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final String route;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // Quick‐access shortcuts shown in the horizontal strip
  static const _quickActions = [
    _QuickAction(
      label: 'New Receipt',
      icon: Icons.receipt_long_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFFF6600), Color(0xFFE55A00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/receipt-builder',
    ),
    _QuickAction(
      label: 'QR Code',
      icon: Icons.qr_code_2_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/qr-generator',
    ),
    _QuickAction(
      label: 'Barcode',
      icon: Icons.qr_code_scanner_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/barcode-generator',
    ),
    _QuickAction(
      label: 'Scan',
      icon: Icons.center_focus_strong_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF047857)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/scanner',
    ),
  ];

  // All 13 modules
  static const _modules = [
    _Module(
      title: 'Receipt Builder',
      description: 'Build & print receipts',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFFF6600),
      route: '/receipt-builder',
    ),
    _Module(
      title: 'Templates',
      description: '8 ready presets',
      icon: Icons.dashboard_customize_rounded,
      color: Color(0xFF7C3AED),
      route: '/receipt-templates',
    ),
    _Module(
      title: 'QR Generator',
      description: 'Custom QR codes',
      icon: Icons.qr_code_2_rounded,
      color: Color(0xFF0891B2),
      route: '/qr-generator',
    ),
    _Module(
      title: 'Barcode Gen',
      description: '7 formats supported',
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFFFF6600),
      route: '/barcode-generator',
    ),
    _Module(
      title: 'Scanner',
      description: 'Laser & camera',
      icon: Icons.center_focus_strong_rounded,
      color: Color(0xFF2563EB),
      route: '/scanner',
    ),
    _Module(
      title: 'NFC Manager',
      description: 'Read & write tags',
      icon: Icons.nfc_rounded,
      color: Color(0xFF059669),
      route: '/nfc',
    ),
    _Module(
      title: 'Photo to PDF',
      description: 'Pick, rename & share',
      icon: Icons.add_photo_alternate_rounded,
      color: Color(0xFF7C3AED),
      route: '/photo-to-pdf',
    ),
    _Module(
      title: 'Printer Bench',
      description: 'Test & calibrate',
      icon: Icons.print_rounded,
      color: Color(0xFFFF6600),
      route: '/sunmi-printer',
    ),
    _Module(
      title: 'History Box',
      description: 'Database & logs',
      icon: Icons.storage_rounded,
      color: Color(0xFFE55A00),
      route: '/history',
    ),
    _Module(
      title: 'Device Info',
      description: 'Hardware diagnostics',
      icon: Icons.perm_device_information_rounded,
      color: Color(0xFF059669),
      route: '/device-info',
    ),
  ];

  // Derive a time-of-day greeting
  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 👋';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceInfoAsync = ref.watch(deviceInfoServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D0D10) : AppConstants.lightBg,
      body: FutureBuilder<DeviceMetrics>(
        future: deviceInfoAsync.getDeviceMetrics(),
        builder: (context, snapshot) {
          final metrics = snapshot.data;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── SliverAppBar (collapsible header) ────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(context, isDark),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Device status card ──────────────────────────────────
                    _DeviceStatusCard(metrics: metrics),

                    const SizedBox(height: 20),

                    // ── Quick actions ───────────────────────────────────────
                    _SectionTitle(title: 'Quick Actions'),
                    const SizedBox(height: 10),
                    _QuickActionsRow(actions: _quickActions),

                    const SizedBox(height: 24),

                    // ── All modules ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(title: 'All Modules'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  AppConstants.primaryOrange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${_modules.length} tools',
                            style: const TextStyle(
                              color: AppConstants.primaryOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Module grid ─────────────────────────────────────────
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.55,
                      ),
                      itemCount: _modules.length,
                      itemBuilder: (context, i) =>
                          _ModuleCard(module: _modules[i]),
                    ),

                    const SizedBox(height: 20),

                    // ── Footer ──────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Developed by ${AppConstants.developerName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppConstants.developerTitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppConstants.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    // Initials avatar from developer name
    final nameParts = AppConstants.developerName.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'
        : AppConstants.developerName.substring(0, 2).toUpperCase();

    return Stack(
      children: [
        // Ambient orange glow at top
        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppConstants.primaryOrange.withOpacity(isDark ? 0.18 : 0.1),
                  Colors.transparent,
                ],
                radius: 0.9,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 12,
            16,
            16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white54
                            : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Printa Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppConstants.primaryOrange, AppConstants.orangeDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryOrange.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Device Status Card ────────────────────────────────────────────────────────

class _DeviceStatusCard extends StatelessWidget {
  const _DeviceStatusCard({required this.metrics});
  final DeviceMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final m = metrics;

    // Use the real device name from DeviceMetrics
    final deviceLabel = m?.deviceName ?? 'Connecting…';
    final battery = m?.batteryLevel ?? 0;
    final printerStatus = m?.printerStatus ?? '…';
    final paperStatus = m?.paperStatus ?? '…';
    final isLoaded = m != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A22).withOpacity(0.85)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryOrange.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryOrange.withOpacity(isDark ? 0.12 : 0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: LIVE indicator + device name + battery/wifi ──────────
          Row(
            children: [
              // Pulsing live dot
              _LiveIndicator(isLoaded: isLoaded),
              const SizedBox(width: 6),
              Text(
                isLoaded ? 'LIVE' : 'LOADING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isLoaded ? const Color(0xFF22C55E) : Colors.orange,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              // Battery icon
              Row(
                children: [
                  Icon(
                    battery > 60
                        ? Icons.battery_full_rounded
                        : battery > 30
                            ? Icons.battery_4_bar_rounded
                            : Icons.battery_alert_rounded,
                    size: 16,
                    color: battery > 30
                        ? AppConstants.primaryOrange
                        : Colors.red,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isLoaded ? '$battery%' : '--',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: battery > 30
                          ? AppConstants.primaryOrange
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.wifi_rounded,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Device name (dynamic) ─────────────────────────────────────────
          Text(
            deviceLabel,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            isLoaded
                ? 'Printer ${m.printerStatus} • Battery $battery% • Paper ${m.paperStatus}'
                : 'Fetching device information…',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // ── Stat pills ────────────────────────────────────────────────────
          Row(
            children: [
              _StatPill(
                icon: Icons.print_rounded,
                label: printerStatus,
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.bolt_rounded,
                label: isLoaded ? '$battery%' : '…',
                color: AppConstants.primaryOrange,
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.article_rounded,
                label: paperStatus,
                color: const Color(0xFF0891B2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pulsing live indicator ───────────────────────────────────────────────────

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator({required this.isLoaded});
  final bool isLoaded;

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isLoaded ? const Color(0xFF22C55E) : Colors.orange;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

// ── Stat pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }
}

// ─── Quick Actions Row ────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});
  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final a = actions[i];
          return _QuickActionButton(action: a);
        },
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({required this.action});
  final _QuickAction action;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    const tabRoutes = {'/', '/scanner', '/nfc', '/history', '/settings'};
    if (tabRoutes.contains(widget.action.route)) {
      context.go(widget.action.route);
    } else {
      context.push(widget.action.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          _onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: 76,
          decoration: BoxDecoration(
            gradient: widget.action.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.action.gradient.colors.first.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.action.icon, color: Colors.white, size: 26),
              const SizedBox(height: 6),
              Text(
                widget.action.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Module Card ───────────────────────────────────────────────────────────────

class _ModuleCard extends StatefulWidget {
  const _ModuleCard({required this.module});
  final _Module module;

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    const tabRoutes = {'/', '/scanner', '/nfc', '/history', '/settings'};
    if (tabRoutes.contains(widget.module.route)) {
      context.go(widget.module.route);
    } else {
      context.push(widget.module.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final m = widget.module;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          _onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1A22)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.25)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gradient icon container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      m.color,
                      m.color.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: m.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(m.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      m.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.white38
                            : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
