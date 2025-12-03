import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../models/user_model.dart';
import '../../widgets/nav_scaffold.dart';
import '../../services/database_service.dart';
import '../../models/sale_model.dart';

class SalesInputScreen extends StatefulWidget {
  final UserModel user;

  const SalesInputScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<SalesInputScreen> createState() => _SalesInputScreenState();
}

class _SalesInputScreenState extends State<SalesInputScreen> {
  final DatabaseService _db = DatabaseService();
  String _selectedStatus = 'Semua'; // Semua, Pending, Diproses, Selesai

  @override
  Widget build(BuildContext context) {
    return NavScaffold(
      user: widget.user,
      title: 'Pesanan Masuk',
      body: Column(
        children: [
          // Status filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('Filter: ',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        items: [
                          'Semua',
                          'Pending',
                          'Diproses',
                          'Selesai',
                          'Ditolak'
                        ]
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStatus = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sales list
          Expanded(
            child: StreamBuilder<List<Sale>>(
              stream: _db.getAllSales(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sales = snap.data!;

                // Filter only today's orders for incoming orders view
                final today = DateTime.now();
                var todayOrders = sales.where((s) {
                  final saleDate = s.date;
                  return saleDate.year == today.year &&
                      saleDate.month == today.month &&
                      saleDate.day == today.day;
                }).toList();

                // Apply status filter
                if (_selectedStatus != 'Semua') {
                  final filterStatus = _selectedStatus.toLowerCase();
                  todayOrders = todayOrders
                      .where((s) => s.status == filterStatus)
                      .toList();
                }

                if (todayOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                            _selectedStatus == 'Semua'
                                ? 'Belum ada pesanan hari ini'
                                : 'Belum ada pesanan ${_selectedStatus.toLowerCase()}',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_active,
                                color: const Color(0xFF1E40AF), size: 20),
                            const SizedBox(width: 8),
                            Text('${todayOrders.length} Pesanan',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: todayOrders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final sale = todayOrders[i];
                            return _buildOrderCard(context, sale);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Sale sale) {
    // Determine status badge color
    Color statusColor;
    IconData statusIcon;
    switch (sale.status) {
      case 'diproses':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'selesai':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'ditolak':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default: // pending
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showOrderDetail(context, sale);
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long,
                        color: Color(0xFF1E40AF), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sale.invoiceNo,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(sale.customerName,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 14)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rp ${sale.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E40AF))),
                      const SizedBox(height: 4),
                      Text(
                        '${sale.date.hour.toString().padLeft(2, '0')}:${sale.date.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag,
                            size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text('${sale.items.length} item',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                            sale.status[0].toUpperCase() +
                                sale.status.substring(1),
                            style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, Sale sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Detail Pesanan',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _detailRow('No. Invoice', sale.invoiceNo),
                    _detailRow('Pelanggan', sale.customerName),
                    _detailRow('Tanggal',
                        sale.date.toLocal().toString().split('.')[0]),
                    _detailRow(
                        'Status',
                        sale.status[0].toUpperCase() +
                            sale.status.substring(1)),
                    _detailRow('Metode Pembayaran',
                        sale.paymentMethod == 'qris' ? 'QRIS' : 'Tunai'),
                    if (sale.paymentMethod == 'qris' && sale.senderName != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person,
                                color: Color(0xFF1E40AF), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nama Pengirim QRIS:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    sale.senderName!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (sale.paymentMethod == 'qris' &&
                        sale.paymentProofUrl != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.receipt,
                                    color: Color(0xFF059669), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Bukti Pembayaran:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight:
                                      120, // Limit height to prevent overflow
                                ),
                                child: Image.memory(
                                  base64Decode(sale.paymentProofUrl!),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      alignment: Alignment.center,
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error, color: Colors.red),
                                          SizedBox(height: 4),
                                          Text('Gagal memuat gambar',
                                              style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppBar(
                                          title: const Text('Bukti Pembayaran'),
                                          leading: IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () => Navigator.pop(ctx),
                                          ),
                                        ),
                                        InteractiveViewer(
                                          child: Image.memory(
                                            base64Decode(sale.paymentProofUrl!),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.zoom_in, size: 18),
                              label: const Text('Lihat Detail'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF059669),
                                side:
                                    const BorderSide(color: Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    const Text('Item Pesanan',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ListView.separated(
                      controller: controller,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sale.items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final item = sale.items[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name),
                          subtitle: Text(
                              'Rp ${item.price.toStringAsFixed(0)} x ${item.qty}'),
                          trailing: Text(
                              'Rp ${(item.price * item.qty).toStringAsFixed(0)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Rp ${sale.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Status update buttons based on current status
                    if (sale.status == 'pending') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _db.updateSaleStatus(sale.id, 'diproses');
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Pesanan sedang diproses')),
                              );
                            }
                          },
                          icon: const Icon(Icons.sync, color: Colors.white),
                          label: const Text('Proses Pesanan',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Tolak Pesanan'),
                                content: const Text(
                                  'Apakah Anda yakin ingin menolak pesanan ini? Stok akan dikembalikan.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Tolak',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _db.updateSaleStatus(sale.id, 'ditolak');
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pesanan ditolak'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Tolak Pesanan',
                              style: TextStyle(fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ] else if (sale.status == 'diproses')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _db.updateSaleStatus(sale.id, 'selesai');
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Pesanan telah selesai')),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle,
                              color: Colors.white),
                          label: const Text('Selesaikan Pesanan',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      )
                    else if (sale.status == 'selesai')
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Pesanan Selesai',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                            ],
                          ),
                        ),
                      )
                    else if (sale.status == 'ditolak')
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Pesanan Ditolak',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: Color(0xFF1E40AF)),
                        ),
                        child: const Text('Tutup',
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF1E40AF))),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
