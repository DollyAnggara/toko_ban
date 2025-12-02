import 'package:flutter/material.dart';
import '../../models/tire_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../widgets/nav_scaffold.dart';
import 'edit_ban.dart';

class TireListScreen extends StatefulWidget {
  final UserModel user;

  const TireListScreen({required this.user, Key? key}) : super(key: key);

  @override
  _TireListScreenState createState() => _TireListScreenState();
}

// Backwards-compatible wrapper so callers using `DataBanScreen` still work.
class DataBanScreen extends StatelessWidget {
  final UserModel user;
  const DataBanScreen({required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TireListScreen(user: user);
  }
}

class _TireListScreenState extends State<TireListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Header search placed in the blue header via NavScaffold.headerWidget
    final headerWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Cari ban, merek, atau ukuran',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final content = Column(
      children: [
        Expanded(
          child: Container(
            margin:
                const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.transparent, // removed white background per request
              borderRadius: BorderRadius.circular(16),
            ),
            child: StreamBuilder<List<Tire>>(
              stream: _databaseService.getAllTires(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Tire> tires = snapshot.data ?? [];

                // Apply search filter from the header
                final q = searchQuery.toLowerCase();
                if (q.isNotEmpty) {
                  tires = tires.where((tire) {
                    final matchesBrand = tire.brand.toLowerCase().contains(q);
                    final matchesSize =
                        tire.size.toString().toLowerCase().contains(q);
                    final matchesPrice =
                        tire.price.toString().toLowerCase().contains(q);
                    return matchesBrand || matchesSize || matchesPrice;
                  }).toList();
                }

                if (tires.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada data ban'),
                  );
                }

                return ListView.builder(
                  itemCount: tires.length,
                  itemBuilder: (context, index) {
                    Tire tire = tires[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: const Color(0xFFFFFFFF),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tire.brand,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Ukuran: ${tire.size}"),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Rp ${tire.price}",
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      _iconBox(
                                        icon: Icons.edit,
                                        color: Colors.blue,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditTireScreen(tire: tire),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      _iconBox(
                                        icon: Icons.delete,
                                        color: Colors.red,
                                        onTap: () =>
                                            _showDeleteDialog(context, tire),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Stok: ${tire.stock}",
                                    style: TextStyle(
                                      color: tire.stock < 10
                                          ? Colors.orange
                                          : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );

    return NavScaffold(
        user: widget.user,
        body: content,
        title: 'Data Ban',
        headerWidget: headerWidget);
  }

  Widget _iconBox({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Tire tire) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Ban'),
          content: Text('Apakah Anda yakin ingin menghapus ${tire.brand}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.deleteTire(tire.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ban berhasil dihapus')),
                );
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
