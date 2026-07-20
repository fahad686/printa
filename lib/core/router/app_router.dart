import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/receipt_builder/receipt_builder_screen.dart';
import '../../features/receipt_templates/receipt_templates_screen.dart';
import '../../features/qr_generator/qr_generator_screen.dart';
import '../../features/barcode_generator/barcode_generator_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/nfc/nfc_screen.dart';
import '../../features/nfc_invoice/nfc_invoice_screen.dart';
import '../../features/qr_invoice/qr_invoice_screen.dart';
import '../../features/pdf_generator/pdf_generator_screen.dart';
import '../../features/sunmi_printer/sunmi_printer_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/device_info/device_info_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
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
      path: '/scanner',
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/nfc',
      builder: (context, state) => const NFCScreen(),
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
      builder: (context, state) => const PDFGeneratorScreen(),
    ),
    GoRoute(
      path: '/sunmi-printer',
      builder: (context, state) => const SunmiPrinterScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/device-info',
      builder: (context, state) => const DeviceInfoScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
