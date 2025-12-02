import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widgets/nav_scaffold.dart';
import '../../widgets/animated_card.dart';
import '../../services/database_service.dart';
import '../../models/tire_model.dart';
import '../../models/sale_model.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;

  const AdminDashboard({required this.user, super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseService _db = DatabaseService();

  Widget _buildStatCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: 72, fit: BoxFit.contain),
        const SizedBox(height: 10),
        const Text('TOKO BAN MOBIL',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Management Stok Ban Profesional',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );

    return NavScaffold(
      user: widget.user,
      headerWidget: headerWidget,
      body: StreamBuilder<List<Tire>>(
        stream: _db.getAllTires(),
        builder: (context, tireSnapshot) {
          if (tireSnapshot.hasError) {
            return Center(child: Text('Error: ${tireSnapshot.error}'));
          }
          if (!tireSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tires = tireSnapshot.data!;
          final totalStock =
              tires.fold<int>(0, (sum, tire) => sum + tire.stock);

          return StreamBuilder<List<Sale>>(
            stream: _db.getAllSales(),
            builder: (context, saleSnapshot) {
              if (saleSnapshot.hasError) {
                return Center(child: Text('Error: ${saleSnapshot.error}'));
              }
              if (!saleSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final sales = saleSnapshot.data!;
              final totalSales = sales.length;
              final totalRevenue =
                  sales.fold<double>(0, (sum, sale) => sum + sale.total);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        AnimatedCard(
                          delay: 0,
                          child: _buildStatCard(
                            title: 'Total Stok Ban',
                            value: '$totalStock',
                            icon: Icons.inventory_2_outlined,
                            color: Colors.blue,
                          ),
                        ),
                        AnimatedCard(
                          delay: 100,
                          child: _buildStatCard(
                            title: 'Jenis Ban',
                            value: '${tires.length}',
                            icon: Icons.category_outlined,
                            color: Colors.green,
                          ),
                        ),
                        AnimatedCard(
                          delay: 200,
                          child: _buildStatCard(
                            title: 'Total Penjualan',
                            value: '$totalSales',
                            icon: Icons.shopping_cart_outlined,
                            color: Colors.orange,
                          ),
                        ),
                        AnimatedCard(
                          delay: 300,
                          child: _buildStatCard(
                            title: 'Total Pendapatan',
                            value:
                                'Rp ${(totalRevenue / 1000).toStringAsFixed(0)}K',
                            icon: Icons.attach_money,
                            color: Colors.purple,
                          ),
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
