import 'package:flutter/material.dart';

class HomeEditor extends StatelessWidget {
  const HomeEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang biên tập viên')),
      body: const Center(child: Text('Xin chào Editor ✍️')),
    );
  }
}
