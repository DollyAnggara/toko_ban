import 'package:flutter/material.dart';
import '../models/user_model.dart';

typedef ItemTapCallback = void Function(int index);

class NavPanel extends StatefulWidget {
  final UserModel user;
  final ItemTapCallback onItemTap;
  final VoidCallback? onLogout;

  const NavPanel(
      {required this.user, required this.onItemTap, this.onLogout, super.key});

  @override
  State<NavPanel> createState() => _NavPanelState();
}

class _NavPanelState extends State<NavPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _itemAnimations;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Header animation
    _headerAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    // Create staggered animations for menu items
    _itemAnimations = List.generate(
      10,
      (index) => CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.1 + (index * 0.05),
          0.4 + (index * 0.05),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _navItem(BuildContext context, IconData icon, String title, int index,
      int animIndex) {
    return FadeTransition(
      opacity: _itemAnimations[animIndex],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.3, 0),
          end: Offset.zero,
        ).animate(_itemAnimations[animIndex]),
        child: ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Icon(icon, color: const Color(0xFF1F2937), size: 26),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
          ),
          onTap: () => widget.onItemTap(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBar = MediaQuery.of(context).padding.top;
    // Soft neutral background and spacious layout to match design
    final roleNorm = widget.user.role.trim().toLowerCase();
    final isKaryawanOrAdmin =
        roleNorm.contains('karyawan') || roleNorm.contains('admin');
    final isAdmin = roleNorm.contains('admin');
    final isPelanggan = roleNorm.contains('pelanggan');

    int animIndex = 0;

    return Container(
      color: const Color(0xFFF9F9F9),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FadeTransition(
            opacity: _headerAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.5, 0),
                end: Offset.zero,
              ).animate(_headerAnimation),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, statusBar + 12, 16, 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF1E40AF),
                      child: Text(
                        widget.user.name.isNotEmpty
                            ? widget.user.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.user.email,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey[300]),
          const SizedBox(height: 6),
          _navItem(
              context, Icons.dashboard_outlined, 'Dashboard', 0, animIndex++),
          if (isPelanggan) ...[
            _navItem(context, Icons.shopping_cart, 'Pembelian', 1, animIndex++),
            _navItem(context, Icons.receipt_long, 'Riwayat Pembelian', 2,
                animIndex++),
          ],
          if (isKaryawanOrAdmin && !isAdmin) ...[
            _navItem(context, Icons.tire_repair, 'Data Ban', 1, animIndex++),
            _navItem(context, Icons.add_circle_outline, 'Tambah Ban', 2,
                animIndex++),
            _navItem(context, Icons.point_of_sale_outlined, 'Penjualan', 3,
                animIndex++),
            _navItem(context, Icons.receipt_long_outlined, 'Riwayat Penjualan',
                4, animIndex++),
            _navItem(
                context, Icons.bar_chart_outlined, 'Laporan', 5, animIndex++),
          ],
          if (isAdmin) ...[
            _navItem(context, Icons.tire_repair, 'Data Ban', 8, animIndex++),
            _navItem(context, Icons.add_circle_outline, 'Tambah Ban', 9,
                animIndex++),
            _navItem(
                context, Icons.history, 'Riwayat Penjualan', 10, animIndex++),
            _navItem(context, Icons.person, 'Pelanggan', 7, animIndex++),
            _navItem(context, Icons.group, 'Karyawan', 6, animIndex++),
            _navItem(context, Icons.admin_panel_settings, 'Tambah Admin', 13,
                animIndex++),
            _navItem(
                context, Icons.bar_chart_outlined, 'Laporan', 15, animIndex++),
          ],
          const SizedBox(height: 6),
          Divider(height: 1, thickness: 1, color: Colors.grey[300]),
          const SizedBox(height: 6),
          _navItem(context, Icons.person_outlined, 'Profile', 14, animIndex++),
          FadeTransition(
            opacity: _itemAnimations[animIndex < 10 ? animIndex : 9],
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.3, 0),
                end: Offset.zero,
              ).animate(_itemAnimations[animIndex < 10 ? animIndex : 9]),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                leading: Icon(Icons.logout,
                    color: Theme.of(context).colorScheme.error, size: 26),
                title: Text(
                  'Logout',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 16),
                ),
                onTap: widget.onLogout,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
