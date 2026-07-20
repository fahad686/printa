import 'dart:convert';

class HistoryItemModel {
  final String id;
  final String title;
  final String category; // 'receipt', 'qr', 'barcode', 'nfc', 'scan', 'pdf'
  final DateTime timestamp;
  final String payload; // JSON or raw text string
  final String? subtitle;

  HistoryItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.timestamp,
    required this.payload,
    this.subtitle,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload,
        'subtitle': subtitle,
      };

  factory HistoryItemModel.fromJson(Map<String, dynamic> json) => HistoryItemModel(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Record',
        category: json['category'] ?? 'general',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
            : DateTime.now(),
        payload: json['payload'] ?? '',
        subtitle: json['subtitle'],
      );

  String toJsonString() => jsonEncode(toJson());

  factory HistoryItemModel.fromJsonString(String str) =>
      HistoryItemModel.fromJson(jsonDecode(str));
}
