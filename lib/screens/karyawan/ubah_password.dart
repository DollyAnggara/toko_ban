import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

/// Menampilkan dialog untuk mengganti password.
/// Mengembalikan `true` bila berhasil, `false` bila dibatalkan atau gagal.
Future<bool> showChangePasswordDialog(
    BuildContext context, AuthService authService) async {
  final _formKey = GlobalKey<FormState>();
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool isLoading = false;

  // Use showDialog with StatefulBuilder so we can update loading state
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Ubah Password'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password lama'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Isi password lama' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password baru'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Isi password baru';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Konfirmasi password'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Konfirmasi password';
                    if (v != newCtrl.text) return 'Password tidak sama';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop(false);
                    },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => isLoading = true);
                      try {
                        await authService.changePassword(
                            currentCtrl.text.trim(), newCtrl.text.trim());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Password berhasil diubah'),
                                backgroundColor: Colors.green),
                          );
                          Navigator.of(context).pop(true);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal mengubah password: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ubah'),
            ),
          ],
        );
      });
    },
  );

  // dispose controllers after dialog closed
  currentCtrl.dispose();
  newCtrl.dispose();
  confirmCtrl.dispose();

  return result ?? false;
}
