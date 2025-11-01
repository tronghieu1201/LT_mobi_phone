// Updated home_admin.dart - Removed the "Quản lý search" button
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'manage/manage_users.dart';
import '../screens/view/view_admin_product/view_ad_home.dart'; // New import

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  bool _isLoggedIn = false; // Khởi tạo false để tránh flash loading không cần thiết
  bool _isChecking = true; // Thêm flag để hiển thị loading trong lúc check

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final isLoggedIn = token != null && token.isNotEmpty;

      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isChecking = false;
        });

        if (!isLoggedIn) {
          // Delay nhẹ để tránh flash, nhưng không cần thiết lắm
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        }
      }
    } catch (e) {
      // Xử lý lỗi nếu SharedPreferences fail (hiếm trên web)
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isChecking = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final auth = AuthService();
      await auth.logout(); // Giả sử AuthService.logout() clear Firebase session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token'); // Xóa token local
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Fallback nếu lỗi
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
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
    if (_isChecking) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator(color: vietnamRed)),
      );
    }

    if (!_isLoggedIn) {
      return const SizedBox.shrink(); // Tránh render không cần thiết, navigator sẽ handle
    }

    return Scaffold(
      backgroundColor: backgroundColor, // Nền xám rất nhạt
      appBar: AppBar(
        title: Text(
          "", // Empty title
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 15), // Giảm khoảng trống trên để đưa lá cờ lên cao hơn (từ 20 xuống 15)
            // Lá cờ lớn ở giữa, với hiệu ứng gợn sóng như đang bay
            Center(
              child: WavingFlag(
                imagePath: 'assets/img/VietNam.png',
                width: 250, // Thu nhỏ kích thước lá cờ
                height: 167, // Tỷ lệ 3:2 cho cờ Việt Nam
              ),
            ),
            const SizedBox(height: 30), // Giảm khoảng trống dưới lá cờ
            const Spacer(flex: 2), // Đẩy card xuống dưới
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
                  mainAxisSize: MainAxisSize.min, // Tối ưu kích thước card
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ViewAdHomeScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // Nền trắng
                          foregroundColor: vietnamRed, // Chữ màu đỏ
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: vietnamYellow, width: 2), // Viền vàng
                          ),
                          elevation: 3,
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text('Quản lý home', style: const TextStyle(color: vietnamRed)),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                          backgroundColor: Colors.white, // Nền trắng
                          foregroundColor: vietnamRed, // Chữ màu đỏ
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: vietnamYellow, width: 2), // Viền vàng
                          ),
                          elevation: 3,
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text('Quản lý user', style: const TextStyle(color: vietnamRed)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: vietnamRed), // Thay icon cờ bằng icon logout mặc định
                label: Text("Đăng xuất",
                    style: TextStyle(color: vietnamRed)), // Chữ màu ĐỎ cờ
                style: TextButton.styleFrom(
                    foregroundColor: vietnamRed), // Màu chữ khi nhấn
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ... (Keep the WavingFlag, _WavingFlagState, FlagPainter classes unchanged)
class WavingFlag extends StatefulWidget {
  final double width;
  final double height;
  final String imagePath;

  const WavingFlag({
    super.key,
    required this.imagePath,
    this.width = 250,
    this.height = 167,
  });

  @override
  State<WavingFlag> createState() => _WavingFlagState();
}

class _WavingFlagState extends State<WavingFlag> with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController _controller;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _loadImage();
  }

  Future<void> _loadImage() async {
    final ByteData data = await rootBundle.load(widget.imagePath);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _image = fi.image;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return CustomPaint(
      painter: FlagPainter(_image!, animation.value, widget.width, widget.height),
      size: Size(widget.width, widget.height),
    );
  }
}

class FlagPainter extends CustomPainter {
  final ui.Image image;
  final double wavePhase;
  final double width;
  final double height;

  FlagPainter(this.image, this.wavePhase, this.width, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    _paintWaveEffect(canvas, size);
  }

  void _paintWaveEffect(Canvas canvas, Size size) {
    final Path path = Path();
    final int waveCount = 3;
    final double amplitude = size.height * 0.08;
    final double effectiveHeight = size.height;
    final double yOffset = 0;

    // Bottom edge (inverted for starting from bottom left)
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2.0) {
      double normalizedX = x / size.width;
      double y = size.height - yOffset - math.sin(normalizedX * waveCount * math.pi * 2 + wavePhase + math.pi) * amplitude;
      path.lineTo(x, y);
    }
    // Top right corner
    path.lineTo(size.width, yOffset);
    // Top edge
    for (double x = size.width; x >= 0; x -= 2.0) {
      double normalizedX = x / size.width;
      double y = yOffset + math.sin(normalizedX * waveCount * math.pi * 2 + wavePhase) * amplitude;
      path.lineTo(x, y);
    }
    path.close();

    canvas.clipPath(path);

    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: image,
      fit: BoxFit.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}