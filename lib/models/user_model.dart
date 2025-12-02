class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool approved;
  final String shopName;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.approved = true,
    required this.shopName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'approved': approved,
      'shopName': shopName,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'pelanggan',
      approved: map['approved'] == null ? true : (map['approved'] as bool),
      shopName: map['shopName'] ?? 'GD Mitra - Toko Ban Mobil',
    );
  }
}
