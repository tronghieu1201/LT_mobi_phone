import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  String role = 'user';
  bool loading = false;

  final AuthService _auth = AuthService();

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

  void _register() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vui lòng nhập đầy đủ thông tin'),
            backgroundColor: Colors.red[600], // Màu đỏ cảnh báo
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final result = await _auth.register(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        role: role,
      );

      if (mounted) {
        setState(() => loading = false);
      }

      if (result == "success") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Đăng ký thành công"),
              backgroundColor: Colors.green[600], // Màu xanh thành công
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result ?? "Lỗi không xác định"),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }
      String errorMsg = "Lỗi đăng ký: ${e.message}";
      if (e.code == 'email-already-in-use') {
        errorMsg = "Email đã tồn tại, hãy đăng nhập hoặc dùng email khác.";
      } else if (e.code == 'weak-password') {
        errorMsg = "Mật khẩu quá yếu, hãy dùng mật khẩu mạnh hơn.";
      } else if (e.code == 'invalid-email') {
        errorMsg = "Email không hợp lệ.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi không xác định: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Nền xám rất nhạt
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.transparent, // Nền AppBar trong suốt
        elevation: 0,
        iconTheme: IconThemeData(color: vietnamRed), // Nút back (nếu có) màu đỏ
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Hình ảnh đại diện khi vào app
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Bóng đen mờ
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/img/1.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Xin chào quý khách với icon cờ Việt Nam (căn giữa)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Đăng ký tài khoản",
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
            const SizedBox(height: 30),

            // Form trong Card
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
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: darkTextColor), // Chữ đen
                      decoration: InputDecoration(
                        labelText: 'Tên',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.person_outline,
                            color: vietnamYellow), // Icon màu VÀNG
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: vietnamRed, width: 2.0), // Viền focus màu ĐỎ
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: darkTextColor), // Chữ đen
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.phone_outlined,
                            color: vietnamYellow), // Icon màu VÀNG
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: vietnamRed, width: 2.0), // Viền focus màu ĐỎ
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: darkTextColor), // Chữ đen
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: vietnamYellow), // Icon màu VÀNG
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: vietnamRed, width: 2.0), // Viền focus màu ĐỎ
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      style: TextStyle(color: darkTextColor), // Chữ đen
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: vietnamYellow), // Icon màu VÀNG
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: vietnamRed, width: 2.0), // Viền focus màu ĐỎ
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vietnamRed, // Nút màu ĐỎ cờ
                          foregroundColor: lightTextColor, // Chữ TRẮNG
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                        ),
                        child: loading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: lightTextColor,
                                    strokeWidth: 2), // Loading TRẮNG
                              )
                            : Text('Đăng ký',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: lightTextColor)), // Chữ TRẮNG
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }
}