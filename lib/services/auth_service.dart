import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';  // Import cho Google Sign-In (mobile)

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SỬA: GoogleSignIn cho web (thêm clientId cho Chrome) - GIỮ NGUYÊN NHƯNG KHÔNG DÙNG TRÊN WEB
  static const String _webClientId = '183467337649-jr0c3ccfpu2l219ivg5r8ce9c7r2i4te.apps.googleusercontent.com';  // Web Client ID từ Firebase
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,  // Chỉ dùng clientId trên web (nhưng thực tế dùng popup)
    scopes: ['email', 'profile'],  // Scopes cần cho Firebase
  );

  // ✅ Init auth persistence (giữ session sau refresh) - GIỮ NGUYÊN
  Future<void> initAuth() async {
    await _auth.setPersistence(Persistence.LOCAL);
  }

  // ✅ Chỉ đảm bảo admin tồn tại, KHÔNG tự động đăng nhập - GIỮ NGUYÊN
  Future<void> ensureDefaultAdmin() async {
    const adminEmail = 'admin7@gmail.com';
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

  // Đăng ký tài khoản (với role) - Lưu history rỗng (GIỮ NGUYÊN)
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

  // ✅ Đăng ký người dùng mới có thông tin (mặc định role = 'user') - GIỮ NGUYÊN
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
        'role': 'user',  // MẶC ĐỊNH 'user' (không chọn nữa)
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

  // Đăng nhập (trả về role nếu thành công) - GIỮ NGUYÊN
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

  // CẬP NHẬT: Google Sign-In (cải thiện xử lý lỗi web/mobile, đảm bảo data giống registerWithInfo)
  Future<String?> googleSignIn() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      UserCredential result;
      if (kIsWeb) {
        // Trên web: Dùng signInWithPopup với Firebase Auth (tránh token null/COOP). Thêm try-catch cho popup blocked.
        try {
          result = await _auth.signInWithPopup(googleProvider);
          print('✅ Google Sign-In web thành công với popup');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'popup-closed-by-user') {
            print('⚠️ User đóng popup');
            return null;
          } else if (e.code == 'network-request-failed') {
            print('⚠️ Lỗi mạng/CORS trên web - kiểm tra authorized domains trong Firebase Console');
            return 'Lỗi kết nối web';
          }
          rethrow;
        }
      } else {
        // Trên mobile: Giữ google_sign_in, fallback nếu accessToken null.
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print('⚠️ User hủy Google Sign-In mobile');
          return null;  // User cancel
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String? accessToken = googleAuth.accessToken;
        final String? idToken = googleAuth.idToken;

        if (idToken == null && accessToken == null) {
          print('⚠️ Token null trên mobile - kiểm tra SHA-1 trong Firebase');
          return 'Lỗi token mobile';
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );

        result = await _auth.signInWithCredential(credential);
        print('✅ Google Sign-In mobile thành công');
      }

      final user = result.user;
      if (user != null) {
        await _createUserIfNew(user);  // Tạo/cập nhật data giống registerWithInfo
        final role = await _getRoleFromUid(user.uid);
        if (role != null) {
          print('✅ Google Sign-In hoàn tất, role: $role cho ${user.email}');
          return role;
        } else {
          print('⚠️ Không lấy được role sau Google Sign-In');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('❌ Google Sign-In error: $e');  // Debug chi tiết
      return 'Lỗi Google Sign-In: ${e.toString()}';
    }
  }

  // CẬP NHẬT: Tạo user mới trong Firestore (cho đăng ký tự động từ Google) - Thêm photoURL và verify email nếu cần, giống user.dart
  Future<void> _createUserIfNew(User user) async {
    final uid = user.uid;
    final email = user.email ?? '';
    final name = user.displayName ?? 'User Google';  // Tên từ Google
    final phone = user.phoneNumber ?? '';  // Thường null cho Google
    final photoUrl = user.photoURL ?? '';  // Thêm photo từ Google (giống data web thực tế)

    // Kiểm tra nếu chưa có document trong 'users'
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      // Tạo document mới với role 'user' mặc định, data đầy đủ giống registerWithInfo
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'photoUrl': photoUrl,  // Thêm mới: Ảnh đại diện từ Google
        'role': 'user',  // Mặc định cho user thường (giống user.dart)
        'enabled': true,
        'history': [],  // Lưu history rỗng
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ User Google mới đã được tạo với data đầy đủ: $email (role: user)');
      
      // Tùy chọn: Gửi email verification nếu cần (giống data web chuẩn)
      // await user.sendEmailVerification();
    } else {
      print('✅ User Google đã tồn tại: $email');
    }

    // Không auto tạo cho 'store' - admin phải tạo thủ công nếu cần
  }

  // Helper lấy role (tách từ login để dùng chung) - GIỮ NGUYÊN
  Future<String?> _getRoleFromUid(String uid) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>?;
      final isEnabled = userData?['enabled'] ?? true;
      if (isEnabled != false) {
        return userData?['role'];
      }
    }

    DocumentSnapshot storeDoc = await _firestore.collection('store').doc(uid).get();
    if (storeDoc.exists) {
      final storeData = storeDoc.data() as Map<String, dynamic>?;
      final isEnabled = storeData?['enabled'] ?? true;
      if (isEnabled != false) {
        return storeData?['role'];
      }
    }
    return null;
  }

  // ✅ Lấy thông tin người dùng (role, tên, history...) - CẬP NHẬT: Thêm photoUrl nếu có
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

  // Đăng xuất - GIỮ NGUYÊN, thêm signOut Google
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    print('👋 Đã đăng xuất');
  }

  // Fetch danh sách stores - GIỮ NGUYÊN
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

  // Fetch danh sách users (loại trừ admin nếu cần) - GIỮ NGUYÊN
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

  // Disable user/store - GIỮ NGUYÊN
  Future<void> disableAccount(String uid, String collection) async {
    try {
      await _firestore.collection(collection).doc(uid).update({'enabled': false});
      print('✅ Đã vô hiệu hóa tài khoản: $uid');
    } catch (e) {
      print('❌ Lỗi vô hiệu hóa: $e');
    }
  }

  // Enable user/store - GIỮ NGUYÊN
  Future<void> enableAccount(String uid, String collection) async {
    try {
      await _firestore.collection(collection).doc(uid).update({'enabled': true});
      print('✅ Đã kích hoạt tài khoản: $uid');
    } catch (e) {
      print('❌ Lỗi kích hoạt: $e');
    }
  }

  // Delete account (chỉ xóa document, user Auth vẫn tồn tại nhưng không login được vì không có doc) - GIỮ NGUYÊN
  Future<void> deleteAccount(String uid, String collection) async {
    try {
      await _firestore.collection(collection).doc(uid).delete();
      print('✅ Đã xóa tài khoản: $uid');
    } catch (e) {
      print('❌ Lỗi xóa tài khoản: $e');
    }
  }
}