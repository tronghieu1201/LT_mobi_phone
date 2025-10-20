// lib/view/view_v2/propose_v2.dart
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ProposeV2 extends StatefulWidget {
  const ProposeV2({super.key});

  @override
  State<ProposeV2> createState() => _ProposeV2State();
}

class _ProposeV2State extends State<ProposeV2> {
  String _mapEmbedUrl = '';
  static const LatLng _defaultPosition = LatLng(10.7769, 106.7009); // Fallback TP. Hồ Chí Minh
  String _currentViewType = '';
  LatLng? _currentPosition;
  String? _category;

  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color backgroundColor = Colors.grey[50]!;

  final Map<String, List<Map<String, String>>> _locationsByCategory = {
    'Bánh mì': [
      {'name': 'Bánh mì Má Hải', 'address': '792 XLHN, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
      {'name': 'BÁNH MÌ QUE RUBY', 'address': 'Số 1 đường 17 10, Quang Trung/29 đường Lê Văn Chí, Thủ Đức, Thành phố Hồ Chí Minh 71300, Việt Nam', 'phone': '0933626949'},
      {'name': 'Lò Bánh Mì Hà Nội', 'address': '72 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0985980282'},
      {'name': 'Lò Bánh Mì Khánh Mập', 'address': '45 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0974366846'},
    ],
    'Mỳ cay': [
      {'name': 'Mì cay Naga - Man Thiện', 'address': '30a Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
    ],
    'Cơm sườn': [
      {'name': 'Cơm tấm Sài Gòn 918 Lão Trư', 'address': '918 Song Hành Xa Lộ Hà Nội, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh 71206, Việt Nam', 'phone': '0707210606'},
      {'name': 'MIN MIN - Cơm Gà & Ăn Vặt', 'address': '121A Đ. Tân Lập 2, P, Thủ Đức, Thành phố Hồ Chí Minh 72000, Việt Nam', 'phone': '0346507177'},
      {'name': 'Tiệm cơm nhà Phúc', 'address': '198 Man Thiện, Phường Tân Phú, Quận 9, Hồ Chí Minh, Việt Nam', 'phone': '0906032357'},
      {'name': 'Quán Cơm Trang Quận 9', 'address': '104 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0937065322'},
      {'name': 'Quán Cơm Cô Thanh', 'address': 'H3 Man Thiện, Khu phố 1, Thủ Đức, Hồ Chí Minh, Việt Nam'},
      {'name': 'Quán Cơm CamRanh 385', 'address': '45 Đ. Số 385, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0332255818'},
    ],
    'Bún bò': [
      {'name': 'Bún bò gốc huế - mai đình', 'address': '62/15a, 62 Đ. Số 385, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0379539022'},
      {'name': 'Bún Bò Thắm', 'address': '73H Đ. Trương Văn Thành, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0867708791'},
      {'name': 'Bún bò cô Út', 'address': '88C Đ. Trương Văn Thành, Khu Phố 6, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
    ],
    'Nước mía': [
      {'name': 'Nước Mía Cô Hương', 'address': 'A200/23B Đ. Lê Văn Việt, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0908109817'},
    ],
    'Cafe': [
      {'name': 'Cont coffee', 'address': 'Song Hành Xa Lộ Hà Nội, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam'},
      {'name': 'Synary Smart Coffee HUTECH Thủ Đức Campus', 'address': '396 XLHN, Phường Tân Phú, Thủ Đức, Hồ Chí Minh, Việt Nam'},
      {'name': 'Synary Coffee - Hutech', 'address': '10/80c Song Hành Xa Lộ Hà Nội, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
      {'name': 'Phuc Long Coffee & Tea (Phúc Long Hutech Q.9)', 'address': '10/80c XLHN, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '02871001968'},
      {'name': 'Highlands coffee HUTECH khu E', 'address': 'VQ4P+28C, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
    ],
    'Trà sữa': [
      {'name': 'Trà Sữa ToCoToCo Man Thiện', 'address': '271 Man Thiện, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh 700000, Việt Nam', 'phone': '1900636936'},
      {'name': 'Sữa Gạo - Trà Sữa Cha Heo | Quận', 'address': '140A Man Thiện, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh 700000, Việt Nam', 'phone': '0938776898'},
    ],
    'Sinh tố': [
      {'name': 'Tròn Quán - Sinh Tố, Nước Ép', 'address': '31B Đường 904, KP6, Thủ Đức, Thành phố Hồ Chí Minh 715650, Việt Nam', 'phone': '0977512795'},
    ],
    'Nước ép': [
      {'name': 'Sinh tố nước ép a mập', 'address': '70 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0965350228'},
      {'name': 'Sinh Tố Nước Ép Kim Tuyền', 'address': '436 Đ. Lê Văn Việt, Tăng Nhơn Phú A, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0332323977'},
    ],
  };

  List<Map<String, String>> get _locations => _locationsByCategory[_category ?? 'Bánh mì'] ?? [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _currentPosition = arguments['currentPosition'] as LatLng?;
      _category = arguments['category'] as String?;
      _updateMapUrl();
    }
  }

  @override
  void initState() {
    super.initState();
    final position = _currentPosition ?? _defaultPosition;
    _updateMapUrl();
  }

  void _updateMapUrl() {
    final position = _currentPosition ?? _defaultPosition;
    _mapEmbedUrl = _generateEmbedUrl(position.latitude, position.longitude);
    _currentViewType = 'propose-map-iframe-${DateTime.now().millisecondsSinceEpoch}';
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
        debugPrint('Lỗi register propose map iframe: $e');
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
    final origin = _currentPosition ?? _defaultPosition;
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
              Text('${_category ?? 'Đề xuất'}', style: TextStyle(color: vietnamRed)),
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
                          'Vị trí của bạn: ${_currentPosition?.latitude.toStringAsFixed(4)}, ${_currentPosition?.longitude.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 12, color: vietnamRed),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 16),
                        onPressed: () async {
                          // Reload position nếu cần
                          await _loadCurrentPositionForPropose();
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
                          'Danh sách ${_category} gần đây',
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

  // Hàm reload vị trí trong propose
  Future<void> _loadCurrentPositionForPropose() async {
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
    _currentPosition = newPosition;
    setState(() {
      // Cập nhật UI nếu cần
    });
    _updateMapUrl();
  }
}