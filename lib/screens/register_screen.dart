import 'package:flutter/material.dart';
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
    setState(() => loading = true);
    final result = await _auth.register(
      email: emailCtrl.text.trim(),
      password: passCtrl.text.trim(),
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      role: role,
    );
    setState(() => loading = false);

    if (result == "success") {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Đăng ký thành công")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result ?? "Lỗi không xác định")));
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
}
