import 'package:flutter/material.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Quản lý'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          'Xin chào 👋',
          style: TextStyle(
            fontSize: 28,
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
