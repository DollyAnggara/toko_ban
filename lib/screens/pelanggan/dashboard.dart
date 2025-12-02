import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widgets/nav_scaffold.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/pressable_card.dart';
import 'beli_ban.dart';
import 'riwayat_pembelian.dart';
import 'profile.dart';

class CustomerDashboardScreen extends StatelessWidget {
  final UserModel user;
  const CustomerDashboardScreen({required this.user, Key? key})
      : super(key: key);

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return PressableCard(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1E40AF);

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

    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Halo, ${user.name}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Selamat datang. Pilih menu di bawah untuk melanjutkan.'),
          const SizedBox(height: 20),

          // Main action cards (only 2 cards: Pembelian & Riwayat)
          LayoutBuilder(builder: (context, constraints) {
            final spacing = 14.0;
            final crossAxisCount = constraints.maxWidth > 600 ? 2 : 2;
            final itemWidth =
                (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                    crossAxisCount;
            const itemHeight = 160.0;
            final childAspectRatio = itemWidth / itemHeight;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
              children: [
                AnimatedCard(
                  delay: 0,
                  child: _buildInfoCard(
                      title: 'Pembelian',
                      subtitle: 'Lihat katalog produk ban',
                      icon: Icons.shopping_cart,
                      color: primary,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => BeliBanScreen(user: user)))),
                ),
                AnimatedCard(
                  delay: 100,
                  child: _buildInfoCard(
                      title: 'Riwayat Pembelian',
                      subtitle: 'Lihat transaksi Anda',
                      icon: Icons.receipt_long,
                      color: Colors.green,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => RiwayatPembelianScreen(user: user)))),
                ),
              ],
            );
          }),
        ],
      ),
    );

    return NavScaffold(user: user, body: content, headerWidget: headerWidget);
  }
}
