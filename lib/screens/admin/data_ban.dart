import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/tire_model.dart';
import '../../services/database_service.dart';
import '../../widgets/nav_scaffold.dart';

class AdminDataBan extends StatefulWidget {
  final UserModel user;

  const AdminDataBan({required this.user, super.key});

  @override
  State<AdminDataBan> createState() => _AdminDataBanState();
}

class _AdminDataBanState extends State<AdminDataBan> {
  final DatabaseService _db = DatabaseService();

  Future<void> _deleteTire(String tireId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus ban ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.deleteTire(tireId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ban berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus ban: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavScaffold(
      user: widget.user,
      title: 'Data Ban',
      body: StreamBuilder<List<Tire>>(
        stream: _db.getAllTires(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tires = snapshot.data!;

          if (tires.isEmpty) {
            return const Center(
              child: Text('Belum ada data ban'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tires.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tire = tires[index];
              return Container(
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
                            tire.brand,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ukuran: ${tire.size}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stok: ${tire.stock}',
                            style: TextStyle(
                              color: tire.stock < 10
                                  ? Colors.orange
                                  : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rp ${tire.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _deleteTire(tire.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
