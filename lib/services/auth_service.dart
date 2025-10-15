import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Giữ nguyên phần admin gốc
  Future<void> ensureDefaultAdmin() async {
    const adminEmail = 'admin@gmail.com';
    const adminPassword = '123456';
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(adminEmail);
      if (methods.isEmpty) {
        final userCred = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        await _firestore.collection('users').doc(userCred.user!.uid).set({
          'email': adminEmail,
          'role': 'admin',
          'name': 'Admin',
          'phone': '0000000000',
        });
        print('✅ Đã tạo admin mặc định');
      }
    } catch (e) {
      print('⚠️ Lỗi tạo admin: $e');
    }
  }

  // ✅ Đăng ký có thông tin
  Future<User?> registerWithInfo(
      String name, String phone, String email, String password) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(userCred.user!.uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'role': 'user',
    });

    return userCred.user;
  }

  // ✅ Đăng nhập
  Future<User?> login(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCred.user;
  }

  // ✅ Lấy role và họ tên
  Future<Map<String, dynamic>?> getUserInfo(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    return snap.data();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
