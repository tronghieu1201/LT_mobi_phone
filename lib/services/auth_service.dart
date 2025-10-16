import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          'enabled': true,
        });
        print('✅ Admin đã được tạo: $adminEmail');
      }

      // ✅ Đăng nhập admin luôn sau khi kiểm tra
      await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('Đăng nhập thành công: $adminEmail');
    } catch (e) {
      // Nếu tài khoản đã tồn tại, chỉ đăng nhập lại mà không in lỗi
      try {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        print('Đăng nhập thành công: $adminEmail');
      } catch (_) {
        // Trường hợp duy nhất lỗi thật, không đăng nhập được
        print('❌ Lỗi đăng nhập admin: $e');
      }
    }
  }

  // Đăng ký tài khoản (với role)
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
        final isEnabled = userData?['enabled'] ?? true; // Mặc định true nếu không có field
        if (isEnabled != false) {
          print('Đăng nhập thành công: $email (role: ${userData?['role']})');
          return userData?['role'];
        } else {
          await _auth.signOut(); // Đăng xuất nếu bị disable
          print('❌ Tài khoản bị vô hiệu hóa: $email');
          return null;
        }
      }

      // Kiểm tra trong store
      DocumentSnapshot storeDoc =
          await _firestore.collection('store').doc(uid).get();
      if (storeDoc.exists) {
        final storeData = storeDoc.data() as Map<String, dynamic>?;
        final isEnabled = storeData?['enabled'] ?? true; // Mặc định true nếu không có field
        if (isEnabled != false) {
          print('Đăng nhập thành công: $email (role: ${storeData?['role']})');
          return storeData?['role'];
        } else {
          await _auth.signOut(); // Đăng xuất nếu bị disable
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

  // ✅ Lấy thông tin người dùng (role, tên, ...)
  Future<Map<String, dynamic>?> getUserInfo(String uid) async {
    try {
      // Kiểm tra users trước
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      }

      // Nếu không, kiểm tra store
      DocumentSnapshot storeDoc = await _firestore.collection('store').doc(uid).get();
      if (storeDoc.exists) {
        return storeDoc.data() as Map<String, dynamic>?;
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
