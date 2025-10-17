import 'package:flutter/material.dart';
// Không cần FirebaseAuth nếu chỉ hello, bỏ để tránh lỗi import

class ViewSearch extends StatefulWidget {
  const ViewSearch({super.key});

  @override
  State<ViewSearch> createState() => _ViewSearchState();
}

class _ViewSearchState extends State<ViewSearch> {
  double distance = 0.0; // Định nghĩa biến distance để fix lỗi getter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text('Hello - Trang Tìm kiếm!'),
      ),
      // Nếu sau này cần map hoặc search phức tạp, uncomment và thêm logic
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Ví dụ: Tính distance (giả sử từ geolocator)
      //     setState(() {
      //       distance = 5.5; // Giá trị mẫu
      //     });
      //   },
      //   child: Text('Distance: $distance'),
      // ),
    );
  }
}