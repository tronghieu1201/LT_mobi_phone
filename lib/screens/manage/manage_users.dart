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
      const SnackBar(content: Text('Đã vô hiệu hóa user')),
    );
  }

  Future<void> _enableUser(String uid) async {
    await _auth.enableAccount(uid, 'users');
    _fetchUsers(); // Refresh list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã kích hoạt user')),
    );
  }

  Future<void> _deleteUser(String uid, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
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
        const SnackBar(content: Text('Đã xóa user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý user'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Không có user nào'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isEnabled = user['enabled'] != false;
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(user['name'] ?? 'N/A'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${user['email']}'),
                            Text('SĐT: ${user['phone']}'),
                            Text('Trạng thái: ${isEnabled ? 'Kích hoạt' : 'Vô hiệu hóa'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(isEnabled ? Icons.block : Icons.check_circle),
                              onPressed: () => isEnabled ? _disableUser(user['uid']) : _enableUser(user['uid']),
                              color: isEnabled ? Colors.orange : Colors.green,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user['uid'], user['email']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}