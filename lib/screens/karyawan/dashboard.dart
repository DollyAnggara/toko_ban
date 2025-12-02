import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/tire_model.dart';
import '../../widgets/nav_panel.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/pressable_card.dart';
import '../login_screen.dart';
import 'data_ban.dart';
import 'tambah_ban.dart';
import 'penjualan.dart';
import 'edit_ban.dart';
import 'laporan.dart';
import 'riwayat_penjualan.dart';
import 'profile.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  const DashboardScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _navigationController;
  late Animation<double> _navigationAnimation;
  late Animation<Offset> _navigationOffset;
  bool _isNavigationVisible = false;

  @override
  void initState() {
    super.initState();
    _navigationController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _navigationAnimation = CurvedAnimation(
      parent: _navigationController,
      curve: Curves.easeOutCubic,
    );
    _navigationOffset =
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(_navigationAnimation);
  }

  @override
  void dispose() {
    _navigationController.dispose();
    super.dispose();
  }

  void _toggleNavigation() {
    setState(() {
      _isNavigationVisible = !_isNavigationVisible;
      if (_isNavigationVisible) {
        _navigationController.forward();
      } else {
        _navigationController.reverse();
      }
    });
  }

  // Navigation items are rendered by the reusable NavPanel widget.

  Widget _buildMainContent(Color primary) {
    // Build header full-width so its blue background reaches the status bar and screen edges.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-bleed header
        Builder(builder: (ctx) {
          final statusBar = MediaQuery.of(ctx).padding.top;
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.only(
                top: statusBar + 14, bottom: 18, left: 16, right: 16),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: _toggleNavigation,
                    tooltip: 'Menu',
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.png',
                          height: 72, fit: BoxFit.contain),
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
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        // The rest of the page content uses an inner padding so it doesn't touch screen edges
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selamat Datang!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Kelola stok ban mobil Anda dengan mudah dan efisien',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),

              // Action grid (responsive)
              LayoutBuilder(builder: (context, constraints) {
                final spacing = 14.0;
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                final itemWidth =
                    (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                        crossAxisCount;
                const itemHeight = 170.0;
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
                          title: 'Data Ban',
                          subtitle: 'Lihat Semua Stok',
                          icon: Icons.tire_repair,
                          color: primary,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DataBanScreen(user: widget.user))),
                          cardColor: Colors.white),
                    ),
                    AnimatedCard(
                      delay: 100,
                      child: _buildInfoCard(
                          title: 'Tambah',
                          subtitle: 'Tambah Ban Baru',
                          icon: Icons.add_circle_outline,
                          color: primary,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AddTireScreen(user: widget.user))),
                          cardColor: Colors.white),
                    ),
                    AnimatedCard(
                      delay: 200,
                      child: _buildInfoCard(
                          title: 'Edit Data',
                          subtitle: 'Update Informasi',
                          icon: Icons.edit_outlined,
                          color: primary,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      TireListScreen(user: widget.user))),
                          cardColor: Colors.white),
                    ),
                    AnimatedCard(
                      delay: 300,
                      child: _buildInfoCard(
                          title: 'Penjualan',
                          subtitle: 'Catat penjualan',
                          icon: Icons.point_of_sale_outlined,
                          color: primary,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      SalesInputScreen(user: widget.user))),
                          cardColor: Colors.white),
                    ),
                    AnimatedCard(
                      delay: 400,
                      child: _buildInfoCard(
                          title: 'Riwayat Penjualan',
                          subtitle: 'Lihat riwayat',
                          icon: Icons.receipt_long,
                          color: primary,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      SalesHistoryScreen(user: widget.user))),
                          cardColor: Colors.white),
                    ),
                    AnimatedCard(
                      delay: 500,
                      child: _buildInfoCard(
                          title: 'Laporan',
                          subtitle: 'Statistik stok',
                          icon: Icons.bar_chart,
                          color: primary,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ReportsScreen(user: widget.user))),
                          cardColor: Colors.white),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 16),

              // Statistik Cepat card (dynamic from database)
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Statistik Cepat',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      StreamBuilder<List<Tire>>(
                        stream: DatabaseService().getAllTires(),
                        builder: (context, snapshot) {
                          final tires = snapshot.data ?? <Tire>[];
                          final jenis =
                              tires.map((e) => e.brand).toSet().length;
                          final totalStock =
                              tires.fold<int>(0, (s, e) => s + e.stock);

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Jenis Ban:',
                                      style: TextStyle(fontSize: 14)),
                                  const SizedBox(height: 6),
                                  Text(jenis.toString(),
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: primary)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Stok Tersedia:',
                                      style: TextStyle(fontSize: 14)),
                                  const SizedBox(height: 6),
                                  Text(totalStock.toString(),
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: primary)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color cardColor = Colors.white,
  }) {
    return PressableCard(
      onTap: onTap,
      child: Card(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1E40AF);
    return Scaffold(
      body: Stack(
        children: [
          // Main content (full-screen)
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                // Swipe left
                if (_isNavigationVisible) _toggleNavigation();
              } else if (details.primaryVelocity! > 0) {
                // Swipe right
                if (!_isNavigationVisible) _toggleNavigation();
              }
            },
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewPadding.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainContent(primary),
                  ],
                ),
              ),
            ),
          ),

          // Dimmed backdrop when navigation is visible
          if (_isNavigationVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleNavigation,
                child: Container(
                  color: Colors.black38,
                ),
              ),
            ),

          // Navigation panel (SlideTransition for GPU-friendly animation)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: SlideTransition(
              position: _navigationOffset,
              child: SizedBox(
                width: 280,
                child: Material(
                  elevation: 8,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(16),
                    ),
                  ),
                  child: RepaintBoundary(
                    child: NavPanel(
                      user: widget.user,
                      onItemTap: (index) {
                        _toggleNavigation();
                        switch (index) {
                          case 0:
                            break;
                          case 1:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      TireListScreen(user: widget.user)),
                            );
                            break;
                          case 2:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AddTireScreen(user: widget.user)),
                            );
                            break;
                          case 3:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      SalesInputScreen(user: widget.user)),
                            );
                            break;
                          case 4:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      SalesHistoryScreen(user: widget.user)),
                            );
                            break;
                          case 5:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ReportsScreen(user: widget.user)),
                            );
                            break;
                          case 14: // Profile - index baru sesuai NavPanel
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ProfileScreen(user: widget.user)),
                            );
                            break;
                          default:
                            // unknown index — ignore
                            break;
                        }
                      },
                      onLogout: () async {
                        _toggleNavigation();
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text('Konfirmasi'),
                            content:
                                const Text('Yakin ingin keluar dari akun?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Keluar',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) return;

                        final auth = AuthService();
                        await auth.logout();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
