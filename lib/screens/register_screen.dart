import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import để handle FirebaseAuthException
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  String role = 'user';
  bool loading = false;

  final AuthService _auth = AuthService();

  void _register() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
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
      final result = await _auth.register(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        role: role,
      );

      if (mounted) {
        setState(() => loading = false);
      }

      if (result == "success") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đăng ký thành công")),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result ?? "Lỗi không xác định")),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }
      String errorMsg = "Lỗi đăng ký: ${e.message}";
      if (e.code == 'email-already-in-use') {
        errorMsg = "Email đã tồn tại, hãy đăng nhập hoặc dùng email khác.";
      } else if (e.code == 'weak-password') {
        errorMsg = "Mật khẩu quá yếu, hãy dùng mật khẩu mạnh hơn.";
      } else if (e.code == 'invalid-email') {
        errorMsg = "Email không hợp lệ.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi không xác định: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký tài khoản")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu')),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Loại tài khoản'),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Người dùng')),
                  DropdownMenuItem(value: 'store', child: Text('Cửa hàng')),
                ],
                onChanged: (val) => setState(() => role = val!),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: loading ? null : _register,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Đăng ký"),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }
}