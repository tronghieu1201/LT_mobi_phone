// Updated file: home_user.dart (Direct navigation for 'magic' type to ProposeV2 with 'Chè' category, skipping ViewMagic)
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
// Removed import for view_magic.dart since we're skipping it for 'magic'
import 'view/view_user.dart';
import 'view/view_v2/propose_v2.dart'; // FIXED: Sửa lại đường dẫn import
import '../realtime/result/result.dart'; // Import mới cho ResultScreen
import 'dart:async'; // Cho Timer auto-scroll
import 'dart:convert'; // Thêm cho JSON
import 'package:http/http.dart' as http; // Thêm cho HTTP request
import 'package:flutter/foundation.dart' as foundation; // Đổi tên để tránh conflict với kIsWeb
import 'package:shared_preferences/shared_preferences.dart'; // NEW: For loading dynamic categories

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

  // NEW: Dynamic categories loaded from SharedPreferences
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true; // NEW: Loading state to prevent early build

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
    'assets/img/5.jpg',
    'assets/img/2.jpg',
    'assets/img/4.jpg', 
    'assets/img/3.jpg',
  ];
  final PageController _morningController = PageController();
  int _currentMorningIndex = 0;
  Timer? _morningTimer;

  // Auto-scroll cho buổi trưa
  final List<String> _afternoonImages = [
    'assets/img/6.jpg',
    'assets/img/1.jpg',
    'assets/img/7.png',
  ];
  final PageController _afternoonController = PageController();
  int _currentAfternoonIndex = 0;
  Timer? _afternoonTimer;

  // Auto-scroll cho buổi tối
  final List<String> _eveningImages = [
    'assets/img/OIP.webp',
    'assets/img/9.webp',
    'assets/img/10.jpg',
  ];
  final PageController _eveningController = PageController();
  int _currentEveningIndex = 0;
  Timer? _eveningTimer;
  // (Phần logic giữ nguyên)

  // --- Chat Mini State (Tích hợp trực tiếp) ---
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _chatMessages = [
    ChatMessage(text: 'Chào bạn! Siuuuuuuuuuuuu', isUser: false),
  ];
  final ScrollController _chatScrollController = ScrollController();
  bool _isChatLoading = false;
  bool _isChatOpen = false; // Toggle để mở/đóng panel chat nhỏ

  // Dynamic base URL: localhost cho web, IP cho mobile (thay YOUR_IP bằng IP máy thật)
  String get _chatBaseUrl {
    if (foundation.kIsWeb) return 'http://localhost:5000';
    return 'http://YOUR_IP:5000'; // e.g., 'http://192.168.1.100:5000' cho Android
  }

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add(ChatMessage(text: text, isUser: true));
      _isChatLoading = true;
    });
    _chatController.clear();

    try {
      final response = await http.post(
        Uri.parse('${_chatBaseUrl}/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      ).timeout(const Duration(seconds: 10)); // Thêm timeout để tránh hang

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _chatMessages.add(ChatMessage(text: data['response'], isUser: false));
        });
      } else {
        setState(() {
          _chatMessages.add(ChatMessage(
              text: 'Lỗi HTTP ${response.statusCode}: ${response.body}. Kiểm tra server?', 
              isUser: false));
        });
      }
    } on http.ClientException catch (e) {
      setState(() {
        _chatMessages.add(ChatMessage(
            text: 'Lỗi kết nối: $e. Đảm bảo server Python chạy tại $_chatBaseUrl và kiểm tra firewall/CORS.', 
            isUser: false));
      });
    } catch (e) {
      setState(() {
        _chatMessages.add(ChatMessage(text: 'Lỗi không mong muốn: $e. Thử lại nhé!', isUser: false));
      });
    }

    setState(() => _isChatLoading = false);
    _scrollToChatBottom();
  }

  void _scrollToChatBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleChatPanel() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
    if (_isChatOpen) {
      // Scroll to bottom khi mở
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToChatBottom());
    }
  }

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

  // Hàm mới để navigate đến ResultScreen
  void _navigateToResult() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResultScreen()),
    );
  }

  // NEW: Load dynamic categories from SharedPreferences
  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString('home_categories');
      if (categoriesJson != null) {
        final List<dynamic> decoded = jsonDecode(categoriesJson);
        setState(() {
          _categories = decoded.map((x) => Map<String, dynamic>.from(x)).toList();
          // Ensure all fields are set correctly
          _categories.removeWhere((cat) => cat['label'] == null || cat['icon'] == null);
          _categories.forEach((cat) {
            cat['icon'] ??= 'Icons.help_outline';
            cat['type'] ??= 'developing';
            cat['visible'] ??= true;
            // FIXED: Ensure correct types for specific labels
            if (cat['label'] == 'Đồ ăn') cat['type'] = 'food';
            if (cat['label'] == 'Đồ uống') cat['type'] = 'drink';
            if (cat['label'] == 'Tin nhắn') cat['type'] = 'magic';
          });
        });
      } else {
        _setDefaultCategories();
      }
    } catch (e) {
      debugPrint('Error decoding categories: $e');
      _setDefaultCategories();
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  void _setDefaultCategories() {
    setState(() {
      _categories = [
        {'label': 'Đồ ăn', 'icon': 'Icons.restaurant', 'type': 'food', 'visible': true},
        {'label': 'Đi chợ', 'icon': 'Icons.shopping_cart', 'type': 'developing', 'visible': true},
        {'label': 'Đồ uống', 'icon': 'Icons.local_drink', 'type': 'drink', 'visible': true},
        {'label': 'Giao hàng', 'icon': 'Icons.delivery_dining', 'type': 'developing', 'visible': true},
        {'label': 'Tin nhắn', 'icon': 'Icons.message', 'type': 'magic', 'visible': true},
        {'label': 'Tính cách của bạn', 'icon': 'Icons.psychology', 'type': 'developing', 'visible': true},
        {'label': 'Ưu ái', 'icon': 'Icons.favorite', 'type': 'developing', 'visible': true},
        {'label': 'Mua nợ', 'icon': 'Icons.payment', 'type': 'developing', 'visible': true},
      ];
      _isLoadingCategories = false;
    });
  }

  // FIXED: Get onTap callback based on type - For 'magic', direct to ProposeV2 with 'Chè' category (skip ViewMagic)
  VoidCallback? _getCategoryOnTap(String? type) {
    if (type == 'food') {
      return () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewFood(currentPosition: _currentPosition),
        ),
      );
    } else if (type == 'drink') {
      return () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewDrink(currentPosition: _currentPosition),
        ),
      );
    } else if (type == 'magic') { // FIXED: Direct to ProposeV2 with category 'Chè' (skip ViewMagic, go straight to Hình 2)
      return () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProposeV2(),
          settings: RouteSettings(
            name: '/propose_v2',
            arguments: {'currentPosition': _currentPosition, 'category': 'Chè'},
          ),
        ),
      );
    } else {
      return _showDevelopingSnackBar; // All others show developing
    }
  }

  @override
  void initState() {
    super.initState();
    _isLoadingCategories = true;
    _loadCategories(); // NEW: Load categories
    _loadCurrentLocation();
    if (foundation.kIsWeb) {
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

    // Timer auto-scroll cho vouchers (2s mỗi hình) - FIXED: Check hasClients
    _voucherTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _voucherController.hasClients) {
        _currentVoucherIndex =
            (_currentVoucherIndex + 1) % _voucherImages.length;
        _voucherController.animateToPage(
          _currentVoucherIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    // Timer cho buổi sáng (delay 0.5s để không đồng bộ) - FIXED: Check hasClients
    Timer(const Duration(milliseconds: 500), () {
      _morningTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted && _morningController.hasClients) {
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

    // Timer cho buổi trưa (delay 1s) - FIXED: Check hasClients
    Timer(const Duration(seconds: 1), () {
      _afternoonTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted && _afternoonController.hasClients) {
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

    // Timer cho buổi tối (delay 1.5s) - FIXED: Check hasClients
    Timer(const Duration(milliseconds: 1500), () {
      _eveningTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted && _eveningController.hasClients) {
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
    _chatController.dispose();
    _chatScrollController.dispose();
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
    if (foundation.kIsWeb && mounted) {
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
        body: Stack(
          children: [
            SingleChildScrollView(
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
                  if (foundation.kIsWeb)
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
                  // NEW: Dynamic category buttons (all shown, but disabled/faded if !visible)
                  if (_isLoadingCategories)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
                      child: Center(child: CircularProgressIndicator(color: vietnamYellow)),
                    )
                  else if (_categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.center,
                        children: _categories.map((cat) {
                          final label = cat['label'] as String? ?? 'Unknown';
                          final isVisible = (cat['visible'] as bool? ?? true);
                          final type = cat['type'] as String? ?? 'developing';
                          final onTap = isVisible ? _getCategoryOnTap(type) : null;
                          final iconData = _parseIconData(cat['icon'] as String?);
                          return Opacity(
                            opacity: isVisible ? 1.0 : 0.5,
                            child: InkWell(
                              onTap: onTap,
                              borderRadius: BorderRadius.circular(20),
                              child: IgnorePointer(
                                ignoring: !isVisible,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: vietnamYellow.withOpacity(isVisible ? 0.3 : 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(iconData, color: vietnamYellow, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          color: darkTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
                              return GestureDetector(
                                onTap: _showDevelopingSnackBar, // FIXED: Correct function name
                                child: Padding(
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
                              return GestureDetector(
                                onTap: _navigateToResult, // Thay đổi: Navigate đến ResultScreen
                                child: Padding(
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
                              return GestureDetector(
                                onTap: _navigateToResult, // Thay đổi: Navigate đến ResultScreen
                                child: Padding(
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
                              return GestureDetector(
                                onTap: _navigateToResult, // Thay đổi: Navigate đến ResultScreen
                                child: Padding(
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
            // --- Mini Chat Panel (Nhỏ dưới góc) ---
            if (_isChatOpen)
              Positioned(
                bottom: 80, // Cách floating button 80px
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 450, // Chiều cao nhỏ gọn
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: vietnamYellow.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        // Header chat nhỏ
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: vietnamYellow,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble, color: vietnamRed, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Rằm tháng 7',
                                  style: TextStyle(
                                    color: vietnamRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: vietnamRed),
                                onPressed: _toggleChatPanel,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        // Messages list (Expanded để scroll)
                        Expanded(
                          child: ListView.builder(
                            controller: _chatScrollController,
                            itemCount: _chatMessages.length + (_isChatLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _chatMessages.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: CircularProgressIndicator(color: vietnamRed)),
                                );
                              }
                              final message = _chatMessages[index];
                              return Align(
                                alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: message.isUser ? vietnamYellow : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                                    ],
                                  ),
                                  child: Text(
                                    message.text,
                                    style: TextStyle(
                                      color: message.isUser ? Colors.black87 : vietnamRed,
                                      fontSize: 14, // Nhỏ hơn để fit panel
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Input field nhỏ
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _chatController,
                                  decoration: InputDecoration(
                                    hintText: 'Bạn muốn ăn gì hôm nay?',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: vietnamYellow, width: 2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Nhỏ gọn
                                  ),
                                  onSubmitted: (_) => _sendChatMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FloatingActionButton(
                                mini: true,
                                heroTag: 'chat_send',
                                onPressed: _isChatLoading ? null : _sendChatMessage,
                                backgroundColor: vietnamYellow,
                                child: _isChatLoading 
                                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                                    : const Icon(Icons.send, color: Colors.black87, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Chat bot button (Toggle panel nhỏ)
        floatingActionButton: FloatingActionButton(
          onPressed: _toggleChatPanel,
          backgroundColor: vietnamYellow,
          child: Icon(
            _isChatOpen ? Icons.close : Icons.chat_bubble,
            color: Colors.black87,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // NEW: Helper to parse icon string to IconData - FIXED: Handle null and invalid
  IconData _parseIconData(String? iconStr) {
    if (iconStr == null || iconStr.isEmpty) {
      return Icons.help_outline;
    }
    final parts = iconStr.split('.');
    if (parts.length != 2 || parts[0] != 'Icons') {
      return Icons.help_outline;
    }
    final name = parts[1];
    return _getIconByName(name);
  }

  // NEW: Map string name to IconData
  IconData _getIconByName(String name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_drink':
        return Icons.local_drink;
      case 'delivery_dining':
        return Icons.delivery_dining;
      case 'message':
        return Icons.message;
      case 'psychology':
        return Icons.psychology;
      case 'favorite':
        return Icons.favorite;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.help_outline;
    }
  }

  // Helper build category button (deprecated, but kept for reference)
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

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}