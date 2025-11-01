// New file: view_ad_search.dart (Simple placeholder, expand as needed)
import 'package:flutter/material.dart';

class ViewAdSearchScreen extends StatelessWidget {
  const ViewAdSearchScreen({super.key});

  // Colors
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color backgroundColor = Colors.grey[50]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Search'),
        backgroundColor: vietnamRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: backgroundColor,
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: vietnamYellow),
              SizedBox(height: 16),
              Text(
                'Chức năng quản lý Search đang phát triển',
                style: TextStyle(fontSize: 18, color: vietnamRed),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}