import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeUserScreen extends StatelessWidget {
  final String userName;

  const HomeUserScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang người dùng')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('👋 Xin chào $userName', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            const Text('Form hiển thị số 2 (User)', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await AuthService().logout();
                Navigator.pop(context);
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
