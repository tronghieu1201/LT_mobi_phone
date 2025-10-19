import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_admin.dart';
import 'home_user.dart';
import 'home_store.dart';
import 'home_store1.dart';
import 'home_store2.dart';
import 'home_store3.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  bool loading = false;

  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  // Màu Đỏ cờ (màu nhấn chính)
  static const Color vietnamRed = Color(0xFFDA251D);
  // Màu Vàng sao (màu nhấn phụ)
  static const Color vietnamYellow = Color(0xFFFFC107); // (Màu Amber 500-600)
  // Màu chữ chính (trên nền trắng)
  static Color darkTextColor = Colors.black87;
  // Màu chữ phụ (trên nền đỏ)
  static Color lightTextColor = Colors.white;
  // Màu nền chính
  static Color backgroundColor = Colors.grey[50]!; // Nền hơi xám 1 chút cho dịu mắt

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateBasedOnRole();
      });
    }
  }

  void _navigateBasedOnRole() async {
    // ... (Toàn bộ logic này giữ nguyên) ...
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await _getRoleFromUid(user.uid);
      final email = user.email ?? '';
      if (role == 'admin') {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeAdminScreen()));
        }
      } else if (role == 'user') {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeUserScreen()));
        }
      } else if (role == 'store') {
        if (mounted) {
          if (email == 'store1@gmail.com') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const HomeStore1Screen()));
          } else if (email == 'store2@gmail.com') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const HomeStore2Screen()));
          } else if (email == 'store3@gmail.com') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const HomeStore3Screen()));
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const HomeStoreScreen()));
          }
        }
      }
    }
  }

  Future<String?> _getRoleFromUid(String uid) async {
    // ... (Toàn bộ logic này giữ nguyên) ...
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>?;
      final isEnabled = userData?['enabled'] ?? true;
      if (isEnabled != false) {
        return userData?['role'];
      }
    }

    DocumentSnapshot storeDoc =
        await FirebaseFirestore.instance.collection('store').doc(uid).get();
    if (storeDoc.exists) {
      final storeData = storeDoc.data() as Map<String, dynamic>?;
      final isEnabled = storeData?['enabled'] ?? true;
      if (isEnabled != false) {
        return storeData?['role'];
      }
    }

    return null;
  }

  void _login() async {
    // ... (Toàn bộ logic này giữ nguyên, chỉ đổi màu SnackBar) ...
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vui lòng nhập đầy đủ thông tin'),
            backgroundColor: Colors.red[600], // Màu đỏ cảnh báo
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final role = await _authService.login(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final email = emailCtrl.text.trim();

      if (role != null && role != 'null') {
        if (mounted) {
          if (role == 'admin') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const HomeAdminScreen()));
          } else if (role == 'user') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const HomeUserScreen()));
          } else if (role == 'store') {
            if (email == 'store@gmail.com') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeStoreScreen()));
            } else if (email == 'store1@gmail.com') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeStore1Screen()));
            } else if (email == 'store2@gmail.com') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeStore2Screen()));
            } else if (email == 'store3@gmail.com') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeStore3Screen()));
            } else {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeStoreScreen()));
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Sai thông tin đăng nhập hoặc tài khoản bị vô hiệu hóa'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Nền xám rất nhạt
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.transparent, // Nền AppBar trong suốt
        elevation: 0,
        iconTheme: IconThemeData(color: vietnamRed), // Nút back (nếu có) màu đỏ
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Hình ảnh đại diện khi vào app
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Bóng đen mờ
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/img/1.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Xin chào quý khách với icon cờ Việt Nam (căn giữa)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Xin chào quý khách",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: vietnamRed, // Chữ tiêu đề màu đỏ cờ
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      'assets/img/VietNam.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Form trong Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              color: Colors.white, // Card nền trắng tinh
              shadowColor: Colors.black.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: darkTextColor), // Chữ đen
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: vietnamYellow), // Icon màu VÀNG
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: vietnamRed, width: 2.0), // Viền focus màu ĐỎ
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      style: TextStyle(color: darkTextColor), // Chữ đen
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: vietnamYellow), // Icon màu VÀNG
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: vietnamRed, width: 2.0), // Viền focus màu ĐỎ
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vietnamRed, // Nút màu ĐỎ cờ
                          foregroundColor: lightTextColor, // Chữ TRẮNG
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                        ),
                        child: loading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: lightTextColor,
                                    strokeWidth: 2), // Loading TRẮNG
                              )
                            : Text('Đăng nhập',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: lightTextColor)), // Chữ TRẮNG
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              icon: SizedBox(
                width: 20,
                height: 20,
                child: Image.asset(
                  'assets/img/VietNam.png',
                  fit: BoxFit.contain,
                ),
              ),
              label: Text("Đăng ký",
                  style: TextStyle(color: vietnamRed)), // Chữ màu ĐỎ cờ
              style: TextButton.styleFrom(
                  foregroundColor: vietnamRed), // Màu chữ khi nhấn
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}