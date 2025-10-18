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

  // Auto-scroll cho vouchers
  final List<String> _voucherImages = [
    'assets/img/voucher1.png',
    'assets/img/voucher2.jpg',
    'assets/img/voucher3.jpg',
    'assets/img/voucher4.jpg',
    'assets/img/voucher5.jpg',
  ];
  final PageController _voucherController = PageController();
  int _currentVoucherIndex = 0;
  Timer? _voucherTimer;

  // Auto-scroll cho buổi sáng
  final List<String> _morningImages = [
    'assets/img/sang1.jpg',
    'assets/img/sang2.jpg',
    'assets/img/sang3.jpg',
    'assets/img/sang4.jpg',
    'assets/img/sang5.jpg',
  ];
  final PageController _morningController = PageController();
  int _currentMorningIndex = 0;
  Timer? _morningTimer;

  // Auto-scroll cho buổi trưa
  final List<String> _afternoonImages = [
    'assets/img/trua1.jpg',
    'assets/img/trua2.jpg',
    'assets/img/trua3.jpg',
    'assets/img/trua4.jpg',
    'assets/img/trua5.jpg',
  ];
  final PageController _afternoonController = PageController();
  int _currentAfternoonIndex = 0;
  Timer? _afternoonTimer;

  // Auto-scroll cho buổi tối
  final List<String> _eveningImages = [
    'assets/img/toi1.jpg',
    'assets/img/toi2.jpg',
    'assets/img/toi3.jpg',
    'assets/img/toi4.jpg',
    'assets/img/toi5.jpg',
  ];
  final PageController _eveningController = PageController();
  int _currentEveningIndex = 0;
  Timer? _eveningTimer;

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
                  border: Border.all(color: const Color(0xFFBBDEFB), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE3F2FD).withOpacity(0.5),
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showDevelopingSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tính năng đang phát triển')),
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
              ..src = _mapEmbedUrl.isNotEmpty ? _mapEmbedUrl : _generateEmbedUrl(_defaultPosition.latitude, _defaultPosition.longitude)
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
        _currentVoucherIndex = (_currentVoucherIndex + 1) % _voucherImages.length;
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
          _currentMorningIndex = (_currentMorningIndex + 1) % _morningImages.length;
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
          _currentAfternoonIndex = (_currentAfternoonIndex + 1) % _afternoonImages.length;
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
          _currentEveningIndex = (_currentEveningIndex + 1) % _eveningImages.length;
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
    _mapEmbedUrl = 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme màu mệnh Thủy - xanh nhạt da trời
    final theme = Theme.of(context).copyWith(
      primaryColor: const Color(0xFF81D4FA),
      scaffoldBackgroundColor: const Color(0xFFE3F2FD),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF81D4FA)),
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
              // Top row: QR và tìm kiếm ở trên, hồ sơ nhỏ hơn (size 16)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 40, 12, 16),
                child: Row(
                  children: [
                    // Nút QR nhỏ gọn
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: () => _showQRDialog(context),
                        icon: const Icon(Icons.qr_code_scanner, size: 24, color: Color(0xFF81D4FA)),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                          elevation: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Ô tìm kiếm chiếm giữa - button thay thế TextField
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewSearch(currentPosition: _currentPosition),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search, color: Color(0xFF81D4FA), size: 20),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nút hồ sơ nhỏ gọn
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ViewUser()),
                          );
                        },
                        icon: const Icon(Icons.person, size: 22, color: Color(0xFF81D4FA)),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                          elevation: 1,
                        ),
                      ),
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
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE3F2FD),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _mapEmbedUrl.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF81D4FA)))
                          : const HtmlElementView(viewType: 'small-google-maps-iframe'),
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
                      color: const Color(0xFFE3F2FD),
                    ),
                    child: const Center(
                      child: Text('Bản đồ chỉ hỗ trợ trên web', style: TextStyle(color: Color(0xFF81D4FA))),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Các button category
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
                      const Color(0xFF81D4FA),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewFood(currentPosition: _currentPosition),
                        ),
                      ),
                    ),
                    _buildCategoryButton(
                      'Đi chợ',
                      Icons.shopping_cart,
                      const Color(0xFF81D4FA),
                      _showDevelopingSnackBar,
                    ),
                    _buildCategoryButton(
                      'Đồ uống',
                      Icons.local_drink,
                      const Color(0xFF81D4FA),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewDrink(currentPosition: _currentPosition),
                        ),
                      ),
                    ),
                    _buildCategoryButton(
                      'Giao hàng',
                      Icons.delivery_dining,
                      const Color(0xFF81D4FA),
                      _showDevelopingSnackBar,
                    ),
                    _buildCategoryButton(
                      'Tin nhắn',
                      Icons.message,
                      const Color(0xFF81D4FA),
                      _showDevelopingSnackBar,
                    ),
                    _buildCategoryButton(
                      'Tính cách của bạn',
                      Icons.psychology,
                      const Color(0xFF81D4FA),
                      _showDevelopingSnackBar,
                    ),
                    _buildCategoryButton(
                      'Ưu ái',
                      Icons.favorite,
                      const Color(0xFF81D4FA),
                      _showDevelopingSnackBar,
                    ),
                    _buildCategoryButton(
                      'Mua nợ',
                      Icons.payment,
                      const Color(0xFF81D4FA),
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
                    const Text('Khuyến mãi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF81D4FA))),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: PageView.builder(
                        controller: _voucherController,
                        itemCount: _voucherImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(_voucherImages[index], fit: BoxFit.cover, width: double.infinity),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_voucherImages.length, (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: _currentVoucherIndex == index ? 8 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentVoucherIndex == index ? const Color(0xFF81D4FA) : Colors.grey,
                          borderRadius: BorderRadius.circular(3),
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
                    const Text('Combo gợi ý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF81D4FA))),
                    const SizedBox(height: 16),
                    // Buổi sáng
                    const Text('Buổi sáng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF81D4FA))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: PageView.builder(
                        controller: _morningController,
                        itemCount: _morningImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(_morningImages[index], fit: BoxFit.cover, width: double.infinity),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_morningImages.length, (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: _currentMorningIndex == index ? 8 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentMorningIndex == index ? const Color(0xFF81D4FA) : Colors.grey,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                    ),
                    const SizedBox(height: 16),
                    // Buổi trưa
                    const Text('Buổi trưa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF81D4FA))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: PageView.builder(
                        controller: _afternoonController,
                        itemCount: _afternoonImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(_afternoonImages[index], fit: BoxFit.cover, width: double.infinity),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_afternoonImages.length, (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: _currentAfternoonIndex == index ? 8 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentAfternoonIndex == index ? const Color(0xFF81D4FA) : Colors.grey,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                    ),
                    const SizedBox(height: 16),
                    // Buổi tối
                    const Text('Buổi tối', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF81D4FA))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: PageView.builder(
                        controller: _eveningController,
                        itemCount: _eveningImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(_eveningImages[index], fit: BoxFit.cover, width: double.infinity),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_eveningImages.length, (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: _currentEveningIndex == index ? 8 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentEveningIndex == index ? const Color(0xFF81D4FA) : Colors.grey,
                          borderRadius: BorderRadius.circular(3),
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
        // Chat bot button "Tâm sự" dưới góc phải, nổi, dưới cùng
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showChatBotDialog(context);
          },
          backgroundColor: const Color(0xFF81D4FA),
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
        title: const Text('Tâm sự với Chat Bot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chào bạn! Tôi là chat bot của Doan Mobi. Bạn muốn tâm sự gì hôm nay?'),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn của bạn...',
                border: OutlineInputBorder(),
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
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // Helper build category button (bỏ "Tâm sự" ra khỏi Wrap)
  Widget _buildCategoryButton(String label, IconData icon, Color color, VoidCallback onTap) {
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
              color: const Color(0xFFE3F2FD),
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
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}