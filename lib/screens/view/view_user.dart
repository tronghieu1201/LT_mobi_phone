import 'package:flutter/material.dart';
import '../login_screen.dart'; // Fix import: dùng '../' vì cùng screens/

class ViewUser extends StatefulWidget {
  const ViewUser({super.key});

  @override
  State<ViewUser> createState() => _ViewUserState();
}

class _ViewUserState extends State<ViewUser> {
  void _handleLogout(BuildContext context) async {
    // Giả sử bạn có AuthService, nếu không thì direct nav
    // final auth = AuthService();
    // await auth.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), // Bỏ const nếu LoginScreen không const
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hello - Trang Hồ sơ!'),
            SizedBox(height: 20),
            Text('Chưa có tính năng upload ảnh (web hạn chế image_picker).'),
          ],
        ),
      ),
    );
  }
}