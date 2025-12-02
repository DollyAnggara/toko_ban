import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItem {
  final String tireId;
  final String name;
  final int qty;
  final double price;

  SaleItem(
      {required this.tireId,
      required this.name,
      required this.qty,
      required this.price});

  factory SaleItem.fromMap(Map<String, dynamic> m) => SaleItem(
        tireId: m['tireId'] ?? '',
        name: m['name'] ?? '',
        qty: (m['qty'] ?? 0) is int
            ? (m['qty'] ?? 0)
            : int.parse((m['qty'] ?? '0').toString()),
        price: (m['price'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'tireId': tireId,
        'name': name,
        'qty': qty,
        'price': price,
      };
}

class Sale {
  final String id;
  final String invoiceNo;
  final String customerName;
  final DateTime date;
  final double total;
  final List<SaleItem> items;
  final String status; // pending, diproses, selesai

  Sale(
      {required this.id,
      required this.invoiceNo,
      required this.customerName,
      required this.date,
      required this.total,
      required this.items,
      this.status = 'pending'});

  factory Sale.fromMap(String id, Map<String, dynamic> m) {
    DateTime parsedDate = DateTime.now();
    final dateField = m['date'];
    if (dateField is Timestamp) {
      parsedDate = dateField.toDate();
    } else if (dateField is String) {
      parsedDate = DateTime.tryParse(dateField) ?? DateTime.now();
    }

    return Sale(
      id: id,
      invoiceNo: m['invoiceNo'] ?? '',
      customerName: m['customerName'] ?? '',
      date: parsedDate,
      total: (m['total'] ?? 0).toDouble(),
      status: m['status'] ?? 'pending',
      items: (m['items'] as List<dynamic>?)
              ?.map((e) => SaleItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
        'invoiceNo': invoiceNo,
        'customerName': customerName,
        'date': date.toIso8601String(),
        'total': total,
        'status': status,
        'items': items.map((e) => e.toMap()).toList(),
      };
}
