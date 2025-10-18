import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'view/view_search.dart';
import 'view/view_food.dart';
import 'view/view_drink.dart';
import 'view/view_user.dart';
import 'dart:async'; // Cho Timer auto-scroll

class HomeUserScreen extends StatefulWidget {
  const HomeUserScreen({Key? key}) : super(key: key);

  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  String _mapEmbedUrl = '';
  static const LatLng _defaultPosition = LatLng(21.0278, 105.8342);
  LatLng? _currentPosition;

  // --- Bảng màu Cờ Đỏ Sao Vàng (ĐÃ CHUẨN) ---
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color darkTextColor = Colors.black87;
  static Color lightTextColor = Colors.white;
  static Color backgroundColor = Colors.grey[50]!;

  // (Giữ nguyên phần định nghĩa các list vouchers, controllers, timers...)
  // Auto-scroll cho vouchers
  final List<String> _voucherImages = [
    'assets/img/ss1.jpg',
    'assets/img/ss2.jpg',
    'assets/img/ss3.jpg',
  ];
  final PageController _voucherController = PageController();
  int _currentVoucherIndex = 0;
  Timer? _voucherTimer;

  // Auto-scroll cho buổi sáng
  final List<String> _morningImages = [
    'assets/img/sang2.jpg',
    'assets/img/sang3.jpg',
    'assets/img/sang4.jpg',
  ];
  final PageController _morningController = PageController();
  int _currentMorningIndex = 0;
  Timer? _morningTimer;

  // Auto-scroll cho buổi trưa
  final List<String> _afternoonImages = [
    'assets/img/trua1.jpg',
    'assets/img/trua2.jpg',
    'assets/img/trua3.jpg',
  ];
  final PageController _afternoonController = PageController();
  int _currentAfternoonIndex = 0;
  Timer? _afternoonTimer;

  // Auto-scroll cho buổi tối
  final List<String> _eveningImages = [
    'assets/img/toi1.jpg',
    'assets/img/toi2.jpg',
    'assets/img/toi3.jpg',
  ];
  final PageController _eveningController = PageController();
  int _currentEveningIndex = 0;
  Timer? _eveningTimer;
  // (Phần logic giữ nguyên)

