import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../models/tire_model.dart';
import '../../models/sale_model.dart';
import '../../services/database_service.dart';
import '../../widgets/nav_scaffold.dart';

class BeliBanScreen extends StatefulWidget {
  final UserModel user;
  const BeliBanScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<BeliBanScreen> createState() => _BeliBanScreenState();
}

class _BeliBanScreenState extends State<BeliBanScreen> {
  final DatabaseService _db = DatabaseService();
  final Map<String, int> _cart = {}; // tireId -> qty
  String? selectedBrand;
  String _paymentMethod = 'tunai'; // Default payment method

  void _addToCart(Tire t) {
    setState(() {
      _cart[t.id] = (_cart[t.id] ?? 0) + 1;
    });
  }

  void _removeFromCart(Tire t) {
    setState(() {
      final cur = (_cart[t.id] ?? 0) - 1;
      if (cur <= 0)
        _cart.remove(t.id);
      else
        _cart[t.id] = cur;
    });
  }

  // Helper method to safely find tire (returns null if deleted)
  Tire? _findTire(List<Tire> tires, String id) {
    try {
      return tires.firstWhere((t) => t.id == id);
    } catch (e) {
      return null; // Tire was deleted from database
    }
  }

  // Clean cart by removing references to deleted tires
  void _cleanCart(List<Tire> tires) {
    final deletedIds = <String>[];
    for (final id in _cart.keys) {
      if (_findTire(tires, id) == null) {
        deletedIds.add(id);
      }
    }
    if (deletedIds.isNotEmpty) {
      // Use post frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            for (final id in deletedIds) {
              _cart.remove(id);
            }
          });
          // Show notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${deletedIds.length} item dihapus dari keranjang (produk tidak tersedia)'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  double _cartTotal(List<Tire> tires) {
    double sum = 0;
    for (final entry in _cart.entries) {
      final tire = _findTire(tires, entry.key);
      if (tire != null) {
        sum += tire.price.toDouble() * entry.value;
      }
    }
    return sum;
  }

  Future<void> _performCheckout(List<Tire> tires,
      {String? senderName, String? paymentProofUrl}) async {
    if (_cart.isEmpty) return;
    // Build sale
    final items = <SaleItem>[];
    for (final e in _cart.entries) {
      final tire = _findTire(tires, e.key);
      if (tire != null) {
        items.add(SaleItem(
            tireId: tire.id,
            name: tire.series.isNotEmpty
                ? '${tire.brand} ${tire.series} ${tire.size}'
                : '${tire.brand} ${tire.size}',
            qty: e.value,
            price: tire.price.toDouble()));
      }
    }
    final total = _cartTotal(tires);

    print('🛒 Checkout Debug:');
    print('Cart items: ${_cart.length}');
    for (final e in _cart.entries) {
      final tire = _findTire(tires, e.key);
      if (tire != null) {
        print(
            '  - ${tire.series.isNotEmpty ? '${tire.brand} ${tire.series}' : tire.brand} ${tire.size}: ${e.value} x Rp${tire.price} = Rp${tire.price * e.value}');
      }
    }
    print('Calculated total: Rp$total');

    final sale = Sale(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNo: 'INV${DateTime.now().millisecondsSinceEpoch}',
      customerName: widget.user.name,
      date: DateTime.now(),
      total: total,
      items: items,
      status: 'pending',
      paymentMethod: _paymentMethod,
      senderName: senderName,
      paymentProofUrl: paymentProofUrl,
    );

    print('Sale object total: Rp${sale.total}');
    print('Sale items count: ${sale.items.length}');

    // Save sale and decrement stock
    try {
      await _db.addSale(sale, widget.user.uid);
      for (final e in _cart.entries) {
        final tire = _findTire(tires, e.key);
        if (tire != null) {
          final updated = Tire(
              id: tire.id,
              brand: tire.brand,
              series: tire.series,
              size: tire.size,
              price: tire.price,
              stock: tire.stock - e.value);
          await _db.updateTire(updated);
        }
      }

      setState(() => _cart.clear());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pembelian berhasil')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<bool?> _showCheckoutDialog(List<Tire> tires) async {
    if (_cart.isEmpty) return false;
    final items = <Map<String, dynamic>>[];
    for (final e in _cart.entries) {
      final tire = _findTire(tires, e.key);
      if (tire != null) {
        items.add({'tire': tire, 'qty': e.value});
      }
    }

    var confirming = false;
    String tempPaymentMethod = _paymentMethod;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Konfirmasi Pembelian'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Payment Method Selection
                  const Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              tempPaymentMethod = 'tunai';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: tempPaymentMethod == 'tunai'
                                    ? const Color(0xFF1E40AF)
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: tempPaymentMethod == 'tunai'
                                  ? const Color(0xFF1E40AF).withOpacity(0.1)
                                  : Colors.white,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.money,
                                  size: 40,
                                  color: tempPaymentMethod == 'tunai'
                                      ? const Color(0xFF1E40AF)
                                      : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tunai',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: tempPaymentMethod == 'tunai'
                                        ? const Color(0xFF1E40AF)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              tempPaymentMethod = 'qris';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: tempPaymentMethod == 'qris'
                                    ? const Color(0xFF1E40AF)
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: tempPaymentMethod == 'qris'
                                  ? const Color(0xFF1E40AF).withOpacity(0.1)
                                  : Colors.white,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 40,
                                  color: tempPaymentMethod == 'qris'
                                      ? const Color(0xFF1E40AF)
                                      : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'QRIS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: tempPaymentMethod == 'qris'
                                        ? const Color(0xFF1E40AF)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Cart Items
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (_, i) {
                        final entry = items[i];
                        final Tire tire = entry['tire'] as Tire;
                        final int qty = entry['qty'] as int;
                        return ListTile(
                          title: Text(tire.series.isNotEmpty
                              ? '${tire.brand} ${tire.series} ${tire.size}'
                              : '${tire.brand} ${tire.size}'),
                          trailing: Text('x$qty'),
                          subtitle: Text('Rp ${tire.price.toStringAsFixed(0)}'),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(),
                      itemCount: items.length,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Rp ${_cartTotal(tires).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed:
                      confirming ? null : () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal')),
              ElevatedButton(
                onPressed: confirming
                    ? null
                    : () async {
                        setStateDialog(() => confirming = true);
                        setState(() {
                          _paymentMethod = tempPaymentMethod;
                        });
                        if (tempPaymentMethod == 'qris') {
                          Navigator.of(ctx).pop(false);
                          await _showQRISDialog(tires);
                        } else {
                          await _performCheckout(tires);
                          setStateDialog(() => confirming = false);
                          if (mounted) Navigator.of(ctx).pop(true);
                        }
                      },
                child: confirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Konfirmasi',
                        style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF)),
              ),
            ],
          );
        });
      },
    );

    // if confirmed, nothing else to do (performCheckout cleared cart)
    return confirmed == true;
  }

  Future<void> _showQRISDialog(List<Tire> tires) async {
    var confirming = false;
    final senderNameController = TextEditingController();
    File? selectedImage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Pembayaran QRIS'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Scan QR Code untuk pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // QRIS QR Code Image
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/qris/qris_code.jpg',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                alignment: Alignment.center,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code,
                                        size: 60, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'QR Code tidak tersedia',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await rootBundle
                                    .load('assets/qris/qris_code.jpg');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Gunakan screenshot untuk menyimpan QR Code'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Screenshot untuk Simpan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E40AF),
                              side: const BorderSide(color: Color(0xFF1E40AF)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pembayaran:'),
                              Text(
                                'Rp ${_cartTotal(tires).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Input Nama Pengirim
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: Color(0xFF1E40AF),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Nama Pengirim',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: senderNameController,
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama sesuai akun pengirim',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1E40AF),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nama ini akan digunakan untuk verifikasi pembayaran',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Upload Bukti Pembayaran
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.upload_file,
                                size: 20,
                                color: Color(0xFF1E40AF),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Bukti Pembayaran',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (selectedImage != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                selectedImage!, // Payment proof image
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setStateDialog(() {
                                        selectedImage = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete, size: 18),
                                    label: const Text('Hapus'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image =
                                          await picker.pickImage(
                                        source: ImageSource.gallery,
                                        imageQuality: 70,
                                      );
                                      if (image != null) {
                                        setStateDialog(() {
                                          selectedImage = File(image.path);
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('Ganti'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E40AF),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            OutlinedButton.icon(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 70,
                                );
                                if (image != null) {
                                  setStateDialog(() {
                                    selectedImage = File(image.path);
                                  });
                                }
                              },
                              icon: const Icon(Icons.add_photo_alternate),
                              label:
                                  const Text('Pilih Gambar Bukti Pembayaran'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E40AF),
                                side:
                                    const BorderSide(color: Color(0xFF1E40AF)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload screenshot bukti transfer untuk verifikasi',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Upload bukti pembayaran dan isi nama pengirim, kemudian klik "Konfirmasi Pembayaran"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: confirming
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                      },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: confirming
                    ? null
                    : () async {
                        final senderName = senderNameController.text.trim();

                        if (senderName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mohon masukkan nama pengirim'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (selectedImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mohon upload bukti pembayaran'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setStateDialog(() => confirming = true);

                        try {
                          print('📤 Converting image to Base64...');

                          // Read image bytes
                          final bytes = await selectedImage!.readAsBytes();
                          print('📷 Original size: ${bytes.length} bytes');

                          // Convert to Base64
                          final base64Image = base64Encode(bytes);
                          print(
                              '✅ Image converted to Base64 (${base64Image.length} characters)');

                          await _performCheckout(
                            tires,
                            senderName: senderName,
                            paymentProofUrl: base64Image,
                          );

                          setStateDialog(() => confirming = false);
                          if (mounted) {
                            Navigator.of(ctx).pop();
                          }
                        } catch (e) {
                          print('❌ Error: $e');
                          setStateDialog(() => confirming = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Gagal memproses bukti pembayaran: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                ),
                child: confirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Konfirmasi Pembayaran',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavScaffold(
      user: widget.user,
      title: 'Beli Ban',
      body: StreamBuilder<List<Tire>>(
        stream: _db.getAllTires(),
        builder: (context, snap) {
          final allTires = snap.data ?? [];
          final brands = allTires.map((t) => t.brand).toSet().toList();

          // Clean cart of deleted tire references
          if (allTires.isNotEmpty && _cart.isNotEmpty) {
            _cleanCart(allTires);
          }

          // Filter tires by selected brand
          var tires = allTires;
          if (selectedBrand != null && selectedBrand != '') {
            tires = allTires.where((t) => t.brand == selectedBrand).toList();
          }

          return Column(
            children: [
              // Filter section
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    const Text('Filter Merek: ',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedBrand,
                            hint: const Text('Semua Merek'),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('Semua Merek')),
                              ...brands.map((b) =>
                                  DropdownMenuItem(value: b, child: Text(b)))
                            ],
                            onChanged: (v) => setState(() => selectedBrand = v),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tires.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada ban tersedia',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: tires.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final t = tires[i];
                          final qty = _cart[t.id] ?? 0;
                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              title: Text(t.series.isNotEmpty
                                  ? '${t.brand} ${t.series} ${t.size}'
                                  : '${t.brand} ${t.size}'),
                              subtitle: Text(
                                  'Rp ${t.price.toStringAsFixed(0)} • Stok: ${t.stock}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (qty > 0) ...[
                                    IconButton(
                                        onPressed: () => _removeFromCart(t),
                                        icon: const Icon(
                                            Icons.remove_circle_outline)),
                                    Text(qty.toString()),
                                    IconButton(
                                        onPressed: () => _addToCart(t),
                                        icon: const Icon(
                                            Icons.add_circle_outline)),
                                  ] else ...[
                                    ElevatedButton(
                                        onPressed: t.stock > 0
                                            ? () => _addToCart(t)
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1E40AF)),
                                        child: const Text('Beli',
                                            style:
                                                TextStyle(color: Colors.white)))
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 8)
                  ]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total: Rp ${_cartTotal(tires).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      ElevatedButton(
                          onPressed: () => _showCheckoutDialog(tires),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E40AF)),
                          child: const Text('Checkout',
                              style: TextStyle(color: Colors.white))),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
