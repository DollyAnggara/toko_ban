import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/sale_model.dart';
import '../../models/tire_model.dart';
import '../../services/database_service.dart';
import '../../widgets/nav_scaffold.dart';

class SalesHistoryScreen extends StatefulWidget {
  final UserModel user;
  const SalesHistoryScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final DatabaseService _db = DatabaseService();
  // Filters removed per request; show full history

  @override
  Widget build(BuildContext context) {
    // Filters removed; we will show the full history list

    final body = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Text('Riwayat Penjualan Terakhir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<Sale>>(
              stream: _db.getAllSales(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data!;
                if (all.isEmpty) {
                  return Center(
                      child: Text('Tidak ada transaksi untuk ditampilkan'));
                }

                return ListView.separated(
                  itemCount: all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final s = all[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue.shade50,
                                child: const Icon(Icons.receipt_long,
                                    color: Color(0xFF1E40AF)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.invoiceNo,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(
                                        '${s.customerName} • ${s.date.toLocal().toString().split(' ')[0]}',
                                        style: const TextStyle(
                                            color: Colors.black54)),
                                  ],
                                ),
                              ),
                              Text('Rp ${s.total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (s.items.isNotEmpty) ...[
                            const Divider(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: s.items
                                  .map((it) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                                child: Text(
                                                    '${it.name} x${it.qty}')),
                                            Text(
                                                'Rp ${(it.price * it.qty).toStringAsFixed(0)}')
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            )
                          ]
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    return NavScaffold(
        user: widget.user, title: 'Riwayat Penjualan', body: body);
  }
}
