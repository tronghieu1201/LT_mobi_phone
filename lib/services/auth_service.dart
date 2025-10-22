import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Init auth persistence (giữ session sau refresh)
  Future<void> initAuth() async {
    await _auth.setPersistence(Persistence.LOCAL);
  }

  // ✅ Chỉ đảm bảo admin tồn tại, KHÔNG tự động đăng nhập
  Future<void> ensureDefaultAdmin() async {
    const adminEmail = 'admin@gmail.com';
    const adminPassword = '123456';

    try {
      await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      await _auth.signOut();
      print('✅ Admin đã tồn tại: $adminEmail');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        final userCred = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        await _firestore.collection('users').doc(userCred.user!.uid).set({
          'email': adminEmail,
          'role': 'admin',
          'name': 'Admin',
          'phone': '0000000000',
          'enabled': true,
          'history': [],  // Lưu history rỗng khi tạo tài khoản
        });
        print('✅ Admin đã được tạo: $adminEmail');
      } else {
        print('⚠️ Lỗi check admin: ${e.message}');
      }
    } catch (e) {
      print('...');
    }
  }

  // Đăng ký tài khoản (với role) - Lưu history rỗng
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
        'enabled': true,
        'history': [],  // Lưu history rỗng khi tạo tài khoản
      });

      print('✅ Người dùng mới đã được tạo: $email');
      return "success";
    } on FirebaseAuthException catch (e) {
      print('❌ Lỗi đăng ký: ${e.message}');
      return e.message;
    }
  }

  // ✅ Đăng ký người dùng mới có thông tin (mặc định role = 'user')
  Future<User?> registerWithInfo(
      String name, String phone, String email, String password) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCred.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'user',
        'enabled': true,
        'history': [],  // Lưu history rỗng khi tạo tài khoản
      });

      print('✅ Người dùng mới đã được tạo: $email');
      return userCred.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Lỗi đăng ký: ${e.message}');
      return null;
    }
  }

  // Đăng nhập (trả về role nếu thành công)
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCred.user!.uid;

      // Kiểm tra trong users
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final isEnabled = userData?['enabled'] ?? true;
        if (isEnabled != false) {
          print('Đăng nhập thành công: $email (role: ${userData?['role']})');
          return userData?['role'];
        } else {
          await _auth.signOut();
          print('❌ Tài khoản bị vô hiệu hóa: $email');
          return null;
        }
      }

      // Kiểm tra trong store
      DocumentSnapshot storeDoc =
          await _firestore.collection('store').doc(uid).get();
      if (storeDoc.exists) {
        final storeData = storeDoc.data() as Map<String, dynamic>?;
        final isEnabled = storeData?['enabled'] ?? true;
        if (isEnabled != false) {
          print('Đăng nhập thành công: $email (role: ${storeData?['role']})');
          return storeData?['role'];
        } else {
          await _auth.signOut();
          print('❌ Tài khoản bị vô hiệu hóa: $email');
          return null;
        }
      }

      print('❌ Không tìm thấy thông tin user/store cho: $email');
      return null;
    } on FirebaseAuthException catch (e) {
      print('❌ Lỗi đăng nhập: ${e.message}');
      return e.message;
    }
  }

  // ✅ Lấy thông tin người dùng (role, tên, history...)
  Future<Map<String, dynamic>?> getUserInfo(String uid) async {
    try {
      // Kiểm tra users trước
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (!data.containsKey('history')) {
          data['history'] = [];  // Khởi tạo nếu chưa có
        }
        return data;
      }

      // Nếu không, kiểm tra store
      DocumentSnapshot storeDoc = await _firestore.collection('store').doc(uid).get();
      if (storeDoc.exists) {
        Map<String, dynamic> data = storeDoc.data() as Map<String, dynamic>;
        if (!data.containsKey('history')) {
          data['history'] = [];  // Khởi tạo nếu chưa có
        }
        return data;
      }

      return null;
    } catch (e) {
      print('❌ Lỗi lấy thông tin user: $e');
      return null;
    }
  }

  // Đăng xuất
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
              'enabled': data['enabled'] ?? true,
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
              'enabled': data['enabled'] ?? true,
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
    try {
      await _firestore.collection(collection).doc(uid).update({'enabled': false});
      print('✅ Đã vô hiệu hóa tài khoản: $uid');
    } catch (e) {
      print('❌ Lỗi vô hiệu hóa: $e');
    }
  }

  // Enable user/store
  Future<void> enableAccount(String uid, String collection) async {
    try {
      await _firestore.collection(collection).doc(uid).update({'enabled': true});
      print('✅ Đã kích hoạt tài khoản: $uid');
    } catch (e) {
      print('❌ Lỗi kích hoạt: $e');
    }
  }

  // Delete account (chỉ xóa document, user Auth vẫn tồn tại nhưng không login được vì không có doc)
  Future<void> deleteAccount(String uid, String collection) async {
    try {
      await _firestore.collection(collection).doc(uid).delete();
      print('✅ Đã xóa tài khoản: $uid');
    } catch (e) {
      print('❌ Lỗi xóa tài khoản: $e');
    }
  }
}