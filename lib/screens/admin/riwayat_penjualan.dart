import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/sale_model.dart';
import '../../services/database_service.dart';
import '../../widgets/nav_scaffold.dart';

class AdminRiwayatPenjualan extends StatefulWidget {
  final UserModel user;

  const AdminRiwayatPenjualan({required this.user, super.key});

  @override
  State<AdminRiwayatPenjualan> createState() => _AdminRiwayatPenjualanState();
}

class _AdminRiwayatPenjualanState extends State<AdminRiwayatPenjualan> {
  final DatabaseService _db = DatabaseService();

  void _showDetailDialog(Sale sale) {
    final dateStr =
        '${sale.date.day}/${sale.date.month}/${sale.date.year} ${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Detail Penjualan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pelanggan: ${sale.customerName}'),
              const SizedBox(height: 8),
              Text('Tanggal: $dateStr'),
              const SizedBox(height: 8),
              Text('Status: ${sale.status}'),
              const SizedBox(height: 8),
              Text(
                  'Metode Pembayaran: ${sale.paymentMethod == 'qris' ? 'QRIS' : 'Tunai'}'),
              if (sale.paymentMethod == 'qris' && sale.senderName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person,
                          color: Color(0xFF1E40AF), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pengirim: ${sale.senderName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text('Item:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...sale.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${item.name} (${item.qty}x)'),
                  )),
              const Divider(height: 24),
              Text(
                'Total: Rp ${sale.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavScaffold(
      user: widget.user,
      title: 'Riwayat Penjualan',
      body: StreamBuilder<List<Sale>>(
        stream: _db.getAllSales(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sales = snapshot.data!;
          sales.sort((a, b) => b.date.compareTo(a.date));

          if (sales.isEmpty) {
            return const Center(
              child: Text('Belum ada riwayat penjualan'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sale = sales[index];
              final status = sale.status;
              final dateStr =
                  '${sale.date.day}/${sale.date.month}/${sale.date.year} ${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}';
              Color statusColor;
              switch (status) {
                case 'selesai':
                  statusColor = Colors.green;
                  break;
                case 'diproses':
                  statusColor = Colors.blue;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return InkWell(
                onTap: () => _showDetailDialog(sale),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale.customerName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                // ignore: deprecated_member_use
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rp ${sale.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${sale.items.length} item',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
