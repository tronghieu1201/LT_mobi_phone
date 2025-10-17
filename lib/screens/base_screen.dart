import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  void _handleLogout(BuildContext context) async {
    final auth = AuthService();
    await auth.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _handleLogout(context)),
          ...?actions,
        ],
      ),
      body: body,
    );
  }
}