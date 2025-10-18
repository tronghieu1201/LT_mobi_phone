import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart'; // Import AuthService (sửa đường dẫn nếu cần)
import '../login_screen.dart'; // Import để nav về login

class ViewUser extends StatefulWidget {
  const ViewUser({super.key});

  @override
  State<ViewUser> createState() => _ViewUserState();
}

class _ViewUserState extends State<ViewUser> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userInfo; // Lưu thông tin user để dùng chung
  bool _isLoading = true; // Để hiển thị loading khi load data

  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // Load thông tin từ Firestore khi init
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userInfo = await _authService.getUserInfo(user.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi load thông tin: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLogout(BuildContext context) async {
    await _authService.logout(); // Sử dụng _authService (đã import)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _showUpdateInfoDialog() {
    // Controllers cho dialog
    final TextEditingController nameCtrl = TextEditingController(text: _userInfo?['name'] ?? '');
    final TextEditingController phoneCtrl = TextEditingController(text: _userInfo?['phone'] ?? '');
    final TextEditingController oldPassCtrl = TextEditingController();
    final TextEditingController newPassCtrl = TextEditingController();
    final TextEditingController confirmPassCtrl = TextEditingController();
    bool isChangingPass = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tên
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Số điện thoại
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Phân cách mật khẩu
              const Text(
                'Thay đổi mật khẩu (tùy chọn)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: isChangingPass
                ? null
                : () async {
                    // Cập nhật tên và phone trước
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && _userInfo != null) {
                      final collection = (_userInfo!['role'] == 'store') ? 'store' : 'users';
                      await FirebaseFirestore.instance
                          .collection(collection)
                          .doc(user.uid)
                          .update({
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                      });
                    }

                    // Thay đổi mật khẩu nếu nhập
                    if (oldPassCtrl.text.isNotEmpty && newPassCtrl.text.isNotEmpty) {
                      if (newPassCtrl.text != confirmPassCtrl.text) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mật khẩu mới không khớp!')),
                          );
                        }
                        return;
                      }

                      if (newPassCtrl.text.length < 6) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mật khẩu mới phải ít nhất 6 ký tự!')),
                          );
                        }
                        return;
                      }

                      setState(() => isChangingPass = true);

                      try {
                        // Reauthenticate với mật khẩu cũ
                        final credential = EmailAuthProvider.credential(
                          email: user!.email!,
                          password: oldPassCtrl.text.trim(),
                        );
                        await user.reauthenticateWithCredential(credential);

                        // Cập nhật mật khẩu mới
                        await user.updatePassword(newPassCtrl.text.trim());

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã thay đổi mật khẩu thành công!')),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        String errorMsg = 'Lỗi thay đổi mật khẩu: ';
                        switch (e.code) {
                          case 'wrong-password':
                            errorMsg += 'Mật khẩu cũ không đúng.';
                            break;
                          case 'weak-password':
                            errorMsg += 'Mật khẩu mới quá yếu.';
                            break;
                          default:
                            errorMsg += e.message ?? 'Lỗi không xác định.';
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg)),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        }
                      } finally {
                        setState(() => isChangingPass = false);
                      }
                    }

                    // Reload info và đóng dialog
                    await _loadUserInfo();
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật thành công!')),
                      );
                    }
                  },
            child: isChangingPass
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      primaryColor: const Color(0xFF81D4FA), // Xanh nhạt da trời (Blue 200)
      scaffoldBackgroundColor: const Color(0xFFE3F2FD),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF81D4FA), // Xanh nhạt da trời
        foregroundColor: Colors.black87, // Text tối hơn để tương phản tốt
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF81D4FA), // Xanh nhạt da trời
          foregroundColor: Colors.black87, // Text tối hơn
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hồ sơ'),
          // Không có actions logout ở đây, để ở dưới
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Phần 1: Thông tin cá nhân hiển thị cứng với button cập nhật
                    Card(
                      elevation: 4,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Avatar: Logo nhỏ (60px)
                            CircleAvatar(
                              radius: 30, // Nhỏ thôi
                              backgroundColor: const Color(0xFF81D4FA), // Xanh nhạt da trời
                              child: const CircleAvatar(
                                radius: 28,
                                backgroundImage: AssetImage('assets/img/logo.png'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Thông tin cá nhân',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            // Hiển thị tên cứng
                            ListTile(
                              leading: const Icon(Icons.person_outline, color: Color(0xFF81D4FA)), // Xanh nhạt da trời
                              title: const Text('Tên', style: TextStyle(color: Color(0xFF81D4FA))), // Xanh nhạt da trời
                              subtitle: Text(_userInfo?['name'] ?? 'Chưa có thông tin'),
                            ),
                            // Hiển thị số điện thoại cứng
                            ListTile(
                              leading: const Icon(Icons.phone_outlined, color: Color(0xFF81D4FA)), // Xanh nhạt da trời
                              title: const Text('Số điện thoại', style: TextStyle(color: Color(0xFF81D4FA))), // Xanh nhạt da trời
                              subtitle: Text(_userInfo?['phone'] ?? 'Chưa có thông tin'),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _showUpdateInfoDialog,
                                child: const Text('Cập nhật thông tin'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Phần 2: Hoạt động (thay đổi từ Tính năng nâng cao)
                    Card(
                      elevation: 4,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text(
                              'Hoạt động',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: null, // Vô hiệu hóa hiện tại
                                child: const Text('Cài đặt nâng cao'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Phần 3: Button đăng xuất ở dưới
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(Icons.logout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                        ),
                        label: const Text('Đăng xuất'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}