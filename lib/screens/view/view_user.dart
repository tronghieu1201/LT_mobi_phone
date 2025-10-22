import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Cho format date
import '../../services/auth_service.dart';
import '../login_screen.dart';

class ViewUser extends StatefulWidget {
  const ViewUser({super.key});

  @override
  State<ViewUser> createState() => _ViewUserState();
}

class _ViewUserState extends State<ViewUser> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color darkTextColor = Colors.black87;
  static Color lightTextColor = Colors.white;
  static Color backgroundColor = Colors.grey[50]!;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
    await _authService.logout();
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Cập nhật thông tin',
            style: TextStyle(color: vietnamRed)),
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
                    color: vietnamRed),
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
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy', style: TextStyle(color: vietnamRed)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Logic update (bạn có thể expand sau)
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: vietnamRed),
            child: Text('Cập nhật', style: TextStyle(color: lightTextColor)),
          ),
        ],
      ),
    );
  }

  // Hiển thị lịch sử tìm kiếm từ Firebase
  void _showHistoryDialog() {
    final List<dynamic> historyList = List.from(_userInfo?['history'] ?? []);
    if (historyList.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lịch sử tìm kiếm', style: TextStyle(color: vietnamRed)),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                height: 20,
                child: Image.asset('assets/img/VietNam.png', fit: BoxFit.contain),
              ),
            ],
          ),
          content: const Text('Chưa có lịch sử tìm kiếm nào. Hãy thử tìm kiếm món ăn/uống!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng', style: TextStyle(color: vietnamRed)),
            ),
          ],
        ),
      );
      return;
    }

    // Sắp xếp theo timestamp descending (mới nhất trước)
    historyList.sort((a, b) {
      DateTime? timeA, timeB;
      if (a['timestamp'] is Timestamp) {
        timeA = (a['timestamp'] as Timestamp).toDate();
      } else if (a['timestamp'] is DateTime) {
        timeA = a['timestamp'] as DateTime;
      }
      if (b['timestamp'] is Timestamp) {
        timeB = (b['timestamp'] as Timestamp).toDate();
      } else if (b['timestamp'] is DateTime) {
        timeB = b['timestamp'] as DateTime;
      }
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA);
    });

    final limitedHistory = List<dynamic>.from(historyList.take(50)); // Copy list để modify local

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(  // Sử dụng StatefulBuilder để rebuild dialog
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lịch sử tìm kiếm', style: TextStyle(color: vietnamRed)),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                height: 20,
                child: Image.asset('assets/img/VietNam.png', fit: BoxFit.contain),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: limitedHistory.length,
              itemBuilder: (context, index) {
                final entry = limitedHistory[index] as Map<String, dynamic>;
                final name = entry['name'] ?? 'Không xác định';
                final timestampObj = entry['timestamp'];
                DateTime? timestamp;
                if (timestampObj is Timestamp) {
                  timestamp = timestampObj.toDate();
                } else if (timestampObj is DateTime) {
                  timestamp = timestampObj;
                }
                final formattedTime = timestamp != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp)
                    : 'Không xác định';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.grey[100],
                  child: ListTile(
                    leading: Icon(Icons.history, color: vietnamYellow, size: 24),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: vietnamRed,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      formattedTime,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.clear, color: vietnamRed),
                      onPressed: () async {
                        // Local update trước để mượt (xóa ngay lập tức trên UI)
                        setDialogState(() {
                          limitedHistory.removeAt(index);
                        });

                        // Update Firestore
                        await _deleteHistoryItemFromFirestore(limitedHistory);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Đóng', style: TextStyle(color: vietnamRed)),
            ),
          ],
        ),
      ),
    );
  }

  // Xóa item từ Firestore và reload local data (gọi sau local update)
  Future<void> _deleteHistoryItemFromFirestore(List<dynamic> updatedHistory) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'history': updatedHistory});
      await _loadUserInfo(); // Reload toàn bộ để sync
      print('✅ Đã xóa lịch sử thành công');
    } catch (e) {
      print('Error deleting history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa: $e'), backgroundColor: vietnamRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hồ sơ',
                style:
                    TextStyle(color: vietnamRed)),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: vietnamRed),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: vietnamRed))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Phần 1: Thông tin cá nhân
                  Card(
                    elevation: 4,
                    color: Colors.white,
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
                                vietnamYellow,
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
                          // Hiển thị tên
                          ListTile(
                            leading: Icon(Icons.person_outline,
                                color: vietnamYellow),
                            title: Text('Tên',
                                style: TextStyle(
                                    color:
                                        Colors.grey[600])),
                            subtitle: Text(_userInfo?['name'] ?? 'Chưa có thông tin',
                                style: TextStyle(
                                    color: vietnamRed,
                                    fontSize:
                                        16)),
                          ),
                          // Hiển thị số điện thoại
                          ListTile(
                            leading: Icon(Icons.phone_outlined,
                                color: vietnamYellow),
                            title: Text('Số điện thoại',
                                style: TextStyle(
                                    color:
                                        Colors.grey[600])),
                            subtitle: Text(
                                _userInfo?['phone'] ?? 'Chưa có thông tin',
                                style: TextStyle(
                                    color: vietnamRed,
                                    fontSize:
                                        16)),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _showUpdateInfoDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: vietnamRed,
                                foregroundColor: lightTextColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Cập nhật thông tin',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Phần 2: Hoạt động (lịch sử tìm kiếm)
                  Card(
                    elevation: 4,
                    color: Colors.white,
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
                            child: ElevatedButton.icon(
                              onPressed: _showHistoryDialog,
                              icon: Icon(Icons.history, color: lightTextColor),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: vietnamYellow,
                                foregroundColor: darkTextColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              label: const Text('Hoạt động (Lịch sử tìm kiếm)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }
}