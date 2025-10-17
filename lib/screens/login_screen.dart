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

  @override
  void initState() {
    super.initState();
    // ✅ Check nếu đã login, không cho vào login
    if (FirebaseAuth.instance.currentUser != null) {
      // App sẽ handle ở AuthWrapper, nhưng nếu vào đây thì redirect
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateBasedOnRole();
      });
    }
  }

  void _navigateBasedOnRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await _getRoleFromUid(user.uid);
      final email = user.email ?? '';
      if (role == 'admin') {
        if (mounted) {  // ✅ Thêm mounted check để tránh dispose error
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
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeStore1Screen()));
          } else if (email == 'store2@gmail.com') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeStore2Screen()));
          } else if (email == 'store3@gmail.com') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeStore3Screen()));
          } else {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeStoreScreen()));
          }
        }
      }
    }
  }

  Future<String?> _getRoleFromUid(String uid) async {
    // Tương tự helper ở main.dart
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
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
      if (mounted) {  // ✅ Thêm mounted cho snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
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

      if (role != null && role != 'null') {  // ✅ Check role hợp lệ
        if (mounted) {  // ✅ Mounted trước navigate
          if (role == 'admin') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeAdminScreen()));
          } else if (role == 'user') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeUserScreen()));
          } else if (role == 'store') {
            // ✅ Nhận biết cửa hàng theo email
            if (email == 'store@gmail.com') {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomeStoreScreen()));
            } else if (email == 'store1@gmail.com') {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomeStore1Screen()));
            } else if (email == 'store2@gmail.com') {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomeStore2Screen()));
            } else if (email == 'store3@gmail.com') {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomeStore3Screen()));
            } else {
              // Nếu là store nhưng không trùng các email trên
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomeStoreScreen()));
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sai thông tin đăng nhập hoặc tài khoản bị vô hiệu hóa')),
          );
        }
      }
    } catch (e) {
      // ✅ Log lỗi nếu cần: print('Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {  // ✅ Mounted ở finally để tránh dispose error
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _login,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Đăng nhập'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: const Text("Chưa có tài khoản? Đăng ký"),
            ),
          ],
        ),
      ),
    );
  }
}