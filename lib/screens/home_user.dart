import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Thêm import này để có LatLng
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'view/view_search.dart';
import 'view/view_user.dart';

class HomeUserScreen extends StatefulWidget {
  const HomeUserScreen({super.key});

  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  String _mapEmbedUrl = ''; // URL dynamic sẽ update với vị trí user
  static const LatLng _defaultPosition = LatLng(21.0278, 105.8342); // Fallback Hồ Gươm
  LatLng? _currentPosition;

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
    final qrSize = screenWidth > 600 ? 250.0 : 200.0; // Responsive: 250px cho web rộng, 200px cho nhỏ

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: qrSize,
                height: qrSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue[100]!, // Viền xanh nhạt
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue[50]!.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/img/qr.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quét mã QR để truy cập nhanh',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
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

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation(); // Tự động load vị trí khi mở screen
    if (kIsWeb) {
      try {
        // Register iframe factory (sẽ dùng URL dynamic sau)
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
  }

  Future<void> _loadCurrentLocation() async {
    try {
      // Kiểm tra GPS enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Bật GPS để lấy vị trí chính xác.');
        _setDefaultMap();
        return;
      }

      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Cần quyền vị trí để cập nhật map.');
          _setDefaultMap();
          return;
        }
      }

      // Lấy vị trí (tương tự JS: enableHighAccuracy, timeout)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Timeout như JS
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Cập nhật URL embed với vị trí user (không cần key, như JS code)
      _updateMapUrl(_currentPosition!.latitude, _currentPosition!.longitude);
      _showSnackBar('Đã cập nhật vị trí của bạn!');
    } catch (e) {
      debugPrint('Lỗi lấy vị trí: $e');
      _showSnackBar('Sử dụng vị trí mặc định do lỗi: $e');
      _setDefaultMap();
    }
  }

  void _updateMapUrl(double lat, double lng) {
    // Generate URL embed dynamic với vị trí user (không cần key, như JS: q=lat,lng&hl=vi&z=15&output=embed)
    _mapEmbedUrl = 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed';
    if (kIsWeb && mounted) {
      // Re-register iframe với URL mới trên web
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
      setState(() {}); // Refresh UI
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Ý 1: Button Mã QR
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showQRDialog(context),
                icon: const Icon(Icons.qr_code),
                label: const Text('Mã QR'),
              ),
            ),
            // Ý 2 & 3: Buttons Tìm kiếm và Hồ sơ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ViewSearch()),
                        );
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Tìm kiếm'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ViewUser()),
                        );
                      },
                      icon: const Icon(Icons.person),
                      label: const Text('Hồ sơ'),
                    ),
                  ),
                ),
              ],
            ),
            // Ý 4: Thanh tìm kiếm
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // Ý 4: Bản đồ nhỏ (với vị trí hiện tại, fix nhỏ gọn hơn)
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Bản đồ nhỏ (vị trí hiện tại): '),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _loadCurrentLocation, // Refresh vị trí
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(  // Lock size chặt để tránh expand
                      constraints: const BoxConstraints(
                        maxWidth: 300,  // Rộng max 300px
                        maxHeight: 200, // Cao 200px
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _mapEmbedUrl.isEmpty
                            ? const Center(child: CircularProgressIndicator()) // Loading
                            : const HtmlElementView(viewType: 'small-google-maps-iframe'),
                      ),
                    ),
                    if (_currentPosition != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Vị trí: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Bản đồ nhỏ chỉ hỗ trợ trên web'),
              ),
            // Ý 5 & 6: Các button nhỏ vô hiệu hóa
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('Đồ ăn'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('Đi chợ'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('Đồ uống'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('Giao hàng'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('Tin nhắn'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('Tính cách của bạn'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('Ưu ái'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('Mua nợ'),
                  ),
                  ElevatedButton(
                    onPressed: null,
                    child: const Text('Tâm sự'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}