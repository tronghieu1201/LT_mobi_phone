import 'package:flutter/material.dart';
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

  void _login() async {
    setState(() => loading = true);
    final role = await _authService.login(
      email: emailCtrl.text.trim(),
      password: passCtrl.text.trim(),
    );
    setState(() => loading = false);

    final email = emailCtrl.text.trim();

    if (role == 'admin') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeAdminScreen()));
    } 
    else if (role == 'user') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeUserScreen()));
    } 
    else if (role == 'store') {
      // ✅ Nhận biết cửa hàng theo email
      if (email == 'store@gmail.com') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeStoreScreen()));
      } 
      else if (email == 'store1@gmail.com') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeStore1Screen()));
      } 
      else if (email == 'store2@gmail.com') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeStore2Screen()));
      } 
      else if (email == 'store3@gmail.com') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeStore3Screen()));
      } 
      else {
        // Nếu là store nhưng không trùng các email trên
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeStoreScreen()));
      }
    } 
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sai thông tin đăng nhập')),
      );
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
