import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../native/sunmi_printer_service.dart';
import '../../shared/models/history_item_model.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/repositories/history_repository.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All Records'},
    {'id': 'receipt', 'label': 'Receipts'},
    {'id': 'qr', 'label': 'QRs'},
    {'id': 'barcode', 'label': 'Barcodes'},
    {'id': 'nfc', 'label': 'NFC Logs'},
    {'id': 'scan', 'label': 'Scans'},
    {'id': 'pdf', 'label': 'PDFs'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reprintItem(HistoryItemModel item) async {
    final printer = ref.read(sunmiPrinterServiceProvider);
    if (item.category == 'receipt' || item.category == 'pdf') {
      try {
        final invoice = InvoiceModel.fromCompactJsonString(item.payload);
        await printer.printReceipt(invoice);
      } catch (_) {
        await printer.printText(text: item.payload, align: 1);
      }
    } else if (item.category == 'qr') {
      await printer.printQRCode(data: item.payload);
    } else if (item.category == 'barcode') {
      await printer.printBarCode(data: item.payload);
    } else {
      await printer.printText(text: item.payload, align: 1);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reprinted ${item.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyRepo = ref.watch(historyRepositoryProvider);

    List<HistoryItemModel> items;
    if (_searchQuery.isNotEmpty) {
      items = historyRepo.searchHistory(_searchQuery);
    } else if (_selectedCategory != 'all') {
      items = historyRepo.getByCategory(_selectedCategory);
    } else {
      items = historyRepo.getAllHistory();
    }

    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module 11 – History Box'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear All',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear History?'),
                  content: const Text('This will delete all Hive history records.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await historyRepo.clearAll();
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search history records...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, idx) {
                      final cat = _categories[idx];
                      final isSelected = _selectedCategory == cat['id'];

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat['id']!;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items List
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No history records found in Hive',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      IconData icon;
                      switch (item.category) {
                        case 'receipt':
                          icon = Icons.receipt_long_rounded;
                          break;
                        case 'qr':
                          icon = Icons.qr_code_2_rounded;
                          break;
                        case 'barcode':
                          icon = Icons.qr_code_scanner_rounded;
                          break;
                        case 'nfc':
                          icon = Icons.nfc_rounded;
                          break;
                        case 'scan':
                          icon = Icons.center_focus_strong_rounded;
                          break;
                        case 'pdf':
                          icon = Icons.picture_as_pdf_rounded;
                          break;
                        default:
                          icon = Icons.history_rounded;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                            child: Icon(icon, color: Theme.of(context).primaryColor),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.subtitle != null)
                                Text(item.subtitle!, style: const TextStyle(fontSize: 12)),
                              Text(
                                dateFormat.format(item.timestamp),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.print_rounded, size: 20),
                                tooltip: 'Reprint',
                                onPressed: () => _reprintItem(item),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'copy') {
                                    Clipboard.setData(ClipboardData(text: item.payload));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Copied payload!')),
                                    );
                                  } else if (val == 'share') {
                                    Share.share(item.payload);
                                  } else if (val == 'delete') {
                                    await historyRepo.deleteHistoryItem(item.id);
                                    setState(() {});
                                  }
                                },
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(value: 'copy', child: Text('Copy Payload')),
                                  PopupMenuItem(value: 'share', child: Text('Share')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
