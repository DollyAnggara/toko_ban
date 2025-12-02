import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widgets/nav_scaffold.dart';
import 'laporan_penjualan.dart';
import 'laporan_stok.dart';

class AdminLaporanScreen extends StatelessWidget {
  final UserModel user;
  const AdminLaporanScreen({required this.user, super.key});

  Widget _reportCard(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: const Color(0xFF1E40AF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Laporan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _reportCard(context, Icons.bar_chart, 'Laporan Penjualan',
              'Ringkasan penjualan harian, mingguan, bulanan', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminLaporanPenjualanScreen(user: user)));
          }),
          const SizedBox(height: 12),
          _reportCard(context, Icons.inventory, 'Laporan Stok',
              'Lihat perubahan stok dan peringatan minimum', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminLaporanStokScreen(user: user)));
          }),
        ],
      ),
    );
    return NavScaffold(user: user, body: content, title: 'Laporan');
  }
}
