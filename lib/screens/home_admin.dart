import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'manage/manage_stores.dart';
import 'manage/manage_users.dart';

class HomeAdminScreen extends StatelessWidget {
  const HomeAdminScreen({super.key});

  void _handleLogout(BuildContext context) async {
    final auth = AuthService();
    await auth.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  // Màu Đỏ cờ (màu nhấn chính)
  static const Color vietnamRed = Color(0xFFDA251D);
  // Màu Vàng sao (màu nhấn phụ)
  static const Color vietnamYellow = Color(0xFFFFC107); // (Màu Amber 500-600)
  // Màu chữ chính (trên nền trắng)
  static Color darkTextColor = Colors.black87;
  // Màu chữ phụ (trên nền đỏ)
  static Color lightTextColor = Colors.white;
  // Màu nền chính
  static Color backgroundColor = Colors.grey[50]!; // Nền hơi xám 1 chút cho dịu mắt

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Nền xám rất nhạt
      appBar: AppBar(
        title: Text(
          "",
          style: TextStyle(
            color: vietnamRed, // Chữ tiêu đề màu đỏ cờ
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent, // Nền AppBar trong suốt
        elevation: 0,
        iconTheme: IconThemeData(color: vietnamRed), // Icon màu đỏ
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Xin chào Admin với icon cờ Việt Nam (căn giữa)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Rằm Tháng 7",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: vietnamRed, // Chữ tiêu đề màu đỏ cờ
                    ),
                  ),
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
            ),
            const SizedBox(height: 50),

            // Các nút trong Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              color: Colors.white, // Card nền trắng tinh
              shadowColor: Colors.black.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManageStoresScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vietnamRed, // Nút màu ĐỎ cờ
                          foregroundColor: lightTextColor, // Chữ TRẮNG
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text('Quản lý cửa hàng', style: TextStyle(color: lightTextColor)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vietnamRed, // Nút màu ĐỎ cờ
                          foregroundColor: lightTextColor, // Chữ TRẮNG
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text('Quản lý user', style: TextStyle(color: lightTextColor)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => _handleLogout(context),
              icon: SizedBox(
                width: 20,
                height: 20,
                child: Image.asset(
                  'assets/img/VietNam.png',
                  fit: BoxFit.contain,
                ),
              ),
              label: Text("Đăng xuất",
                  style: TextStyle(color: vietnamRed)), // Chữ màu ĐỎ cờ
              style: TextButton.styleFrom(
                  foregroundColor: vietnamRed), // Màu chữ khi nhấn
            ),
          ],
        ),
      ),
    );
  }
}