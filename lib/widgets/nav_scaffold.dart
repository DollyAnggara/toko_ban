import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'nav_panel.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/karyawan/data_ban.dart';
import '../screens/karyawan/tambah_ban.dart';
import '../screens/karyawan/penjualan.dart';
import '../screens/karyawan/riwayat_penjualan.dart';
import '../screens/karyawan/dashboard.dart';
import '../screens/pelanggan/dashboard.dart';
import '../screens/admin/dashboard.dart' as adashboard;
import '../screens/admin/daftar_karyawan.dart' as admin_karyawan;
import '../screens/admin/daftar_pelanggan.dart' as admin_pelanggan;
import '../screens/admin/data_ban.dart' as admin_data_ban;
import '../screens/admin/tambah_ban.dart' as admin_tambah_ban;
import '../screens/admin/riwayat_penjualan.dart' as admin_sales;
import '../screens/admin/tambah_admin.dart' as admin_create;
import '../screens/admin/profile.dart' as admin_profile;
import '../screens/admin/laporan.dart' as admin_laporan;
import '../screens/pelanggan/beli_ban.dart';
import '../screens/pelanggan/riwayat_pembelian.dart';
import '../screens/karyawan/laporan.dart';
import '../screens/karyawan/laporan_penjualan.dart';
import '../screens/karyawan/laporan_stok.dart';
import '../screens/karyawan/profile.dart';
import '../screens/pelanggan/profile.dart' as pelanggan_profile;

/// NavScaffold: a Scaffold-like wrapper that provides the overlay navigation
/// used on Dashboard. Pass `user` and `body` (the page content). It shows a
/// top bar with a menu button that opens the nav panel.
class NavScaffold extends StatefulWidget {
  final UserModel user;
  final Widget body;
  final String? title;
  final Widget? headerWidget;
  final bool showTopBar;

  const NavScaffold(
      {required this.user,
      required this.body,
      this.title,
      this.headerWidget,
      this.showTopBar = true,
      super.key});

  @override
  State<NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends State<NavScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _navigationController;
  late Animation<double> _navigationAnimation;
  late Animation<Offset> _navigationOffset;
  bool _isNavigationVisible = false;

