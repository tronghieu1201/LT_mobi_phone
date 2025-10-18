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
    if (FirebaseAuth.instance.currentUser != null) {
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
      if (mounted) {
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

      if (role != null && role != 'null') {
        if (mounted) {
          if (role == 'admin') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeAdminScreen()));
          } else if (role == 'user') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeUserScreen()));
          } else if (role == 'store') {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
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
      backgroundColor: const Color(0xFFF5F7FA), // Nền nhạt cho mobile
      appBar: AppBar(
        title: const Text("Đăng nhập", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[600],
        elevation: 0,
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
                    color: Colors.black.withOpacity(0.1),
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
                  const Text(
                    "Xin chào quý khách",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
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
            const SizedBox(height: 10),
          
            const SizedBox(height: 30),
            // Form trong Card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              icon: SizedBox(
                width: 20,
                height: 20,
                child: Image.asset(
                  'assets/img/VietNam.png',
                  fit: BoxFit.contain,
                ),
              ),
              label: const Text("Đăng ký"),
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