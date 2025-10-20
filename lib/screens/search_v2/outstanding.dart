// lib/screens/search_v2/outstanding.dart
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class Outstanding extends StatefulWidget {
  final LatLng? currentPosition;
  final String? category;
  const Outstanding({super.key, required this.currentPosition, this.category});

  @override
  State<Outstanding> createState() => _OutstandingState();
}

class _OutstandingState extends State<Outstanding> {
  String _mapEmbedUrl = '';
  static const LatLng _defaultPosition = LatLng(10.7769, 106.7009); // Fallback TP. Hồ Chí Minh
  String _currentViewType = '';

  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color backgroundColor = Colors.grey[50]!;

  final Map<String, List<Map<String, String>>> _locationsByCategory = {
    'GS25': [
      {'name': 'GS25 Man Thiện', 'address': '123 Man Thiện, Phường Tân Phú, Quận 9, Thành phố Hồ Chí Minh, Việt Nam'},
      {'name': 'GS25 - ĐH GTVT', 'address': '449 Đ. Lê Văn Việt, Tăng Nhơn Phú A, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
      {'name': 'GS25 Võ Văn Ngân', 'address': '01 Đ. Võ Văn Ngân, Linh Chiểu, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
      {'name': 'GS25 Hồ Thị Tư', 'address': '52 Hồ Thị Tư, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
    ],
    'Jollibee': [
      {'name': 'Jollibee CoopMart Xa Lộ Hà Nội', 'address': '191 Quang Trung, Hiệp Phú, Quận 9, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '02837307554'},
    ],
    'Ministop': [
      {'name': 'MINISTOP-HUTECH KHU E', 'address': 'Việt Nam, Thành phố Hồ Chí Minh, Thủ Đức, Hiệp Phú, Song Hành Xa Lộ Hà Nội', 'phone': '02835106870'},
    ],
    'Highlands': [
      {'name': 'Highlands coffee HUTECH khu E', 'address': 'VQ4P+28C, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
      {'name': 'Highlands Coffee Song Hành - Thủ Đức', 'address': '15-16 Song Hành Xa Lộ Hà Nội, Phường, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam', 'phone': '02871084459'},
    ],
    'Phu Long': [
      {'name': 'Phuc Long Coffee & Tea (Phúc Long Hutech Q.9)', 'address': '10/80c XLHN, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
    ],
    'HTNG': [
      {'name': 'Hồng Trà Ngô Gia H170', 'address': '159 Lê Văn Chí, Phường Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam', 'phone': '0981545896'},
    ],
  };

  List<Map<String, String>> get _locations => _locationsByCategory[widget.category ?? 'GS25'] ?? [];

  @override
  void initState() {
    super.initState();
    final position = widget.currentPosition ?? _defaultPosition;
    _updateMapUrl(position);
  }

  void _updateMapUrl(LatLng position) {
    _mapEmbedUrl = _generateEmbedUrl(position.latitude, position.longitude);
    _currentViewType = 'outstanding-map-iframe-${DateTime.now().millisecondsSinceEpoch}';
    if (kIsWeb) {
      try {
        ui.platformViewRegistry.registerViewFactory(
          _currentViewType,
          (int viewId) {
            final iframe = html.IFrameElement()
              ..width = '100%'
              ..height = '100%'
              ..src = _mapEmbedUrl
              ..style.border = 'none'
              ..allowFullscreen = true;
            return iframe;
          },
        );
      } catch (e) {
        debugPrint('Lỗi register outstanding map iframe: $e');
      }
    }
    if (mounted) setState(() {});
  }

  String _generateEmbedUrl(double lat, double lng, {int zoom = 15}) {
    return 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=${zoom}&output=embed';
  }

  String _generateDirectionsUrl(LatLng origin, String destination) {
    final encodedOrigin = '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}';
    final encodedDest = Uri.encodeComponent(destination);
    return 'https://www.google.com/maps/dir/?api=1&origin=$encodedOrigin&destination=$encodedDest&travelmode=driving';
  }

  Future<void> _launchMaps(String locationName, String address) async {
    final origin = widget.currentPosition ?? _defaultPosition;
    final destination = '$locationName, $address';
    final url = _generateDirectionsUrl(origin, destination);
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showSnackBar('Không thể mở Google Maps');
    }
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
    final theme = Theme.of(context).copyWith(
      primaryColor: vietnamRed,
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
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${widget.category ?? 'Nổi bật gần đây'}', style: TextStyle(color: vietnamRed)),
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vị trí của bạn
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: vietnamYellow, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Vị trí của bạn: ${widget.currentPosition?.latitude.toStringAsFixed(4)}, ${widget.currentPosition?.longitude.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, color: vietnamRed),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 16),
                        onPressed: () async {
                          // Reload position nếu cần
                          await _loadCurrentPositionForOutstanding();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bản đồ
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Bản đồ vị trí',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: vietnamRed),
                      ),
                    ),
                    Container(
                      height: 200, // Fixed height cho bản đồ nhỏ
                      width: double.infinity,
                      child: _mapEmbedUrl.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : kIsWeb
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(15),
                                    bottomRight: Radius.circular(15),
                                  ),
                                  child: HtmlElementView(viewType: _currentViewType),
                                )
                              : Center(
                                  child: Text(
                                    'Bản đồ chỉ hỗ trợ trên web.',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Danh sách theo category
              if (_locations.isNotEmpty)
                Card(
                  elevation: 4,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danh sách ${widget.category} gần đây',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: vietnamRed),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 400,
                          child: ListView.builder(
                            itemCount: _locations.length,
                            itemBuilder: (context, index) {
                              final location = _locations[index];
                              final hasPhone = location.containsKey('phone') && location['phone']!.isNotEmpty;
                              final subtitleText = hasPhone
                                  ? '${location['address']!}\n${location['phone']!}'
                                  : location['address']!;
                              return ListTile(
                                leading: Icon(Icons.store, color: vietnamYellow, size: 24),
                                title: Text(
                                  location['name']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: vietnamRed,
                                  ),
                                ),
                                subtitle: Text(
                                  subtitleText,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                trailing: Icon(Icons.navigation, color: vietnamYellow),
                                onTap: () {
                                  _launchMaps(location['name']!, location['address']!);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('Không có dữ liệu cho category này.'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm reload vị trí trong outstanding
  Future<void> _loadCurrentPositionForOutstanding() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final newPosition = LatLng(position.latitude, position.longitude);
    setState(() {
      // Cập nhật UI nếu cần
    });
    _updateMapUrl(newPosition);
  }
}