import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../widgets/nav_scaffold.dart';

class AdminDaftarKaryawan extends StatefulWidget {
  final UserModel user;

  const AdminDaftarKaryawan({required this.user, super.key});

  @override
  State<AdminDaftarKaryawan> createState() => _AdminDaftarKaryawanState();
}

class _AdminDaftarKaryawanState extends State<AdminDaftarKaryawan> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _toggleApproval(String uid, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'approved': !currentStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus
                  ? 'Karyawan berhasil disetujui'
                  : 'Persetujuan karyawan dibatalkan',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e')),
        );
      }
    }
  }

  Future<void> _deleteEmployee(String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Hapus Karyawan'),
        content: Text('Apakah Anda yakin ingin menghapus karyawan "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('users').doc(uid).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Karyawan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus karyawan: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavScaffold(
      user: widget.user,
      title: 'Daftar Karyawan',
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('role', isEqualTo: 'karyawan')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = snapshot.data!.docs;

          if (employees.isEmpty) {
            return const Center(
              child: Text('Belum ada karyawan terdaftar'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = employees[index].data() as Map<String, dynamic>;
              final employee = UserModel.fromMap(data);

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
                    CircleAvatar(
                      // ignore: deprecated_member_use
                      backgroundColor: const Color(0xFF1E40AF).withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            employee.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: employee.approved
                                  // ignore: deprecated_member_use
                                  ? Colors.green.withOpacity(0.1)
                                  // ignore: deprecated_member_use
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              employee.approved ? 'Disetujui' : 'Menunggu',
                              style: TextStyle(
                                fontSize: 11,
                                color: employee.approved
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: employee.approved,
                      onChanged: (value) =>
                          _toggleApproval(employee.uid, employee.approved),
                      activeThumbColor: const Color(0xFF1E40AF),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () =>
                          _deleteEmployee(employee.uid, employee.name),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Hapus Karyawan',
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