  @override
  void initState() {
    super.initState();
    _navigationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _navigationAnimation = CurvedAnimation(
        parent: _navigationController, curve: Curves.easeOutCubic);
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

  @override
  Widget build(BuildContext context) {
    const double navWidth = 320;
    String normalizedRole() => widget.user.role.trim().toLowerCase();

    bool roleAllowed(List<String> allowedRoles) {
      if (allowedRoles.isEmpty) return true; // empty = allow all
      final r = normalizedRole();
      for (final a in allowedRoles) {
        if (r.contains(a)) return true;
      }
      return false;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          SafeArea(
            top: false,
            child: Column(
              children: [
                // Full-bleed top header when requested
                if (widget.showTopBar)
                  Builder(builder: (ctx) {
                    final statusBar = MediaQuery.of(ctx).padding.top;
                    return Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E40AF),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      padding: EdgeInsets.only(
                          top: statusBar + 14, bottom: 18, left: 16, right: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Use a Stack so the menu icon doesn't push the title
                          // off-center — the title will always be centered.
                          SizedBox(
                            height: 44,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  left: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.menu,
                                        color: Colors.white),
                                    onPressed: _toggleNavigation,
                                    tooltip: 'Menu',
                                  ),
                                ),
                                if (widget.title != null)
                                  Center(
                                    child: Text(widget.title!,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.headerWidget != null) widget.headerWidget!,
                        ],
                      ),
                    );
                  }),

                Expanded(
                  child: widget.body,
                ),
              ],
            ),
          ),

          // Backdrop
          // Backdrop with subtle opacity when nav is visible
          if (_isNavigationVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleNavigation,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _isNavigationVisible ? 1.0 : 0.0,
                  child: Container(color: Colors.black26),
                ),
              ),
            ),

          // Navigation panel (slides in using SlideTransition for smoother GPU animation)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: SlideTransition(
              position: _navigationOffset,
              child: SizedBox(
                width: navWidth,
                child: Material(
                  elevation: 10,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.horizontal(right: Radius.circular(24)),
                  ),
                  child: RepaintBoundary(
                    child: NavPanel(
                      user: widget.user,
                      onItemTap: (index) async {
                        // close the nav; we'll show access denied if needed
                        _toggleNavigation();

                        // define allowed roles per item (empty = allow all)
                        final Map<int, List<String>> allowed = {
                          0: [],
                          1: ['karyawan', 'admin', 'pelanggan'],
                          2: ['karyawan', 'admin', 'pelanggan'],
                          3: ['karyawan', 'admin'],
                          4: ['karyawan', 'admin'],
                          5: ['karyawan', 'admin'],
                          // admin-only indices
                          6: ['admin'], // Daftar Karyawan
                          7: ['admin'], // Daftar Pelanggan
                          8: ['admin'], // Daftar Ban (Admin)
                          9: ['admin'], // Tambah Ban
                          10: ['admin'], // Riwayat Penjualan (Admin)
                          11: ['admin'], // Laporan Penjualan
                          12: ['admin'], // Laporan Stok
                          13: ['admin'], // Buat Akun Admin
                          // profile index (allowed all)
                          14: [],
                        };

                        final need = allowed[index] ?? [];
                        if (!roleAllowed(need)) {
                          // show a friendly access denied dialog
                          await showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Akses Ditolak'),
                              content: const Text(
                                  'Anda tidak memiliki izin untuk mengakses bagian ini.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('OK')),
                              ],
                            ),
                          );
                          return;
                        }

                        switch (index) {
                          case 0: // dashboard
                            // Route to different dashboards depending on role
                            final r = normalizedRole();
                            if (r.contains('admin')) {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => adashboard.AdminDashboard(
                                          user: widget.user)),
                                  (route) => false);
                            } else if (r.contains('pelanggan') ||
                                r.contains('customer')) {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => CustomerDashboardScreen(
                                          user: widget.user)),
                                  (route) => false);
                            } else {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          DashboardScreen(user: widget.user)),
                                  (route) => false);
                            }
                            break;
                          case 1:
                            // Pelanggan: Pembelian, Karyawan/Admin: Data Ban
                            final r = normalizedRole();
                            if (r.contains('pelanggan')) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          BeliBanScreen(user: widget.user)));
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          TireListScreen(user: widget.user)));
                            }
                            break;
                          case 2:
                            // Pelanggan: Riwayat Pembelian, Karyawan/Admin: Tambah Ban
                            final r2 = normalizedRole();
                            if (r2.contains('pelanggan')) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => RiwayatPembelianScreen(
                                          user: widget.user)));
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          AddTireScreen(user: widget.user)));
                            }
                            break;
                          case 3:
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        SalesInputScreen(user: widget.user)));
                            break;
                          case 4:
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        SalesHistoryScreen(user: widget.user)));
                            break;
                          case 5:
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ReportsScreen(user: widget.user)));
                            break;
                          case 6: // Daftar Karyawan (admin)
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        admin_karyawan.AdminDaftarKaryawan(
                                            user: widget.user)));
                            break;
                          case 7: // Daftar Pelanggan (admin)
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        admin_pelanggan.AdminDaftarPelanggan(
                                            user: widget.user)));
                            break;
                          case 8: // Daftar Ban (admin)
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => admin_data_ban.AdminDataBan(
                                        user: widget.user)));
                            break;
                          case 9: // Tambah Ban (admin)
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        admin_tambah_ban.AdminTambahBan(
                                            user: widget.user)));
                            break;
                          case 10: // Riwayat Penjualan (admin)
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        admin_sales.AdminRiwayatPenjualan(
                                            user: widget.user)));
                            break;
                          case 11: // Laporan Penjualan
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => LaporanPenjualanScreen(
                                        user: widget.user)));
                            break;
                          case 12: // Laporan Stok
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        LaporanStokScreen(user: widget.user)));
                            break;
                          case 13: // Buat Akun Admin
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        admin_create.AdminTambahAdmin(
                                            user: widget.user)));
                            break;

                          case 14:
                            final r = normalizedRole();
                            if (r.contains('admin')) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          admin_profile.AdminProfileScreen(
                                              user: widget.user)));
                            } else if (r.contains('pelanggan') ||
                                r.contains('customer')) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => pelanggan_profile
                                          .PelangganProfileScreen(
                                              user: widget.user)));
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ProfileScreen(user: widget.user)));
                            }
                            break;

                          case 15: // Laporan Admin
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        admin_laporan.AdminLaporanScreen(
                                            user: widget.user)));
                            break;
                        }
                      },
                      onLogout: () async {
                        // Ask for confirmation before logging out
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
                          // ignore: use_build_context_synchronously
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
