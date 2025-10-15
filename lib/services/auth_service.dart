import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Chỉ đảm bảo admin tồn tại, không in log thừa
  Future<void> ensureDefaultAdmin() async {
    const adminEmail = 'admin@gmail.com';
    const adminPassword = '123456';

    try {
      final methods = await _auth.fetchSignInMethodsForEmail(adminEmail);

      if (methods.isEmpty) {
        // Tạo admin nếu chưa có
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
      }

      // ✅ Đăng nhập admin luôn sau khi kiểm tra
      await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('Đăng nhập thành công: ');
    } catch (e) {
      // Nếu tài khoản đã tồn tại, chỉ đăng nhập lại mà không in lỗi
      try {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        print('Đăng nhập thành công: ');
      } catch (_) {
        // Trường hợp duy nhất lỗi thật, không đăng nhập được
      }
    }
  }

  // ✅ Đăng ký người dùng mới có thông tin
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

    print('✅ Người dùng mới đã được tạo: $email');
    return userCred.user;
  }

  // ✅ Đăng nhập người dùng thường
  Future<User?> login(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    print('Đăng nhập thành công: $email');
    return userCred.user;
  }

  // ✅ Lấy thông tin người dùng (role, tên, ...)
  Future<Map<String, dynamic>?> getUserInfo(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    return snap.data();
  }

  // ✅ Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
    print('👋 Đã đăng xuất');
  }
}
