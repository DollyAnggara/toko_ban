import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/tire_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../widgets/nav_scaffold.dart';

class AddTireScreen extends StatefulWidget {
  final UserModel user;

  const AddTireScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AddTireScreen> createState() => _AddTireScreenState();
}

class _AddTireScreenState extends State<AddTireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _databaseService = DatabaseService();
  bool _isLoading = false;

  void _addTire() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final newTire = Tire(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brand: _brandController.text.trim(),
        size: _sizeController.text.trim(),
        price: int.parse(_priceController.text),
        stock: int.parse(_stockController.text),
      );

      await _databaseService.addTire(newTire, widget.user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menambahkan ban!'),
            backgroundColor: Colors.green,
          ),
        );
        await Navigator.maybePop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan ban: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build only the form content — header will be rendered by NavScaffold
    final body = SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildInputField(
                  label: 'Merek Ban',
                  controller: _brandController,
                  hint: 'Contoh: Bridgestone'),
              const SizedBox(height: 16),
              _buildInputField(
                  label: 'Ukuran Ban',
                  controller: _sizeController,
                  hint: 'Contoh: 195/65 R15'),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Harga (Rp)',
                controller: _priceController,
                hint: 'Contoh: 850000',
                isNumber: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Stok Awal',
                controller: _stockController,
                hint: 'Contoh: 10',
                isNumber: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addTire,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Tambah',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Use NavScaffold with its top bar enabled so the blue header fills the top area
    return NavScaffold(
        user: widget.user, body: body, title: 'Tambah Ban', showTopBar: true);
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              height: 1.4),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label harus diisi';
            }
            if (isNumber && int.tryParse(value) == null) {}
            return null;
          },
        ),
      ],
    );
  }
}
