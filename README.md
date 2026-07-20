# SUNMI Hardware Test Suite

A modular, production-quality Flutter application designed to test and showcase every important hardware capability of **SUNMI V3** handheld POS devices. 

---

## 📱 Features & Modules

- **Dashboard:** Modern Material 3 grid with real-time hardware status indicators (Printer status, Paper status, Battery %, RAM, Storage).
- **Module 1 – Receipt Builder:** Dynamic receipt creation with auto-calculated subtotals, tax %, discounts, item line management, live preview, thermal printing, PDF export, and sharing.
- **Module 2 – Receipt Templates:** Live interactive preview switcher with 8 pre-designed receipt styles (*Restaurant*, *Retail*, *Pharmacy*, *Courier*, *Parking Ticket*, *Warehouse*, *Simple Invoice*, *Dark Theme Receipt*).
- **Module 3 – QR Generator:** Supports 8 payload formats (Plain Text, URL, Invoice JSON, WiFi, Phone, Email, vCard, UPI/Payment) with custom QR sizing, foreground/background color pickers, and direct thermal printing.
- **Module 4 – Barcode Generator:** Symbology support for 7 formats (**Code128**, **Code39**, **EAN13**, **EAN8**, **UPC-A**, **PDF417**, **Data Matrix**).
- **Module 5 – Scanner:** Dual-mode barcode scanner supporting hardware SUNMI laser broadcast triggers via MethodChannel with camera fallback (`mobile_scanner`).
- **Module 6 – NFC Manager:** NDEF tag reading, writing, erasing, and locking with tag UID and technology inspection.
- **Module 7 – Invoice in NFC:** Encode dynamic receipt JSON onto NDEF tags. Tap tag to read, reconstruct, preview, and print invoices.
- **Module 8 – QR to Receipt (Offline Invoice Transfer):** Encode invoices into QR codes; scan with camera/laser to reconstruct receipts offline for instant printing.
- **Module 9 – PDF Generator:** Multi-format PDF exporter (A4, 58mm roll, 80mm roll) with an interactive digital signature drawing canvas.
- **Module 10 – SUNMI Printer Direct Test Bench:** Command bench for text alignments (Left, Center, Right), text styles (Bold, Underline, Font Sizes), tables, paper feeding, paper cutting, and status queries.
- **Module 11 – History Box:** Local Hive database persisting all printed receipts, scanned codes, generated QRs/barcodes, NFC logs, and PDFs with search, category filters, and re-printing capabilities.
- **Module 12 – Device Information & Settings:** Comprehensive system diagnostics and global application preferences.

---

## 🛠️ Technology Stack

- **Framework:** Flutter Stable (Dart 3.x)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Architecture:** Clean Architecture + MVVM + Repository Pattern
- **Routing:** `go_router`
- **Local Database:** Hive (`hive`, `hive_flutter`)
- **PDF & Printing:** `pdf`, `printing`
- **Hardware Integrations:** SUNMI AIDL MethodChannel (`com.sunmi.hardware/*`) with fallback mocks for non-SUNMI devices
- **NFC & Scanner:** `nfc_manager`, `mobile_scanner`
- **UI & Aesthetics:** Material 3 Dark/Light themes

---

## 📂 Project Structure

```text
lib/
├── main.dart                          # App Entrypoint & Hive Initialization
├── core/
│   ├── constants/app_constants.dart   # Brand colors, defaults, Hive keys
│   ├── router/app_router.dart         # GoRouter path definitions
│   └── theme/app_theme.dart           # Material 3 light & dark theme setup
├── native/
│   ├── sunmi_printer_service.dart     # MethodChannel interface for SUNMI Printer
│   ├── sunmi_scanner_service.dart     # MethodChannel interface for SUNMI Scanner
│   └── device_info_service.dart       # Platform metrics (RAM, Battery, Android OS)
├── shared/
│   ├── models/                        # Domain models (Invoice, Templates, History, Settings)
│   ├── repositories/                  # Hive repositories (HistoryRepository, SettingsRepository)
│   └── widgets/                       # Reusable UI widgets (ReceiptPreviewWidget, CustomCard, SignatureCanvasWidget)
└── features/                          # 12 Hardware & Feature Modules
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.41.0` or higher
- Android SDK with Java 21 / Android Studio
- SUNMI V3 device (or standard Android / macOS / iOS simulator with virtual fallback)

### Run Application

```bash
# Get dependencies
flutter pub get

# Run static analysis
dart analyze

# Run application
flutter run
```

---

## 📄 License

This project is licensed under the MIT License.
