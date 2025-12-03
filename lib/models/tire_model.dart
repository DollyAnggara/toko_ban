class Tire {
  final String id;
  final String brand;
  final String series;
  final String size;
  final int price;
  final int stock;

  Tire(
      {required this.id,
      required this.brand,
      required this.series,
      required this.size,
      required this.price,
      required this.stock});

  factory Tire.fromMap(Map<String, dynamic> m) => Tire(
        id: m['id'] ?? '',
        brand: m['brand'] ?? '',
        series: m['series'] ?? '',
        size: m['size'] ?? '',
        price: (m['price'] ?? 0) as int,
        stock: (m['stock'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'brand': brand,
        'series': series,
        'size': size,
        'price': price,
        'stock': stock,
      };
}
