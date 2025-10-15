import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      String uid = userCred.user!.uid;

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
  Future<void> logout() async {
    await _auth.signOut();
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