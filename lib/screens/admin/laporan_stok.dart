import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/tire_model.dart';
import '../../models/sale_model.dart';
import '../../services/database_service.dart';
import '../../widgets/nav_scaffold.dart';

class AdminLaporanStokScreen extends StatefulWidget {
  final UserModel user;
  const AdminLaporanStokScreen({required this.user, super.key});

  @override
  State<AdminLaporanStokScreen> createState() => _AdminLaporanStokScreenState();
}

class _AdminLaporanStokScreenState extends State<AdminLaporanStokScreen> {
  final DatabaseService _db = DatabaseService();
  String? selectedBrand;

  @override
  Widget build(BuildContext context) {
    return NavScaffold(
      user: widget.user,
      title: 'Laporan Stok',
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('Filter Merek: ',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: StreamBuilder<List<Tire>>(
                    stream: _db.getAllTires(),
                    builder: (context, snap) {
                      final tires = snap.data ?? <Tire>[];
                      final brands = tires.map((t) => t.brand).toSet().toList();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedBrand,
                            hint: const Text('Semua Merek'),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('Semua Merek')),
                              ...brands.map((b) =>
                                  DropdownMenuItem(value: b, child: Text(b)))
                            ],
                            onChanged: (v) => setState(() => selectedBrand = v),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<List<Tire>>(
                stream: _db.getAllTires(),
                builder: (context, tireSnap) {
                  if (tireSnap.hasError) {
                    return Center(child: Text('Error: ${tireSnap.error}'));
                  }
                  if (!tireSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var tires = tireSnap.data!;
                  if (selectedBrand != null && selectedBrand != '') {
                    tires =
                        tires.where((t) => t.brand == selectedBrand).toList();
                  }

                  // Now stream sales and compute sold quantities per tire
                  return StreamBuilder<List<Sale>>(
                    stream: _db.getAllSales(),
                    builder: (context, saleSnap) {
                      if (saleSnap.hasError) {
                        return Center(child: Text('Error: ${saleSnap.error}'));
                      }
                      if (!saleSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final sales = saleSnap.data!;
                      final Map<String, int> soldMap = {};
                      for (final s in sales) {
                        for (final it in s.items) {
                          if (it.tireId.isEmpty) continue;
                          soldMap[it.tireId] =
                              (soldMap[it.tireId] ?? 0) + it.qty;
                        }
                      }

                      // compute available stock per tire
                      final List<Map<String, dynamic>> rows = tires.map((t) {
                        final sold = soldMap[t.id] ?? 0;
                        // Stock sudah otomatis berkurang saat checkout, jadi langsung pakai t.stock
                        final available = t.stock;
                        return {
                          'tire': t,
                          'available': available,
                          'sold': sold,
                          'original': t.stock
                        };
                      }).toList();

                      final totalAvailable = rows.fold<int>(
                          0, (p, r) => p + (r['available'] as int));
                      final lowStock = rows
                          .where((r) => (r['available'] as int) < 10)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        const Text('Total Stok',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text('$totalAvailable',
                                            style:
                                                const TextStyle(fontSize: 16))
                                      ])),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        const Text('Merek Terdaftar',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(
                                            '${tires.map((t) => t.brand).toSet().length}',
                                            style:
                                                const TextStyle(fontSize: 16))
                                      ])),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final row = rows[idx];
                                final t = row['tire'] as Tire;
                                final available = row['available'] as int;
                                final sold = row['sold'] as int;
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                // ignore: deprecated_member_use
                                                Colors.black.withOpacity(0.03),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3))
                                      ]),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(t.brand,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 6),
                                            Text('Ukuran: ${t.size}')
                                          ]),
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text('Stok: $available',
                                                style: TextStyle(
                                                    color: available < 10
                                                        ? Colors.orange
                                                        : Colors.green,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            const SizedBox(height: 6),
                                            Text('Terjual: $sold',
                                                style: const TextStyle(
                                                    color: Colors.black54)),
                                            const SizedBox(height: 6),
                                            Text('Rp ${t.price}',
                                                style: const TextStyle(
                                                    color: Colors.blue))
                                          ]),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          if (lowStock.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('Peringatan: Stok rendah',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Column(
                                children: lowStock
                                    .map((r) => ListTile(
                                        title: Text((r['tire'] as Tire).brand),
                                        subtitle:
                                            Text('Stok: ${r['available']}')))
                                    .toList())
                          ]
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
