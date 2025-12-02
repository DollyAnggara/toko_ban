import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widgets/nav_scaffold.dart';
import '../../services/database_service.dart';
import '../../models/tire_model.dart';
import 'edit_profile.dart';

class AdminProfileScreen extends StatefulWidget {
  final UserModel user;

  const AdminProfileScreen({required this.user, super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isChanging = false;

  Future<void> _showEditProfileDialog() async {
    setState(() => _isChanging = true);
    final changed = await showAdminEditProfileDialog(context, widget.user);
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
    if (role.isEmpty) return '';
    return role[0].toUpperCase() + role.substring(1);
  }

  @override
  Widget build(BuildContext context) {
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
                  // ignore: deprecated_member_use
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

                // Email & Toko boxes
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
                            Text(
                                widget.user.shopName.isEmpty
                                    ? '-'
                                    : widget.user.shopName,
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Data Ban summary
                StreamBuilder<List<Tire>>(
                  stream: _databaseService.getAllTires(),
                  builder: (context, snapshot) {
                    final totalTires = snapshot.data?.length ?? 0;
                    final totalStock = snapshot.data
                            ?.fold<int>(0, (sum, tire) => sum + tire.stock) ??
                        0;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tire_repair,
                                color: Color(0xFF1E40AF), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Data Ban',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E40AF))),
                                const SizedBox(height: 4),
                                Text('$totalTires jenis • $totalStock stok',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isChanging ? null : _showEditProfileDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text(
                      'Edit Profil',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );

    return NavScaffold(
      user: widget.user,
      body: content,
      title: 'Profil',
      showTopBar: true,
    );
  }
}
