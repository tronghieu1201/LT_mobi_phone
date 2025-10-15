import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home_admin.dart';

class ManageStoresScreen extends StatefulWidget {
  const ManageStoresScreen({super.key});

  @override
  State<ManageStoresScreen> createState() => _ManageStoresScreenState();
}

class _ManageStoresScreenState extends State<ManageStoresScreen> {
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    final stores = await _auth.getStores();
    setState(() {
      _stores = stores;
      _isLoading = false;
    });
  }

  Future<void> _disableStore(String uid) async {
    await _auth.disableAccount(uid, 'store');
    _fetchStores(); // Refresh list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã vô hiệu hóa cửa hàng')),
    );
  }

  Future<void> _enableStore(String uid) async {
    await _auth.enableAccount(uid, 'store');
    _fetchStores(); // Refresh list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã kích hoạt cửa hàng')),
    );
  }

  Future<void> _deleteStore(String uid, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa cửa hàng $email? Tài khoản sẽ mất hẳn và phải tạo lại.'),
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
      await _auth.deleteAccount(uid, 'store');
      _fetchStores(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa cửa hàng')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý cửa hàng'),
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
          : _stores.isEmpty
              ? const Center(child: Text('Không có cửa hàng nào'))
              : ListView.builder(
                  itemCount: _stores.length,
                  itemBuilder: (context, index) {
                    final store = _stores[index];
                    final isEnabled = store['enabled'] != false;
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(store['name'] ?? 'N/A'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${store['email']}'),
                            Text('SĐT: ${store['phone']}'),
                            Text('Trạng thái: ${isEnabled ? 'Kích hoạt' : 'Vô hiệu hóa'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(isEnabled ? Icons.block : Icons.check_circle),
                              onPressed: () => isEnabled ? _disableStore(store['uid']) : _enableStore(store['uid']),
                              color: isEnabled ? Colors.orange : Colors.green,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteStore(store['uid'], store['email']),
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