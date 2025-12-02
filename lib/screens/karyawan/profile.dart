import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'edit_profile.dart';
import '../../widgets/nav_scaffold.dart';
import '../../models/tire_model.dart';
import '../../services/database_service.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  ProfileScreen({required this.user, Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isChanging = false;

  Future<void> _showEditProfileDialog() async {
    // Show modal edit profile dialog (keeps user in-place)
    setState(() => _isChanging = true);
    final changed =
        await showEditProfileDialog(context, AuthService(), widget.user);
    setState(() => _isChanging = false);
    if (!mounted) return;
    if (changed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    }
  }

  String _roleLabel(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized.contains('admin') || normalized.contains('administrator')) {
      return 'Administrator';
    }
    if (normalized.contains('karyawan') || normalized.contains('kary')) {
      return 'Karyawan';
    }
    if (normalized.contains('pelanggan') ||
        normalized.contains('customer') ||
        normalized.contains('client')) {
      return 'Pelanggan';
    }

    // Fallback: capitalize first letter
    if (role.isEmpty) return '';
    return role[0].toUpperCase() + role.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    // Remove the internal blue header because NavScaffold provides the top bar.
    final content = SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.person,
                      color: Color(0xFF1E40AF), size: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _roleLabel(widget.user.role),
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),

                // Email & Toko boxes (label above, value below, small icon)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.email_outlined,
                                      size: 18, color: Color(0xFF6B7280)),
                                ),
                                const SizedBox(width: 10),
                                const Text('Email',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(widget.user.email,
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.store_outlined,
                                      size: 18, color: Color(0xFF6B7280)),
                                ),
                                const SizedBox(width: 10),
                                const Text('Toko',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(widget.user.shopName,
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Data Ban summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      const Text('Data Ban',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF))),
                      const SizedBox(height: 12),
                      StreamBuilder<List<Tire>>(
                        stream: _databaseService.getAllTires(),
                        builder: (context, snap) {
                          final tires = snap.data ?? [];
                          final jenis =
                              tires.map((e) => e.brand).toSet().length;
                          final total =
                              tires.fold<int>(0, (s, e) => s + e.stock);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(jenis.toString(),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E40AF))),
                                  const SizedBox(height: 6),
                                  const Text('Jenis Ban',
                                      style: TextStyle(color: Colors.black54)),
                                ],
                              ),
                              Container(
                                  height: 36,
                                  width: 1,
                                  color: Colors.blue.shade100),
                              Column(
                                children: [
                                  Text(total.toString(),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E40AF))),
                                  const SizedBox(height: 6),
                                  const Text('Total Ban',
                                      style: TextStyle(color: Colors.black54)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                if (_isChanging) const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isChanging ? null : _showEditProfileDialog,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text('Edit Profil',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    // Enable the NavScaffold top bar so the menu button is visible on the profile page.
    return NavScaffold(
        user: widget.user, body: content, title: 'Profil', showTopBar: true);
  }
}
