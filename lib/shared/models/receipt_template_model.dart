import 'invoice_model.dart';

enum ReceiptTemplateType {
  restaurant,
  retail,
  pharmacy,
  courier,
  parkingTicket,
  warehouse,
  simpleInvoice,
  darkTheme,
}

class ReceiptTemplateModel {
  final String id;
  final String title;
  final String category;
  final ReceiptTemplateType type;
  final String description;
  final InvoiceModel sampleInvoice;

  ReceiptTemplateModel({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.description,
    required this.sampleInvoice,
  });

  static List<ReceiptTemplateModel> get defaultTemplates => [
        ReceiptTemplateModel(
          id: 'tpl_restaurant',
          title: 'Restaurant Bill',
          category: 'Food & Beverage',
          type: ReceiptTemplateType.restaurant,
          description: 'Includes Table No, Order Type, Item breakdown & Tip section.',
          sampleInvoice: InvoiceModel(
            id: 'res_01',
            companyName: 'Gourmet Bistro & Grill',
            customerName: 'Alex Smith',
            invoiceNumber: 'REST-4029',
            date: DateTime.now(),
            tableNo: 'Table #12',
            orderType: 'Dine-In',
            currency: '\$',
            taxPercentage: 9.0,
            discountPercentage: 0.0,
            items: [
              InvoiceItem(id: '1', name: 'Ribeye Steak 300g', quantity: 2, unitPrice: 28.90),
              InvoiceItem(id: '2', name: 'Truffle Fries', quantity: 1, unitPrice: 8.50),
              InvoiceItem(id: '3', name: 'Pinot Noir Glass', quantity: 2, unitPrice: 11.00),
            ],
          ),
        ),
        ReceiptTemplateModel(
          id: 'tpl_retail',
          title: 'Retail Store',
          category: 'Shopping',
          type: ReceiptTemplateType.retail,
          description: 'Standard retail receipt with barcode & return policy footer.',
          sampleInvoice: InvoiceModel(
            id: 'ret_01',
            companyName: 'Urban Outfitters Tech',
            customerName: 'Sarah Jenkins',
            invoiceNumber: 'RET-8891',
            date: DateTime.now(),
            currency: '\$',
            taxPercentage: 10.0,
            discountPercentage: 15.0,
            items: [
              InvoiceItem(id: '1', name: 'SUNMI V3 Silicone Case', quantity: 1, unitPrice: 24.99),
              InvoiceItem(id: '2', name: 'Thermal Paper Rolls 58mm (10x)', quantity: 2, unitPrice: 14.50),
              InvoiceItem(id: '3', name: 'USB-C Fast Charger', quantity: 1, unitPrice: 19.99),
            ],
          ),
        ),
        ReceiptTemplateModel(
          id: 'tpl_pharmacy',
          title: 'Pharmacy Rx',
          category: 'Healthcare',
          type: ReceiptTemplateType.pharmacy,
          description: 'Rx invoice with Pharmacist details and prescription ID.',
          sampleInvoice: InvoiceModel(
            id: 'ph_01',
            companyName: 'CarePlus Medical Pharmacy',
            customerName: 'Michael Brown',
            invoiceNumber: 'RX-9920',
            date: DateTime.now(),
            currency: '\$',
            taxPercentage: 0.0,
            discountPercentage: 10.0,
            notes: 'Rx Ref: 449201 | Dr. Emily Roberts',
            items: [
              InvoiceItem(id: '1', name: 'Amoxicillin 500mg (30 Tabs)', quantity: 1, unitPrice: 18.50),
              InvoiceItem(id: '2', name: 'Multivitamin Complex 60s', quantity: 1, unitPrice: 22.00),
            ],
          ),
        ),
        ReceiptTemplateModel(
          id: 'tpl_courier',
          title: 'Courier & Parcel',
          category: 'Logistics',
          type: ReceiptTemplateType.courier,
          description: 'Logistics receipt with tracking QR & weight metrics.',
          sampleInvoice: InvoiceModel(
            id: 'cr_01',
            companyName: 'Express Parcel Post',
            customerName: 'David Lee',
            invoiceNumber: 'TRK-554109',
            date: DateTime.now(),
            currency: '\$',
            taxPercentage: 5.0,
            discountPercentage: 0.0,
            notes: 'Weight: 2.4 kg | Destination: NY 10001',
            items: [
              InvoiceItem(id: '1', name: 'Express Overnight Air Shipping', quantity: 1, unitPrice: 35.00),
              InvoiceItem(id: '2', name: 'Parcel Insurance (\$500 Coverage)', quantity: 1, unitPrice: 5.00),
            ],
          ),
        ),
        ReceiptTemplateModel(
          id: 'tpl_parking',
          title: 'Parking Ticket',
          category: 'Automotive',
          type: ReceiptTemplateType.parkingTicket,
          description: 'Parking validation ticket with entry/exit timestamps.',
          sampleInvoice: InvoiceModel(
            id: 'pk_01',
            companyName: 'Central Metro Parking Garage',
            customerName: 'Vehicle #ABC-8849',
            invoiceNumber: 'PKG-7721',
            date: DateTime.now(),
            currency: '\$',
            taxPercentage: 8.0,
            discountPercentage: 0.0,
            notes: 'Entry: 10:15 AM | Exit: 02:45 PM (4.5 Hrs)',
            items: [
              InvoiceItem(id: '1', name: 'Hourly Parking Rate', quantity: 4, unitPrice: 5.00),
              InvoiceItem(id: '2', name: 'EV Charging Service', quantity: 1, unitPrice: 7.50),
            ],
          ),
        ),
        ReceiptTemplateModel(
          id: 'tpl_warehouse',
          title: 'Warehouse Pick Slip',
          category: 'Inventory',
          type: ReceiptTemplateType.warehouse,
          description: 'Inventory manifest with Bin locations and SKU numbers.',
          sampleInvoice: InvoiceModel(
            id: 'wh_01',
            companyName: 'Global Logistics Hub',
            customerName: 'Picker: Station #4',
            invoiceNumber: 'PICK-3392',
            date: DateTime.now(),
            currency: '\$',
            taxPercentage: 0.0,
            discountPercentage: 0.0,
            notes: 'Zone B - Shelf 14 - Bin 02',
            items: [
              InvoiceItem(id: '1', name: 'SKU-8821: Industrial Printer Head', quantity: 3, unitPrice: 120.00),
              InvoiceItem(id: '2', name: 'SKU-1049: SUNMI Battery Pack 7.7V', quantity: 5, unitPrice: 45.00),
            ],
          ),
        ),
        ReceiptTemplateModel(
          id: 'tpl_simple',
          title: 'Simple Invoice',
          category: 'General',
          type: ReceiptTemplateType.simpleInvoice,
          description: 'Clean minimal invoice for quick cashier checkout.',
          sampleInvoice: InvoiceModel(
            id: 'sim_01',
            companyName: 'SUNMI Quick Pay',
            customerName: 'Cash Sale',
            invoiceNumber: 'QP-0012',
            date: DateTime.now(),
            currency: '\$',
            taxPercentage: 10.0,
            discountPercentage: 0.0,
            items: [
              InvoiceItem(id: '1', name: 'Service Charge', quantity: 1, unitPrice: 15.00),
            ],
          ),
        ),
        ReceiptTemplateModel(
          id: 'tpl_dark',
          title: 'Dark Theme Receipt',
          category: 'Aesthetic',
          type: ReceiptTemplateType.darkTheme,
          description: 'High contrast dark theme digital receipt view.',
          sampleInvoice: InvoiceModel(
            id: 'dk_01',
            companyName: 'Cyberpunk Tech Arcade',
            customerName: 'Gamer #007',
            invoiceNumber: 'CYBER-99',
            date: DateTime.now(),
            currency: '\$',
            taxPercentage: 10.0,
            discountPercentage: 10.0,
            items: [
              InvoiceItem(id: '1', name: 'VR Simulator Pass (1 Hr)', quantity: 2, unitPrice: 25.00),
              InvoiceItem(id: '2', name: 'Energy Drink Pack', quantity: 1, unitPrice: 8.00),
            ],
          ),
        ),
      ];
}
