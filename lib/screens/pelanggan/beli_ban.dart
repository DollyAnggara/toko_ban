import 'package:flutter/material.dart';
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

  double _cartTotal(List<Tire> tires) {
    double sum = 0;
    for (final entry in _cart.entries) {
      final tire = tires.firstWhere((t) => t.id == entry.key);
      sum += tire.price.toDouble() * entry.value;
    }
    return sum;
  }

  Future<void> _performCheckout(List<Tire> tires) async {
    if (_cart.isEmpty) return;
    // Build sale
    final items = <SaleItem>[];
    for (final e in _cart.entries) {
      final tire = tires.firstWhere((t) => t.id == e.key);
      items.add(SaleItem(
          tireId: tire.id,
          name: tire.brand + ' ' + tire.size,
          qty: e.value,
          price: tire.price.toDouble()));
    }
    final total = _cartTotal(tires);

    print('🛒 Checkout Debug:');
    print('Cart items: ${_cart.length}');
    for (final e in _cart.entries) {
      final tire = tires.firstWhere((t) => t.id == e.key);
      print(
          '  - ${tire.brand} ${tire.size}: ${e.value} x Rp${tire.price} = Rp${tire.price * e.value}');
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
    );

    print('Sale object total: Rp${sale.total}');
    print('Sale items count: ${sale.items.length}');

    // Save sale and decrement stock
    try {
      await _db.addSale(sale, widget.user.uid);
      for (final e in _cart.entries) {
        final tire = tires.firstWhere((t) => t.id == e.key);
        final updated = Tire(
            id: tire.id,
            brand: tire.brand,
            size: tire.size,
            price: tire.price,
            stock: tire.stock - e.value);
        await _db.updateTire(updated);
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
    final items = _cart.entries.map((e) {
      final tire = tires.firstWhere((t) => t.id == e.key);
      return {'tire': tire, 'qty': e.value};
    }).toList();

    var confirming = false;
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
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (_, i) {
                        final entry = items[i];
                        final Tire tire = entry['tire'] as Tire;
                        final int qty = entry['qty'] as int;
                        return ListTile(
                          title: Text('${tire.brand} ${tire.size}'),
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
                        await _performCheckout(tires);
                        setStateDialog(() => confirming = false);
                        if (mounted) Navigator.of(ctx).pop(true);
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
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: tires.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = tires[i];
                    final qty = _cart[t.id] ?? 0;
                    return Card(
                      color: Colors.white,
                      child: ListTile(
                        title: Text('${t.brand} ${t.size}'),
                        subtitle: Text(
                            'Rp ${t.price.toStringAsFixed(0)} • Stok: ${t.stock}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (qty > 0) ...[
                              IconButton(
                                  onPressed: () => _removeFromCart(t),
                                  icon:
                                      const Icon(Icons.remove_circle_outline)),
                              Text(qty.toString()),
                              IconButton(
                                  onPressed: () => _addToCart(t),
                                  icon: const Icon(Icons.add_circle_outline)),
                            ] else ...[
                              ElevatedButton(
                                  onPressed:
                                      t.stock > 0 ? () => _addToCart(t) : null,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E40AF)),
                                  child: const Text('Beli',
                                      style: TextStyle(color: Colors.white)))
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
