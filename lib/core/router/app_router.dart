import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/receipt_builder/receipt_builder_screen.dart';
import '../../features/receipt_templates/receipt_templates_screen.dart';
import '../../features/qr_generator/qr_generator_screen.dart';
import '../../features/barcode_generator/barcode_generator_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/nfc/nfc_screen.dart';
import '../../features/nfc/nfc_read_screen.dart';
import '../../features/nfc/nfc_write_screen.dart';
import '../../features/nfc/nfc_update_screen.dart';
import '../../features/nfc/nfc_delete_screen.dart';
import '../../features/nfc_invoice/nfc_invoice_screen.dart';
import '../../features/qr_invoice/qr_invoice_screen.dart';
import '../../features/pdf_generator/pdf_edit_screen.dart';
import '../../features/pdf_generator/pdf_preview_screen.dart';
import '../../features/pdf_generator/photo_to_pdf_screen.dart';
import '../../features/sunmi_printer/sunmi_printer_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/device_info/device_info_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/scanner',
              builder: (context, state) => const ScannerScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nfc',
              builder: (context, state) => const NFCScreen(),
              routes: [
                GoRoute(
                  path: 'read',
                  builder: (context, state) => const NfcReadScreen(),
                ),
                GoRoute(
                  path: 'write',
                  builder: (context, state) => const NfcWriteScreen(),
                ),
                GoRoute(
                  path: 'update',
                  builder: (context, state) => const NfcUpdateScreen(),
                ),
                GoRoute(
                  path: 'delete',
                  builder: (context, state) => const NfcDeleteScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/receipt-builder',
      builder: (context, state) => const ReceiptBuilderScreen(),
    ),
    GoRoute(
      path: '/receipt-templates',
      builder: (context, state) => const ReceiptTemplatesScreen(),
    ),
    GoRoute(
      path: '/qr-generator',
      builder: (context, state) => const QRGeneratorScreen(),
    ),
    GoRoute(
      path: '/barcode-generator',
      builder: (context, state) => const BarcodeGeneratorScreen(),
    ),
    GoRoute(
      path: '/nfc-invoice',
      builder: (context, state) => const NFCInvoiceScreen(),
    ),
    GoRoute(
      path: '/qr-invoice',
      builder: (context, state) => const QRInvoiceScreen(),
    ),
    GoRoute(
      path: '/pdf-generator',
      builder: (context, state) => const PdfEditScreen(),
      routes: [
        GoRoute(
          path: 'preview',
          builder: (context, state) => const PdfPreviewScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/photo-to-pdf',
      builder: (context, state) => const PhotoToPdfScreen(),
    ),
    GoRoute(
      path: '/sunmi-printer',
      builder: (context, state) => const SunmiPrinterScreen(),
    ),
    GoRoute(
      path: '/device-info',
      builder: (context, state) => const DeviceInfoScreen(),
    ),
  ],
);
