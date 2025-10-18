import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home_admin.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

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
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final users = await _auth.getUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _disableUser(String uid) async {
    await _auth.disableAccount(uid, 'users');
    _fetchUsers(); // Refresh list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã vô hiệu hóa user'),
        backgroundColor: vietnamRed,
      ),
    );
  }

  Future<void> _enableUser(String uid) async {
    await _auth.enableAccount(uid, 'users');
    _fetchUsers(); // Refresh list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã kích hoạt user'),
        backgroundColor: vietnamRed,
      ),
    );
  }

  Future<void> _deleteUser(String uid, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa', style: TextStyle(color: vietnamRed, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa user $email? Tài khoản sẽ mất hẳn và phải tạo lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.deleteAccount(uid, 'users');
      _fetchUsers(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xóa user'),
          backgroundColor: vietnamRed,
        ),
      );
    }
  }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDA251D)),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Xin chào với icon cờ Việt Nam (căn giữa)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Quản lý User",
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
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: vietnamRed,
                      ),
                    )
                  : _users.isEmpty
                      ? Center(
                          child: Text(
                            'Không có user nào',
                            style: TextStyle(
                              color: darkTextColor,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isEnabled = user['enabled'] != false;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              color: Colors.white,
                              shadowColor: Colors.black.withOpacity(0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['name'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: darkTextColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Email: ${user['email']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'SĐT: ${user['phone']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Trạng thái: ${isEnabled ? 'Kích hoạt' : 'Vô hiệu hóa'}',
                                            style: TextStyle(
                                              color: isEnabled ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          height: 40,
                                          child: ElevatedButton.icon(
                                            onPressed: () => isEnabled
                                                ? _disableUser(user['uid'])
                                                : _enableUser(user['uid']),
                                            icon: Icon(
                                              isEnabled ? Icons.block : Icons.check_circle,
                                              size: 18,
                                              color: lightTextColor,
                                            ),
                                            label: Text(
                                              isEnabled ? 'Vô hiệu hóa' : 'Kích hoạt',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: lightTextColor,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isEnabled ? Colors.orange : Colors.green,
                                              foregroundColor: lightTextColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: 120,
                                          height: 40,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _deleteUser(user['uid'], user['email']),
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Color(0xFFFFFFFF),
                                            ),
                                            label: const Text(
                                              'Xóa',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFFFFFFF),
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: vietnamRed,
                                              foregroundColor: lightTextColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}