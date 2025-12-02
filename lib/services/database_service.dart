import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tire_model.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTire(Tire tire, String userId) async {
    try {
      await _firestore
          .collection('tires')
          .doc(tire.id)
          .set({...tire.toMap(), 'userId': userId});
    } catch (e) {
      print('Error adding tire: $e');
      rethrow;
    }
  }

  Future<void> updateTire(Tire tire) async {
    try {
      await _firestore.collection('tires').doc(tire.id).update(tire.toMap());
    } catch (e) {
      print('Error updating tire: $e');
      rethrow;
    }
  }

  Future<void> deleteTire(String tireId) async {
    try {
      await _firestore.collection('tires').doc(tireId).delete();
    } catch (e) {
      print('Error deleting tire: $e');
      rethrow;
    }
  }

  // Mengembalikan stream List<Tire> untuk user tertentu
  Stream<List<Tire>> getTires(String userId) {
    return _firestore
        .collection('tires')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              // Jika model Tire.fromMap menerima Map<String, dynamic>
              return Tire.fromMap(data);
            }).toList());
  }

  // Get all tires across all users (for pelanggan browsing)
  Stream<List<Tire>> getAllTires() {
    return _firestore.collection('tires').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Tire.fromMap(doc.data())).toList());
  }

  // Sales: add a sale document and stream sales for a user
  Future<void> addSale(Sale sale, String userId) async {
    try {
      final ref = _firestore.collection('sales').doc();
      final saleData = {
        ...sale.toMap(),
        'userId': userId,
        'date': Timestamp.fromDate(sale.date),
      };

      print('💾 Saving sale to Firestore:');
      print('Total: ${saleData['total']}');
      print('Items: ${saleData['items']}');

      await ref.set(saleData);
      print('✅ Sale saved successfully');
    } catch (e) {
      print('Error adding sale: $e');
      rethrow;
    }
  }

  Stream<List<Sale>> getSales(String userId) {
    return _firestore
        .collection('sales')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Sale.fromMap(d.id, d.data())).toList());
  }

  // Stream sales filtered by customer name (useful for pelanggan purchase history)
  Stream<List<Sale>> getSalesByCustomer(String customerName) {
    print('🔍 Querying sales for customer: $customerName');
    return _firestore
        .collection('sales')
        .where('customerName', isEqualTo: customerName)
        .snapshots()
        .map((snap) {
      print('📦 Found ${snap.docs.length} sales for $customerName');
      final sales = snap.docs.map((d) => Sale.fromMap(d.id, d.data())).toList();
      // Sort by date descending in memory
      sales.sort((a, b) => b.date.compareTo(a.date));
      return sales;
    });
  }

  // Stream all sales across all users (admin view)
  Stream<List<Sale>> getAllSales() {
    return _firestore
        .collection('sales')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Sale.fromMap(d.id, d.data())).toList());
  }

  // Update sale status
  Future<void> updateSaleStatus(String saleId, String newStatus) async {
    try {
      await _firestore.collection('sales').doc(saleId).update({
        'status': newStatus,
      });
    } catch (e) {
      print('Error updating sale status: $e');
      rethrow;
    }
  }

  // Users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final map = {...data, 'uid': d.id};
              return UserModel.fromMap(Map<String, dynamic>.from(map));
            }).toList());
  }

  Stream<List<UserModel>> getPelanggan() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'pelanggan')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final map = {...data, 'uid': d.id};
              return UserModel.fromMap(Map<String, dynamic>.from(map));
            }).toList());
  }

  Stream<List<UserModel>> getKaryawan() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'karyawan')
        .where('approved', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final map = {...data, 'uid': d.id};
              return UserModel.fromMap(Map<String, dynamic>.from(map));
            }).toList());
  }

  Stream<List<UserModel>> getPendingKaryawan() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'karyawan')
        .where('approved', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final map = {...data, 'uid': d.id};
              return UserModel.fromMap(Map<String, dynamic>.from(map));
            }).toList());
  }

  Future<void> approveKaryawan(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'approved': true});
    } catch (e) {
      print('Error approving karyawan: $e');
      rethrow;
    }
  }
}
