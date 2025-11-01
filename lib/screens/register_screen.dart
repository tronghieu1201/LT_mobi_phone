import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // THÊM: Cho kIsWeb nếu cần
import 'dart:async'; // THÊM: Cho TimeoutException
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Để navigate về Login sau đăng ký
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
  // Bỏ 'String role = 'user';' - mặc định trong AuthService
  bool loading = false;
  final AuthService _auth = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
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
  // _register() - Đảm bảo báo lỗi cho email đã dùng (bao gồm Google/Gmail sign-in)
  // Bỏ fetchSignInMethodsForEmail (đã xóa trong firebase_auth >=6.0), dựa vào exception 'email-already-in-use'
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
    final email = emailCtrl.text.trim();
    if (mounted) {
      setState(() => loading = true);
    }
    try {
      // Gọi registerWithInfo thay vì register (mặc định role 'user')
      final user = await _auth.registerWithInfo(
        nameCtrl.text.trim(),
        phoneCtrl.text.trim(),
        email,
        passCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => loading = false);
      }
      if (user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Đăng ký thành công! Vui lòng đăng nhập."),
              backgroundColor: Colors.green[600], // Màu xanh thành công
            ),
          );
          // Navigate về Login để test
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } else {
        if (mounted) {
          setState(() => loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Lỗi đăng ký, vui lòng thử lại."),
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
        errorMsg = "Email đã tồn tại (có thể từ Google/Gmail hoặc đăng ký trước). Vui lòng đăng nhập hoặc dùng email khác.";
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
  // FIX: _googleRegister() - Bỏ delay cho web (fix COOP popup block), show SnackBar NGAY, wrap try-catch riêng cho navigate
  void _googleRegister() async {
    print('🔄 Bắt đầu Google Register...'); // Debug: Bắt đầu
    if (mounted) setState(() => loading = true);
    try {
      // Thêm timeout cho googleSignIn để tránh treo
      final roleOrError = await _auth.googleSignIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Google Sign-In timeout', const Duration(seconds: 30));
        },
      );
      print('📝 Google Sign-In trả về: $roleOrError'); // Debug: Role hoặc error
      if (roleOrError != null && roleOrError != 'null') {
        if (roleOrError.startsWith('Lỗi')) {
          print('❌ Google Register error: $roleOrError'); // Debug error
          if (mounted) {
            setState(() => loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(roleOrError),
                backgroundColor: Colors.red[600],
              ),
            );
          }
          return;
        }
        // Role hợp lệ: Thành công, tắt loading và show SnackBar NGAY (không delay cho web)
        print('✅ Google Register thành công, role: $roleOrError'); // Debug success
        if (mounted) {
          setState(() => loading = false); // Tắt loading NGAY
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Đăng ký thành công! Vui lòng đăng nhập."),
              backgroundColor: Colors.green[600], // Màu xanh thành công
            ),
          );
          // Delay chỉ cho mobile (kIsWeb), bỏ cho web để tránh COOP issue
          if (!kIsWeb) {
            await Future.delayed(const Duration(milliseconds: 500)); // Chỉ delay mobile để chờ popup close
          }
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        }
      } else {
        // Nếu null, coi như fail
        print('❌ Google Register null response');
        if (mounted) {
          setState(() => loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Không nhận được phản hồi từ Google, vui lòng thử lại."),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      }
    } on TimeoutException catch (e) {
      print('❌ Google Register timeout: $e');
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In timeout: ${e.message}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi Google Register: $e');
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng ký Google: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              // Logo và tiêu đề - GIỮ NGUYÊN
              const SizedBox(height: 50),
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/img/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Đăng ký",
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: vietnamRed), // Tiêu đề màu ĐỎ cờ
              ),
              const SizedBox(height: 30),
              Form(
                child: Column(
                  children: [
                    // TextField Tên - GIỮ NGUYÊN
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
                    // TextField Số điện thoại - GIỮ NGUYÊN
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
                    // Nút Đăng ký email/password - GIỮ NGUYÊN
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
                    // Nút Đăng ký bằng Google - GIỮ NGUYÊN
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : _googleRegister,
                        icon: Image.asset('assets/img/google_logo.png', height: 24, width: 24), // Icon Google
                        label: Text('Google', style: TextStyle(fontSize: 16, color: vietnamRed)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: vietnamYellow),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Link về Login - GIỮ NGUYÊN
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                icon: SizedBox(
                  width: 20,
                  height: 20,
                  child: Image.asset(
                    'assets/img/VietNam.png',
                    fit: BoxFit.contain,
                  ),
                ),
                label: Text("Đăng nhập", style: TextStyle(color: vietnamRed)),
                style: TextButton.styleFrom(foregroundColor: vietnamRed),
              ),
            ],
          ),
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