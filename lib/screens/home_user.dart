import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeUserScreen extends StatelessWidget {
  const HomeUserScreen({super.key});

  void _handleLogout(BuildContext context) async {
    final auth = AuthService();
    await auth.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: const Center(
        child: Text("Chào mừng bạn, người dùng 👋"),
      ),
    );
  }
}