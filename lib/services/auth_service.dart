import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

<<<<<<< HEAD
  // Đăng ký tài khoản
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCred.user!.uid;

      String collection = (role == 'store') ? 'store' : 'users';

      await _firestore.collection(collection).doc(uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'role': role,
        'enabled': true, // Mặc định enabled cho user mới
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Đăng nhập
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
=======
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
>>>>>>> 80c036afa8b40c5ce851e56120c92df27f5a9b5a

      String uid = userCred.user!.uid;

<<<<<<< HEAD
      // Kiểm tra trong users
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final isEnabled = userData?['enabled'] ?? true; // Mặc định true nếu không có field
        if (isEnabled != false) {
          return userData?['role'];
        }
      }

      // Kiểm tra trong store
      DocumentSnapshot storeDoc =
          await _firestore.collection('store').doc(uid).get();
      if (storeDoc.exists) {
        final storeData = storeDoc.data() as Map<String, dynamic>?;
        final isEnabled = storeData?['enabled'] ?? true; // Mặc định true nếu không có field
        if (isEnabled != false) {
          return storeData?['role'];
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Đăng xuất
=======
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

  // Fetch danh sách stores
  Future<List<Map<String, dynamic>>> getStores() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('store').get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return {
              'uid': doc.id,
              ...data,
              'enabled': data['enabled'] ?? true, // Mặc định true nếu không có field
            };
          })
          .toList();
    } catch (e) {
      print('Error fetching stores: $e');
      return [];
    }
  }

  // Fetch danh sách users (loại trừ admin nếu cần)
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return data['role'] != 'admin'; // Loại trừ admin
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return {
              'uid': doc.id,
              ...data,
              'enabled': data['enabled'] ?? true, // Mặc định true nếu không có field
            };
          })
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Disable user/store
  Future<void> disableAccount(String uid, String collection) async {
    await _firestore.collection(collection).doc(uid).update({'enabled': false});
  }

  // Enable user/store
  Future<void> enableAccount(String uid, String collection) async {
    await _firestore.collection(collection).doc(uid).update({'enabled': true});
  }

  // Delete account (chỉ xóa document, user Auth vẫn tồn tại nhưng không login được vì không có doc)
  Future<void> deleteAccount(String uid, String collection) async {
    await _firestore.collection(collection).doc(uid).delete();
  }
}