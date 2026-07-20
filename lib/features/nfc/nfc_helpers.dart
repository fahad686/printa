import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../shared/models/history_item_model.dart';
import '../../shared/repositories/history_repository.dart';

class NfcTagData {
  final String uid;
  final String tech;
  final String payload;
  final String writable;
  final String capacity;

  const NfcTagData({
    required this.uid,
    required this.tech,
    required this.payload,
    required this.writable,
    required this.capacity,
  });
}

/// Holds the last successfully read tag so Update screen can preload payload.
final nfcLastReadProvider = StateProvider<NfcTagData?>((ref) => null);

class NfcHelpers {
  static Future<bool> checkAvailability() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('[NFC] isAvailable error: $e');
      return false;
    }
  }

  static String extractUid(NfcTag tag) {
    const techKeys = [
      'nfca', 'nfcb', 'nfcf', 'nfcv',
      'isodep', 'mifareclassic', 'mifareultralight', 'ndef',
    ];
    for (final key in techKeys) {
      final tech = tag.data[key];
      if (tech is Map && tech['identifier'] != null) {
        final id = List<int>.from(tech['identifier'] as List);
        return id
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(':');
      }
    }
    return 'Unknown';
  }

  static String extractTechList(NfcTag tag) {
    final names = {
      'nfca': 'NFC-A (ISO 14443-3A)',
      'nfcb': 'NFC-B (ISO 14443-3B)',
      'nfcf': 'NFC-F (FeliCa)',
      'nfcv': 'NFC-V (ISO 15693)',
      'isodep': 'IsoDep',
      'mifareclassic': 'MIFARE Classic',
      'mifareultralight': 'MIFARE Ultralight',
      'ndef': 'NDEF',
      'ndefformatable': 'NDEF Formatable',
    };
    final found = tag.data.keys.where(names.containsKey).map((k) => names[k]!).toList();
    return found.isEmpty ? 'Unknown' : found.join(', ');
  }

  static String decodeRecord(NdefRecord record) {
    try {
      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
          record.type.isNotEmpty) {
        if (record.type.first == 0x54) {
          final langLen = record.payload.first & 0x3F;
          return utf8.decode(record.payload.sublist(1 + langLen));
        }
        if (record.type.first == 0x55) {
          const prefixes = [
            '', 'http://www.', 'https://www.', 'http://', 'https://',
            'tel:', 'mailto:',
          ];
          final code = record.payload.first;
          final rest = utf8.decode(record.payload.sublist(1));
          return (code < prefixes.length ? prefixes[code] : '') + rest;
        }
      }
      if (record.payload.isEmpty) return '';
      return utf8.decode(record.payload, allowMalformed: true);
    } catch (e) {
      return 'Undecodable payload (${record.payload.length} bytes)';
    }
  }

  static String decodeMessage(NdefMessage? message) {
    if (message == null || message.records.isEmpty) return '';
    return message.records.map(decodeRecord).where((s) => s.isNotEmpty).join('\n');
  }

  static NfcTagData captureTagData(NfcTag tag) {
    final ndef = Ndef.from(tag);
    final payload = decodeMessage(ndef?.cachedMessage);
    return NfcTagData(
      uid: extractUid(tag),
      tech: extractTechList(tag),
      payload: payload.isEmpty ? '(empty - no NDEF payload)' : payload,
      writable: ndef == null
          ? 'No NDEF support'
          : (ndef.isWritable ? 'Yes' : 'No (read-only)'),
      capacity: ndef != null ? '${ndef.maxSize} bytes' : 'N/A',
    );
  }

  static NdefMessage buildMessage({required String text, required String payloadType}) {
    if (payloadType == 'URL') {
      return NdefMessage([NdefRecord.createUri(Uri.parse(text))]);
    }
    return NdefMessage([NdefRecord.createText(text)]);
  }

  static Future<void> saveHistory(
    WidgetRef ref, {
    required String title,
    required String payload,
    String? subtitle,
  }) {
    return ref.read(historyRepositoryProvider).addHistoryItem(
          HistoryItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            category: 'nfc',
            timestamp: DateTime.now(),
            payload: payload,
            subtitle: subtitle,
          ),
        );
  }

  static Future<void> runSession({
    required Future<void> Function(NfcTag tag) onTag,
    required void Function(String status) onStatus,
    required void Function(bool scanning) onScanning,
  }) async {
    final available = await checkAvailability();
    if (!available) {
      onStatus('NFC unavailable. Enable NFC in Android Settings.');
      return;
    }

    onScanning(true);
    onStatus('Hold device near NFC tag...');

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            await onTag(tag);
          } catch (e) {
            onStatus('Error: $e');
          } finally {
            await NfcManager.instance.stopSession().catchError((_) {});
            onScanning(false);
          }
        },
        onError: (error) async {
          onScanning(false);
          onStatus('Session error: ${error.message}');
        },
      );
    } catch (e) {
      onScanning(false);
      onStatus('Could not start NFC session: $e');
    }
  }

  static void stopSession() {
    NfcManager.instance.stopSession().catchError((_) {});
  }

  static NdefMessage emptyMessage() => NdefMessage([
        NdefRecord(
          typeNameFormat: NdefTypeNameFormat.empty,
          type: Uint8List(0),
          identifier: Uint8List(0),
          payload: Uint8List(0),
        ),
      ]);
}
