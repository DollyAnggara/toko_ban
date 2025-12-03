import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tire_model.dart';
import '../../services/database_service.dart';

class AdminEditTireScreen extends StatefulWidget {
  final Tire tire;

  const AdminEditTireScreen({super.key, required this.tire});

  @override
  _AdminEditTireScreenState createState() => _AdminEditTireScreenState();
}

class _AdminEditTireScreenState extends State<AdminEditTireScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _seriesController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _brandController.text = widget.tire.brand;
    _seriesController.text = widget.tire.series;
    _sizeController.text = widget.tire.size;
    _priceController.text = widget.tire.price.toString();
    _stockController.text = widget.tire.stock.toString();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1E40AF),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E40AF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: const Center(
                child: Text(
                  'Edit Data Ban',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                        _buildInputField(
                          label: 'Merek Ban',
                          controller: _brandController,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Seri Ban',
                          controller: _seriesController,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Ukuran',
                          controller: _sizeController,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Harga (Rp)',
                          controller: _priceController,
                          isNumber: true,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Stok',
                          controller: _stockController,
                          isNumber: true,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateTire,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E40AF),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                                        'Update',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label harus diisi';
            }
            if (isNumber && int.tryParse(value) == null) {
              return '$label harus angka';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _updateTire() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        Tire updatedTire = Tire(
          id: widget.tire.id,
          brand: _brandController.text,
          series: _seriesController.text,
          size: _sizeController.text,
          price: int.parse(_priceController.text),
          stock: int.parse(_stockController.text),
        );

        await _databaseService.updateTire(updatedTire);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ban berhasil diupdate')),
        );

        Navigator.pop(context, true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
