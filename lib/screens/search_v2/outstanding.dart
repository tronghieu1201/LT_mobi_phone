// lib/screens/search_v2/outstanding.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Outstanding extends StatefulWidget {
  final LatLng? currentPosition;
  const Outstanding({super.key, required this.currentPosition});

  @override
  State<Outstanding> createState() => _OutstandingState();
}

class _OutstandingState extends State<Outstanding> {
  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color backgroundColor = Colors.grey[50]!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      primaryColor: vietnamRed,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: vietnamRed),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nổi bật gần đây', style: TextStyle(color: vietnamRed)),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  'assets/img/VietNam.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder content for Outstanding screen
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh sách nổi bật chi tiết',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: vietnamRed,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nội dung nổi bật sẽ được thêm sau...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Vị trí hiện tại
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: vietnamYellow, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Vị trí: ${widget.currentPosition?.latitude.toStringAsFixed(4)}, ${widget.currentPosition?.longitude.toStringAsFixed(4)}',
                        style: TextStyle(fontSize: 14, color: vietnamRed),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}