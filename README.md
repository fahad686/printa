# Printa

A modular Flutter app for **handheld POS devices and thermal printers**. Design, preview, and print receipts, QR codes, barcodes, NFC tags, and PDF invoices — with a focus on SUNMI-style POS hardware (e.g. V3) and graceful fallbacks on phones and simulators.

**Developed by** Fahad Ali, Senior Mobile App Consultant.

---

## Highlights

- **Splash & onboarding** — first-run intro, then home
- **Floating pill bottom nav** — Dashboard · Scanner · NFC · History · Settings
- **Printa orange** Material 3 light/dark themes
- **Built-in thermal printing** via Sunmi printer library + MethodChannels (Android POS)
- **Offline-first** Hive storage for settings, history, and templates

---

## Features & Modules

| Module | Description |
|--------|-------------|
| **Dashboard** | Module grid, hardware status banner (printer, paper, battery, RAM, storage) |
| **1 – Receipt Builder** | Dynamic receipts with tax/discount, live preview, thermal print, PDF, share |
| **2 – Receipt Templates** | 8 presets; edit, persist in Hive, share as PNG/PDF |
| **3 – QR Generator** | Plain text, URL, Invoice JSON, WiFi, Phone, Email, vCard, UPI — print & share |
| **4 – Barcode Generator** | Code128, Code39, EAN13, EAN8, UPC-A, PDF417, Data Matrix |
| **5 – Scanner** | Hardware laser (MethodChannel) + camera fallback (`mobile_scanner`) |
| **6 – NFC Manager** | Read / write / update / erase NDEF; UID & tech inspection |
| **7 – Invoice in NFC** | Encode receipt JSON on tags; tap to reconstruct, preview, print |
| **8 – QR to Receipt** | Offline invoice transfer via QR encode → scan → print |
| **9 – PDF Generator** | A4 / 58mm / 80mm roll + signature canvas |
| **10 – Printer Test Bench** | Alignments, styles, tables, feed, cut, status |
| **11 – History Box** | Hive log of receipts, scans, QRs, barcodes, NFC, PDFs — search, filter, reprint |
| **12 – Device Info & Settings** | Diagnostics and global prefs (business, tax, paper width, theme) |

---

## Technology Stack

| Area | Choice |
|------|--------|
| Framework | Flutter (Dart 3.x) |
| State | Riverpod (`flutter_riverpod`) |
| Routing | `go_router` + `StatefulShellRoute` (tab shell) |
| Storage | Hive (`hive`, `hive_flutter`) |
| PDF / share | `pdf`, `printing`, `share_plus` |
| Codes | `qr_flutter`, `barcode_widget`, `mobile_scanner` |
| NFC | `nfc_manager` |
| Printer (Android) | `com.sunmi:printerlibrary` + MethodChannels `com.sunmi.hardware/*` |
| UI | Material 3, Printa orange brand palette |

---

## Project Structure

```text
lib/
├── main.dart
├── core/
│   ├── constants/app_constants.dart
│   ├── router/app_router.dart          # Splash, onboarding, shell tabs, feature routes
│   └── theme/app_theme.dart
├── native/
│   ├── sunmi_printer_service.dart
│   ├── sunmi_scanner_service.dart
│   └── device_info_service.dart
├── shared/
│   ├── models/
│   ├── repositories/                 # Settings, history, templates
│   ├── utils/
│   └── widgets/                      # Floating pill nav, cards, preview, validation…
└── features/
    ├── splash/
    ├── onboarding/
    ├── shell/                        # MainShell + floating pill bottom nav
    ├── dashboard/
    ├── receipt_builder/
    ├── receipt_templates/
    ├── qr_generator/
    ├── barcode_generator/
    ├── scanner/
    ├── nfc/                          # Hub + read/write/update/delete
    ├── nfc_invoice/
    ├── qr_invoice/
    ├── pdf_generator/
    ├── sunmi_printer/
    ├── history/
    ├── device_info/
    └── settings/
```

**Primary tab routes:** `/` · `/scanner` · `/nfc` · `/history` · `/settings`  
Module screens (receipt builder, PDF, printer bench, etc.) push full-screen without the bottom bar.

---

## Getting Started

### Prerequisites

- Flutter SDK matching `pubspec.yaml` (`sdk: ^3.11.5`)
- Android SDK / Android Studio (Java 17+)
- For real thermal print & laser scan: a compatible handheld POS (e.g. SUNMI V3)
- Phones / simulators: UI, PDF, QR, camera scanner, and mocks work; built-in thermal print is POS/Android-oriented

### Run

```bash
flutter pub get
dart analyze
flutter run
```

### Wireless Android (example)

```bash
flutter devices
flutter run -d <device-id>
```

---

## Platform notes

- **Android POS:** Inner printer via Sunmi `InnerPrinterManager` / AIDL service `woyou.aidlservice.jiuiv5`
- **Non-POS Android / iOS:** MethodChannel calls fail safely; camera scanner and PDF/share still work
- **NFC:** Requires NFC hardware + permission; hub shows availability clearly

---

## License

This project is licensed under the MIT License.
