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

  // --- Bảng màu Cờ Đỏ Sao Vàng --- (Đã đúng)
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color darkTextColor = Colors.black87;
  static Color lightTextColor = Colors.white;
  static Color backgroundColor = Colors.grey[50]!;

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
        // Đảm bảo history được khởi tạo nếu chưa có
        if (_userInfo != null && !_userInfo!.containsKey('history')) {
          _userInfo!['history'] = [];
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi load thông tin: $e'),
              backgroundColor: vietnamRed),
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
    final TextEditingController nameCtrl =
        TextEditingController(text: _userInfo?['name'] ?? '');
    final TextEditingController phoneCtrl =
        TextEditingController(text: _userInfo?['phone'] ?? '');
    final TextEditingController oldPassCtrl = TextEditingController();
    final TextEditingController newPassCtrl = TextEditingController();
    final TextEditingController confirmPassCtrl = TextEditingController();
    bool isChangingPass = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Cập nhật thông tin',
            style: TextStyle(color: vietnamRed)), // SỬA: Tiêu đề màu ĐỎ
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tên
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: darkTextColor),
                decoration: InputDecoration(
                  labelText: 'Tên',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon:
                      const Icon(Icons.person_outline, color: vietnamYellow),
                  border: const OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(10))),
                  focusedBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: vietnamRed, width: 2.0),
                          borderRadius: BorderRadius.circular(10)),
                  enabledBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              // Số điện thoại
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: darkTextColor),
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon:
                      const Icon(Icons.phone_outlined, color: vietnamYellow),
                  border: const OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(10))),
                  focusedBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: vietnamRed, width: 2.0),
                          borderRadius: BorderRadius.circular(10)),
                  enabledBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              // Phân cách mật khẩu
              Text(
                'Thay đổi mật khẩu (tùy chọn)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: vietnamRed), // SỬA: Màu ĐỎ
              ),
              const SizedBox(height: 8),
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                style: TextStyle(color: darkTextColor),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: vietnamYellow),
                  border: const OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(10))),
                  focusedBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: vietnamRed, width: 2.0),
                          borderRadius: BorderRadius.circular(10)),
                  enabledBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                style: TextStyle(color: darkTextColor),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: vietnamYellow),
                  border: const OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(10))),
                  focusedBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: vietnamRed, width: 2.0),
                          borderRadius: BorderRadius.circular(10)),
                  enabledBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                style: TextStyle(color: darkTextColor),
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: vietnamYellow),
                  border: const OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(10))),
                  focusedBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: vietnamRed, width: 2.0),
                          borderRadius: BorderRadius.circular(10)),
                  enabledBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy',
                style: TextStyle(color: vietnamRed)), // SỬA: Thêm style
          ),
          ElevatedButton(
            onPressed: isChangingPass
                ? null
                : () async {
                    // Cập nhật tên và phone trước
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && _userInfo != null) {
                      final collection =
                          (_userInfo!['role'] == 'store') ? 'store' : 'users';
                      await FirebaseFirestore.instance
                          .collection(collection)
                          .doc(user.uid)
                          .update({
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                      });
                    }

                    // Thay đổi mật khẩu nếu nhập
                    if (oldPassCtrl.text.isNotEmpty &&
                        newPassCtrl.text.isNotEmpty) {
                      if (newPassCtrl.text != confirmPassCtrl.text) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Mật khẩu mới không khớp!'),
                                backgroundColor: vietnamRed),
                          );
                        }
                        return;
                      }

                      if (newPassCtrl.text.length < 6) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Mật khẩu mới phải ít nhất 6 ký tự!'),
                                backgroundColor: vietnamRed),
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
                            // SỬA: SnackBar thành công
                            SnackBar(
                                content: Text('Đã thay đổi mật khẩu thành công!',
                                    style: TextStyle(color: darkTextColor)),
                                backgroundColor: vietnamYellow),
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
                            SnackBar(
                                content: Text(errorMsg),
                                backgroundColor: vietnamRed),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Lỗi: $e'),
                                backgroundColor: vietnamRed),
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
                        // SỬA: SnackBar thành công
                        SnackBar(
                            content: Text('Cập nhật thành công!',
                                style: TextStyle(color: darkTextColor)),
                            backgroundColor: vietnamYellow),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: vietnamRed,
              foregroundColor: lightTextColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 3,
            ),
            child: isChangingPass
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: lightTextColor,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Cập nhật', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    final List<dynamic> history = _userInfo?['history'] ?? [];
    // Sắp xếp lịch sử theo thời gian mới nhất trước (nếu timestamp là Timestamp)
    final sortedHistory = history
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
      ..sort((a, b) {
        final timeA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        final timeB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        return timeB.compareTo(timeA); // Mới nhất trước
      });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Lịch sử tìm kiếm',
          style: TextStyle(color: vietnamRed),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: sortedHistory.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có lịch sử tìm kiếm.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: sortedHistory.length,
                  itemBuilder: (context, index) {
                    final item = sortedHistory[index];
                    final name = item['name'] ?? item.toString();
                    final timestamp = item['timestamp'];
                    String formattedTime = '';
                    if (timestamp is Timestamp) {
                      final dateTime = timestamp.toDate();
                      formattedTime = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                    } else if (timestamp != null) {
                      formattedTime = timestamp.toString();
                    }
                    return ListTile(
                      leading: const Icon(Icons.history, color: vietnamYellow),
                      title: Text(
                        name,
                        style: const TextStyle(color: vietnamRed),
                      ),
                      subtitle: Text(
                        formattedTime,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đóng',
              style: TextStyle(color: vietnamRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      primaryColor: vietnamRed,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Nền AppBar trong suốt
        elevation: 0,
        iconTheme: IconThemeData(color: vietnamRed),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vietnamRed, // Đỏ
          foregroundColor: lightTextColor, // Text trắng
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 3,
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hồ sơ',
                  style:
                      TextStyle(color: vietnamRed)), // (Đã đúng: Tiêu đề đỏ)
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
          // Không có actions logout ở đây, để ở dưới
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                    color: vietnamRed)) // SỬA: Loading màu ĐỎ
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Phần 1: Thông tin cá nhân
                    Card(
                      elevation: 4,
                      color: Colors.white, // Card nền trắng tinh
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  vietnamYellow, // (Đã đúng: Nền vàng)
                              child: const CircleAvatar(
                                radius: 28,
                                backgroundImage:
                                    AssetImage('assets/img/logo.png'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Thông tin cá nhân',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold,
                                  color: vietnamRed),
                            ),
                            const SizedBox(height: 16),
                            // Hiển thị tên cứng
                            ListTile(
                              leading: Icon(Icons.person_outline,
                                  color: vietnamYellow), // (Đã đúng: Icon vàng)
                              title: Text('Tên',
                                  style: TextStyle(
                                      color:
                                          Colors.grey[600])), // SỬA: Chữ xám
                              subtitle: Text(_userInfo?['name'] ?? 'Chưa có thông tin',
                                  style: TextStyle(
                                      color: vietnamRed,
                                      fontSize:
                                          16)), // SỬA: Chữ đỏ, to hơn
                            ),
                            // Hiển thị số điện thoại cứng
                            ListTile(
                              leading: Icon(Icons.phone_outlined,
                                  color: vietnamYellow), // (Đã đúng: Icon vàng)
                              title: Text('Số điện thoại',
                                  style: TextStyle(
                                      color:
                                          Colors.grey[600])), // SỬA: Chữ xám
                              subtitle: Text(
                                  _userInfo?['phone'] ?? 'Chưa có thông tin',
                                  style: TextStyle(
                                      color: vietnamRed,
                                      fontSize:
                                          16)), // SỬA: Chữ đỏ, to hơn
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _showUpdateInfoDialog,
                                child: const Text('Cập nhật thông tin',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Phần 2: Hoạt động
                    Card(
                      elevation: 4,
                      color: Colors.white, // Card nền trắng tinh
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _showHistoryDialog,
                                child: const Text('Hoạt động',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Phần 3: Button đăng xuất
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vietnamRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                        ),
                        label: const Text('Đăng xuất',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}