  void _handleLogout(BuildContext context) async {
    final auth = AuthService();
    await auth.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showQRDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = screenWidth > 600 ? 250.0 : 200.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: qrSize,
                height: qrSize,
                decoration: BoxDecoration(
                  border: Border.all(color: vietnamYellow, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: vietnamYellow.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/img/qr.jpg', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quét mã QR để truy cập nhanh',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng', style: TextStyle(color: vietnamRed)),
            ),
          ],
        );
      },
    );
  }

  void _showDevelopingSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tính năng đang phát triển'),
          backgroundColor: vietnamRed,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    if (kIsWeb) {
      try {
        ui.platformViewRegistry.registerViewFactory(
          'small-google-maps-iframe',
          (int viewId) {
            final iframe = html.IFrameElement()
              ..width = '100%'
              ..height = '100%'
              ..src = _mapEmbedUrl.isNotEmpty
                  ? _mapEmbedUrl
                  : _generateEmbedUrl(
                      _defaultPosition.latitude, _defaultPosition.longitude)
              ..style.border = 'none'
              ..allowFullscreen = true
              ..allow = 'geolocation; microphone; camera';
            return iframe;
          },
        );
      } catch (e) {
        debugPrint('Lỗi register small iframe: $e');
      }
    }

    // Timer auto-scroll cho vouchers (2s mỗi hình)
    _voucherTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _currentVoucherIndex =
            (_currentVoucherIndex + 1) % _voucherImages.length;
        _voucherController.animateToPage(
          _currentVoucherIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    // Timer cho buổi sáng (delay 0.5s để không đồng bộ)
    Timer(const Duration(milliseconds: 500), () {
      _morningTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          _currentMorningIndex =
              (_currentMorningIndex + 1) % _morningImages.length;
          _morningController.animateToPage(
            _currentMorningIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    });

    // Timer cho buổi trưa (delay 1s)
    Timer(const Duration(seconds: 1), () {
      _afternoonTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          _currentAfternoonIndex =
              (_currentAfternoonIndex + 1) % _afternoonImages.length;
          _afternoonController.animateToPage(
            _currentAfternoonIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    });

    // Timer cho buổi tối (delay 1.5s)
    Timer(const Duration(milliseconds: 1500), () {
      _eveningTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          _currentEveningIndex =
              (_currentEveningIndex + 1) % _eveningImages.length;
          _eveningController.animateToPage(
            _currentEveningIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _voucherTimer?.cancel();
    _morningTimer?.cancel();
    _afternoonTimer?.cancel();
    _eveningTimer?.cancel();
    _voucherController.dispose();
    _morningController.dispose();
    _afternoonController.dispose();
    _eveningController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Bật GPS để lấy vị trí chính xác');
        _setDefaultMap();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Cần quyền vị trí để cập nhật map');
          _setDefaultMap();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _updateMapUrl(_currentPosition!.latitude, _currentPosition!.longitude);
      _showSnackBar('Đã cập nhật vị trí của bạn');
    } catch (e) {
      debugPrint('Lỗi lấy vị trí: $e');
      _showSnackBar('Sử dụng vị trí mặc định do lỗi: $e');
      _setDefaultMap();
    }
  }

  void _updateMapUrl(double lat, double lng) {
    _mapEmbedUrl =
        'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed';
    if (kIsWeb && mounted) {
      ui.platformViewRegistry.registerViewFactory(
        'small-google-maps-iframe',
        (int viewId) {
          final iframe = html.IFrameElement()
            ..width = '100%'
            ..height = '100%'
            ..src = _mapEmbedUrl
            ..style.border = 'none'
            ..allowFullscreen = true
            ..allow = 'geolocation; microphone; camera';
          return iframe;
        },
      );
      setState(() {});
    }
  }

  void _setDefaultMap() {
    _updateMapUrl(_defaultPosition.latitude, _defaultPosition.longitude);
    _currentPosition = _defaultPosition;
  }

  String _generateEmbedUrl(double lat, double lng) {
    return 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed';
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: vietnamRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme màu Việt Nam (Đã đúng)
    final theme = Theme.of(context).copyWith(
      primaryColor: vietnamYellow,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: vietnamRed),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(toolbarHeight: 0),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Top row (Đã đúng: icons màu vàng)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 40, 12, 16),
                child: Column(
                  children: [
                    // Icon cờ Việt Nam ở đầu trang, căn giữa
                    Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Image.asset(
                          'assets/img/VietNam.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Row các nút
                    Row(
                      children: [
                        // Nút QR nhỏ gọn
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            onPressed: () => _showQRDialog(context),
                            icon: const Icon(Icons.qr_code_scanner,
                                size: 24, color: vietnamYellow),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.zero,
                              elevation: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Ô tìm kiếm
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewSearch(
                                        currentPosition: _currentPosition),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.search,
                                  color: vietnamYellow, size: 20),
                              label: const Text(
                                'Tìm kiếm...',
                                style: TextStyle(color: Colors.grey),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Nút hồ sơ
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ViewUser()),
                              );
                            },
                            icon: const Icon(Icons.person,
                                size: 22, color: vietnamYellow),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.zero,
                              elevation: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bản đồ
              if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: vietnamYellow.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: vietnamYellow.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _mapEmbedUrl.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(color: vietnamRed))
                          : const HtmlElementView(
                              viewType: 'small-google-maps-iframe'),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: vietnamYellow.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text('Bản đồ chỉ hỗ trợ trên web',
                          style: TextStyle(
                              color: vietnamYellow.withOpacity(0.8))),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Các button category (Gọi hàm _buildCategoryButton đã sửa ở dưới)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildCategoryButton(
                      'Đồ ăn',
                      Icons.restaurant,
                      vietnamYellow,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ViewFood(currentPosition: _currentPosition),
                        ),
                      ),
                    ),
                    _buildCategoryButton(
                      'Đi chợ',
                      Icons.shopping_cart,
                      vietnamYellow,
                      _showDevelopingSnackBar,
                    ),
                    _buildCategoryButton(
                      'Đồ uống',
                      Icons.local_drink,
                      vietnamYellow,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ViewDrink(currentPosition: _currentPosition),
                        ),
                      ),
                    ),
                    _buildCategoryButton(
                      'Giao hàng',
                      Icons.delivery_dining,
                      vietnamYellow,
                      _showDevelopingSnackBar,
                    ),
                    _buildCategoryButton(
                      'Tin nhắn',
                      Icons.message,
                      vietnamYellow,
                      _showDevelopingSnackBar,
                    ),
                    _buildCategoryButton(
                      'Tính cách của bạn',
                      Icons.psychology,
                      vietnamYellow,
                      _showDevelopingSnackBar,
                    ),
                    _buildCategoryButton(
                      'Ưu ái',
                      Icons.favorite,
                      vietnamYellow,
                      _showDevelopingSnackBar,
                    ),
                    _buildCategoryButton(
                      'Mua nợ',
                      Icons.payment,
                      vietnamYellow,
                      _showDevelopingSnackBar,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Section Khuyến mãi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Khuyến mãi',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: vietnamRed)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200, // TĂNG chiều cao từ 150 lên 200 để hình rõ ràng hơn
                      child: PageView.builder(
                        controller: _voucherController,
                        itemCount: _voucherImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0), // GIẢM padding ngang từ 8 xuống 4 để gọn gàng hơn
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12), // TĂNG border radius nhẹ để bo góc đẹp hơn
                              child: Image.asset(
                                _voucherImages[index],
                                fit: BoxFit.cover, // Giữ cover để lấp đầy mà không méo
                                width: double.infinity,
                                height: double.infinity, // Đảm bảo lấp đầy chiều cao
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Indicators (GIẢM kích thước indicator để gọn hơn)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          _voucherImages.length,
                          (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: _currentVoucherIndex == index ? 6 : 4, // GIẢM từ 8/6 xuống 6/4
                                height: 4, // GIẢM từ 6 xuống 4
                                decoration: BoxDecoration(
                                  color: _currentVoucherIndex == index
                                      ? vietnamRed
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(2), // GIẢM radius cho gọn
                                ),
                              )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Section Combo gợi ý
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Combo gợi ý',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: vietnamRed)),
                    const SizedBox(height: 16),
                    // Buổi sáng
                    Text('Buổi sáng',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkTextColor)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200, // TĂNG chiều cao từ 150 lên 200 để hình rõ ràng hơn
                      child: PageView.builder(
                        controller: _morningController,
                        itemCount: _morningImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0), // GIẢM padding ngang từ 8 xuống 4 để gọn gàng hơn
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12), // TĂNG border radius nhẹ để bo góc đẹp hơn
                              child: Image.asset(
                                _morningImages[index],
                                fit: BoxFit.cover, // Giữ cover để lấp đầy mà không méo
                                width: double.infinity,
                                height: double.infinity, // Đảm bảo lấp đầy chiều cao
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          _morningImages.length,
                          (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: _currentMorningIndex == index ? 6 : 4, // GIẢM từ 8/6 xuống 6/4
                                height: 4, // GIẢM từ 6 xuống 4
                                decoration: BoxDecoration(
                                  color: _currentMorningIndex == index
                                      ? vietnamRed
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(2), // GIẢM radius cho gọn
                                ),
                              )),
                    ),
                    const SizedBox(height: 16),
                    // Buổi trưa
                    Text('Buổi trưa',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkTextColor)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200, // TĂNG chiều cao từ 150 lên 200 để hình rõ ràng hơn
                      child: PageView.builder(
                        controller: _afternoonController,
                        itemCount: _afternoonImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0), // GIẢM padding ngang từ 8 xuống 4 để gọn gàng hơn
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12), // TĂNG border radius nhẹ để bo góc đẹp hơn
                              child: Image.asset(
                                _afternoonImages[index],
                                fit: BoxFit.cover, // Giữ cover để lấp đầy mà không méo
                                width: double.infinity,
                                height: double.infinity, // Đảm bảo lấp đầy chiều cao
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          _afternoonImages.length,
                          (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: _currentAfternoonIndex == index ? 6 : 4, // GIẢM từ 8/6 xuống 6/4
                                height: 4, // GIẢM từ 6 xuống 4
                                decoration: BoxDecoration(
                                  color: _currentAfternoonIndex == index
                                      ? vietnamRed
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(2), // GIẢM radius cho gọn
                                ),
                              )),
                    ),
                    const SizedBox(height: 16),
                    // Buổi tối
                    Text('Buổi tối',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkTextColor)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200, // TĂNG chiều cao từ 150 lên 200 để hình rõ ràng hơn
                      child: PageView.builder(
                        controller: _eveningController,
                        itemCount: _eveningImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0), // GIẢM padding ngang từ 8 xuống 4 để gọn gàng hơn
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12), // TĂNG border radius nhẹ để bo góc đẹp hơn
                              child: Image.asset(
                                _eveningImages[index],
                                fit: BoxFit.cover, // Giữ cover để lấp đầy mà không méo
                                width: double.infinity,
                                height: double.infinity, // Đảm bảo lấp đầy chiều cao
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          _eveningImages.length,
                          (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: _currentEveningIndex == index ? 6 : 4, // GIẢM từ 8/6 xuống 6/4
                                height: 4, // GIẢM từ 6 xuống 4
                                decoration: BoxDecoration(
                                  color: _currentEveningIndex == index
                                      ? vietnamRed
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(2), // GIẢM radius cho gọn
                                ),
                              )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        // Chat bot button (Đã đúng: Vàng + icon đen)
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showChatBotDialog(context);
          },
          backgroundColor: vietnamYellow,
          child: const Icon(Icons.chat_bubble, color: Colors.black87),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // Dialog cho chat bot "Tâm sự"
  void _showChatBotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tâm sự với Chat Bot',
            style: TextStyle(color: vietnamRed)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Chào bạn! Tôi là chat bot của Doan Mobi. Bạn muốn tâm sự gì hôm nay?'),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn của bạn...',
                border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: vietnamYellow.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: vietnamYellow,
                        width: 2.0)),
              ),
              onSubmitted: (value) {
                Navigator.of(context).pop(); // Đóng dialog tạm thời
                // Có thể mở full chat screen sau
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng', style: TextStyle(color: vietnamRed)),
          ),
        ],
      ),
    );
  }

  // Helper build category button
  Widget _buildCategoryButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: vietnamYellow.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: darkTextColor,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}