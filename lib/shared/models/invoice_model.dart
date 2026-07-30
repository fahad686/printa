import 'dart:convert';

class InvoiceItem {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;

  InvoiceItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qty': quantity,
        'price': unitPrice,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        quantity: (json['qty'] as num?)?.toInt() ?? 1,
        unitPrice: (json['price'] as num?)?.toDouble() ?? 0.0,
      );

  InvoiceItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? unitPrice,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class InvoiceModel {
  final String id;
  final String companyName;
  final String? logoUrl;
  final String customerName;
  final String invoiceNumber;
  final DateTime date;
  final String currency;
  final double taxPercentage;
  final double discountPercentage;
  final List<InvoiceItem> items;
  final String? notes;
  final String? tableNo;
  final String? orderType;

  InvoiceModel({
    required this.id,
    required this.companyName,
    this.logoUrl,
    required this.customerName,
    required this.invoiceNumber,
    required this.date,
    this.currency = 'USD',
    this.taxPercentage = 10.0,
    this.discountPercentage = 0.0,
    required this.items,
    this.notes,
    this.tableNo,
    this.orderType,
  });

  double get rawSubtotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get discountAmount => rawSubtotal * (discountPercentage / 100.0);

  double get subtotalAfterDiscount => rawSubtotal - discountAmount;

  double get taxAmount => subtotalAfterDiscount * (taxPercentage / 100.0);

  double get grandTotal => subtotalAfterDiscount + taxAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'company': companyName,
        'logo': logoUrl,
        'customer': customerName,
        'inv_num': invoiceNumber,
        'date': date.toIso8601String(),
        'currency': currency,
        'tax_pct': taxPercentage,
        'disc_pct': discountPercentage,
        'items': items.map((i) => i.toJson()).toList(),
        'notes': notes,
        'table_no': tableNo,
        'order_type': orderType,
        'total': grandTotal,
      };

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
        id: json['id'] ?? '',
        companyName: json['company'] ?? 'Printa Store',
        logoUrl: json['logo'],
        customerName: json['customer'] ?? 'Walk-in Customer',
        invoiceNumber: json['inv_num'] ?? 'INV-1001',
        date: json['date'] != null
            ? DateTime.tryParse(json['date']) ?? DateTime.now()
            : DateTime.now(),
        currency: json['currency'] ?? 'USD',
        taxPercentage: (json['tax_pct'] as num?)?.toDouble() ?? 10.0,
        discountPercentage: (json['disc_pct'] as num?)?.toDouble() ?? 0.0,
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => InvoiceItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        notes: json['notes'],
        tableNo: json['table_no'],
        orderType: json['order_type'],
      );

  String toCompactJsonString() => jsonEncode(toJson());

  static InvoiceModel fromCompactJsonString(String jsonStr) =>
      InvoiceModel.fromJson(jsonDecode(jsonStr));

  static const Object _unset = Object();

  InvoiceModel copyWith({
    String? id,
    String? companyName,
    Object? logoUrl = _unset,
    String? customerName,
    String? invoiceNumber,
    DateTime? date,
    String? currency,
    double? taxPercentage,
    double? discountPercentage,
    List<InvoiceItem>? items,
    Object? notes = _unset,
    Object? tableNo = _unset,
    Object? orderType = _unset,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      logoUrl: identical(logoUrl, _unset) ? this.logoUrl : logoUrl as String?,
      customerName: customerName ?? this.customerName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      items: items ?? List.from(this.items),
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      tableNo: identical(tableNo, _unset) ? this.tableNo : tableNo as String?,
      orderType: identical(orderType, _unset) ? this.orderType : orderType as String?,
    );
  }

  static InvoiceModel createSample() {
    return InvoiceModel(
      id: 'sample_01',
      companyName: 'Printa Bistro & Cafe',
      customerName: 'John Doe',
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      date: DateTime.now(),
      currency: '\$',
      taxPercentage: 8.5,
      discountPercentage: 5.0,
      tableNo: 'T-04',
      orderType: 'Dine-In',
      items: [
        InvoiceItem(id: '1', name: 'Espresso Double', quantity: 2, unitPrice: 4.50),
        InvoiceItem(id: '2', name: 'Avocado Toast', quantity: 1, unitPrice: 12.00),
        InvoiceItem(id: '3', name: 'Matcha Latte', quantity: 1, unitPrice: 6.50),
      ],
    );
  }
}
