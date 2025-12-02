import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save login state
  Future<void> _saveLoginState(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_uid', uid);
      await prefs.setBool('is_logged_in', true);
    } catch (e) {
      print('⚠️ Warning: Could not save login state: $e');
      // Continue without saving - user can still login, just won't auto-login next time
    }
  }

  // Clear login state
  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_in_uid');
      await prefs.setBool('is_logged_in', false);
    } catch (e) {
      print('⚠️ Warning: Could not clear login state: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      print('⚠️ Warning: Could not check login state: $e');
      return false;
    }
  }

  // Get current logged in user from saved state
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('logged_in_uid');

      if (uid == null) return null;

      // Verify Firebase Auth state
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null || firebaseUser.uid != uid) {
        await _clearLoginState();
        return null;
      }

      // Get user data from Firestore
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      } else {
        await _clearLoginState();
        return null;
      }
    } catch (e) {
      print('❌ Error getting current user: $e');
      await _clearLoginState();
      return null;
    }
  }

  Future<UserModel?> register(
      String name, String email, String password, String shopName,
      {String role = 'pelanggan'}) async {
    try {
      print("📧 Creating user with email: $email");

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      print("✅ User created successfully: ${userCredential.user?.uid}");

      UserModel user = UserModel(
        uid: userCredential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        approved: role == 'karyawan' ? false : true,
        shopName: shopName,
      );

      print("💾 Saving user data to Firestore...");

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toMap());

      print("✅ User data saved successfully");

      return user;
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Error: ${e.code} - ${e.message}");
      throw _getErrorMessage(e.code);
    } on FirebaseException catch (e) {
      print("❌ Firebase Error: ${e.code} - ${e.message}");
      throw 'Firestore error: ${e.message}';
    } catch (e) {
      print("❌ General Error: $e");
      throw 'Terjadi kesalahan: $e';
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter)';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'operation-not-allowed':
        return 'Registrasi dengan email/password tidak diizinkan. Periksa Firebase Console.';
      default:
        return 'Registrasi gagal: $errorCode';
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      print("🔐 Attempting login for: $email");

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      print("✅ Firebase Auth successful. UID: ${userCredential.user!.uid}");

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      print("📄 Firestore document exists: ${doc.exists}");

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print("📋 User data from Firestore: $data");

        final user = UserModel.fromMap(data);
        print(
            "👤 Parsed UserModel - Role: ${user.role}, Approved: ${user.approved}");

        // Save login state
        await _saveLoginState(userCredential.user!.uid);
        print("💾 Login state saved");

        return user;
      } else {
        print(
            "❌ Firestore document NOT FOUND for UID: ${userCredential.user!.uid}");
        throw Exception('Data user tidak ditemukan di Firestore');
      }
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Error: ${e.code} - ${e.message}");
      throw _getLoginErrorMessage(e.code);
    } catch (e) {
      print("❌ Login Error: $e");
      throw 'Login gagal: $e';
    }
  }

  String _getLoginErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun dinonaktifkan';
      default:
        return 'Login gagal: $errorCode';
    }
  }

  Future<void> logout() async {
    await _clearLoginState();
    await _auth.signOut();
  }

  /// Change password for the currently signed-in user.
  /// Re-authenticates using the current password before updating.
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum login';
    final email = user.email;
    if (email == null) throw 'Email pengguna tidak tersedia';

    try {
      final credential =
          EmailAuthProvider.credential(email: email, password: currentPassword);
      await user.reauthenticateWithCredential(credential);

      // Some firebase_auth versions expose updatePassword on the User
      // instance, others only on the implementation at runtime. Cast to
      // dynamic to call the method and avoid analyzer complaints about
      // missing members on the abstract `User` type.
      try {
        await (user as dynamic).updatePassword(newPassword);
      } catch (e) {
        // Re-throw so outer handlers can map to friendly messages
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw 'Password lama salah';
        case 'weak-password':
          throw 'Password baru terlalu lemah (minimal 6 karakter)';
        case 'requires-recent-login':
          throw 'Silakan masuk kembali lalu coba lagi';
        default:
          throw 'Gagal mengubah password: ${e.message}';
      }
    } catch (e) {
      throw 'Gagal mengubah password: $e';
    }
  }

  /// Update user's email and name. Requires current password to reauthenticate
  /// when changing email. If only name changes, it updates Firestore directly.
  Future<void> updateEmailAndName(
      {required String currentPassword,
      String? newEmail,
      String? newName}) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna belum login';

    final uid = user.uid;

    try {
      // If email is changing, reauthenticate then update auth email
      if (newEmail != null && newEmail != user.email) {
        final credential = EmailAuthProvider.credential(
            email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);

        // As with updatePassword, some versions/types require a dynamic
        // call to updateEmail to avoid analyzer errors.
        try {
          await (user as dynamic).updateEmail(newEmail);
        } catch (e) {
          rethrow;
        }
      }

      // Update Firestore document for name/email
      final Map<String, dynamic> updates = {};
      if (newName != null) updates['name'] = newName;
      if (newEmail != null) updates['email'] = newEmail;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw 'Password lama salah';
        case 'requires-recent-login':
          throw 'Silakan masuk kembali lalu coba lagi';
        case 'invalid-email':
          throw 'Format email tidak valid';
        default:
          throw 'Gagal memperbarui profil: ${e.message}';
      }
    } catch (e) {
      throw 'Gagal memperbarui profil: $e';
    }
  }
}
