import 'dart:convert';

import 'package:barcode/barcode.dart';

import '../models/invoice_model.dart';

class ValidationResult {
  final bool isValid;
  final String message;

  const ValidationResult({required this.isValid, required this.message});

  static const valid = ValidationResult(isValid: true, message: 'Valid payload');
}

class PayloadValidator {
  static ValidationResult validateQrPayload(String type, String data) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) {
      return const ValidationResult(isValid: false, message: 'Payload cannot be empty');
    }

    switch (type) {
      case 'URL':
        final uri = Uri.tryParse(trimmed);
        if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
          return const ValidationResult(
            isValid: false,
            message: 'Enter a valid URL (e.g. https://printa.app)',
          );
        }
        return ValidationResult.valid;

      case 'Invoice JSON':
        return validateInvoiceJson(trimmed);

      case 'WiFi':
        if (!trimmed.startsWith('WIFI:')) {
          return const ValidationResult(
            isValid: false,
            message: 'WiFi payload must start with WIFI:',
          );
        }
        return ValidationResult.valid;

      case 'Phone Number':
        if (!trimmed.startsWith('tel:')) {
          return const ValidationResult(
            isValid: false,
            message: 'Phone payload must start with tel:',
          );
        }
        return ValidationResult.valid;

      case 'Email':
        if (!trimmed.startsWith('mailto:')) {
          return const ValidationResult(
            isValid: false,
            message: 'Email payload must start with mailto:',
          );
        }
        return ValidationResult.valid;

      case 'vCard':
        if (!trimmed.contains('BEGIN:VCARD') || !trimmed.contains('END:VCARD')) {
          return const ValidationResult(
            isValid: false,
            message: 'vCard must include BEGIN:VCARD and END:VCARD',
          );
        }
        return ValidationResult.valid;

      case 'UPI / Payment':
        if (!trimmed.startsWith('upi://')) {
          return const ValidationResult(
            isValid: false,
            message: 'UPI payload must start with upi://',
          );
        }
        return ValidationResult.valid;

      default:
        return ValidationResult.valid;
    }
  }

  static ValidationResult validateInvoiceJson(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final hasInvoiceId =
          map.containsKey('inv_num') || map.containsKey('inv') || map.containsKey('id');
      final hasTotal = map.containsKey('total') || map.containsKey('grandTotal');

      if (!hasInvoiceId) {
        return const ValidationResult(
          isValid: false,
          message: 'Invoice JSON needs inv_num, inv, or id field',
        );
      }
      if (!hasTotal) {
        return const ValidationResult(
          isValid: false,
          message: 'Invoice JSON needs total or grandTotal field',
        );
      }

      // Full model parse confirms structure matches app invoice schema
      InvoiceModel.fromJson(map);
      return ValidationResult.valid;
    } on FormatException {
      return const ValidationResult(isValid: false, message: 'Invalid JSON syntax');
    } catch (e) {
      return ValidationResult(isValid: false, message: 'Invalid invoice structure: $e');
    }
  }

  static ValidationResult validateBarcode(String symbology, String data, Barcode barcode) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) {
      return const ValidationResult(isValid: false, message: 'Barcode data cannot be empty');
    }

    try {
      if (!barcode.isValid(trimmed)) {
        return ValidationResult(
          isValid: false,
          message: 'Invalid $symbology data for this format',
        );
      }
      return ValidationResult.valid;
    } catch (e) {
      return ValidationResult(isValid: false, message: 'Validation error: $e');
    }
  }

  static ValidationResult validateTemplateQrData(String jsonStr) {
    return validateInvoiceJson(jsonStr);
  }
}
