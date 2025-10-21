import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  LatLng? _currentPosition;
  String _timeSlot = '';
  String _mapEmbedUrl = '';
  String _currentViewType = '';
  List<Map<String, dynamic>> _recommendations = [];

  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color darkTextColor = Colors.black87;
  static Color lightTextColor = Colors.white;
  static Color backgroundColor = Colors.grey[50]!;

  static const LatLng _defaultPosition = LatLng(21.0278, 105.8342);

  // Map dữ liệu locations từ propose.dart, mở rộng cho các món đề xuất
  final Map<String, List<Map<String, dynamic>>> _locationsByCategory = {
    'Bánh mì': [
      {'name': 'Bánh mì Má Hải', 'address': '792 XLHN, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8665, 'lng': 106.7900},
      {'name': 'BÁNH MÌ QUE RUBY', 'address': 'Số 1 đường 17 10, Quang Trung/29 đường Lê Văn Chí, Thủ Đức, Thành phố Hồ Chí Minh 71300, Việt Nam', 'lat': 10.8650, 'lng': 106.7850, 'phone': '0933626949'},
      {'name': 'Lò Bánh Mì Hà Nội', 'address': '72 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8640, 'lng': 106.7840, 'phone': '0985980282'},
      {'name': 'Lò Bánh Mì Khánh Mập', 'address': '45 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8635, 'lng': 106.7835, 'phone': '0974366846'},
    ],
    'Mì cay': [
      {'name': 'Mì cay Naga - Man Thiện', 'address': '30a Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8620, 'lng': 106.7820},
    ],
    'Cơm': [
      {'name': 'Cơm tấm Sài Gòn 918 Lão Trư', 'address': '918 Song Hành Xa Lộ Hà Nội, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh 71206, Việt Nam', 'lat': 10.8610, 'lng': 106.7810, 'phone': '0707210606'},
      {'name': 'MIN MIN - Cơm Gà & Ăn Vặt', 'address': '121A Đ. Tân Lập 2, P, Thủ Đức, Thành phố Hồ Chí Minh 72000, Việt Nam', 'lat': 10.8600, 'lng': 106.7800, 'phone': '0346507177'},
      {'name': 'Tiệm cơm nhà Phúc', 'address': '198 Man Thiện, Phường Tân Phú, Quận 9, Hồ Chí Minh, Việt Nam', 'lat': 10.8590, 'lng': 106.7790, 'phone': '0906032357'},
      {'name': 'Quán Cơm Trang Quận 9', 'address': '104 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8580, 'lng': 106.7780, 'phone': '0937065322'},
      {'name': 'Quán Cơm Cô Thanh', 'address': 'H3 Man Thiện, Khu phố 1, Thủ Đức, Hồ Chí Minh, Việt Nam', 'lat': 10.8570, 'lng': 106.7770},
      {'name': 'Quán Cơm CamRanh 385', 'address': '45 Đ. Số 385, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8560, 'lng': 106.7760, 'phone': '0332255818'},
    ],
    'Nước mía': [
      {'name': 'Nước Mía Cô Hương', 'address': 'A200/23B Đ. Lê Văn Việt, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8550, 'lng': 106.7750, 'phone': '0908109817'},
    ],
    'Cafe': [
      {'name': 'Cont coffee', 'address': 'Song Hành Xa Lộ Hà Nội, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam', 'lat': 10.8540, 'lng': 106.7740},
      {'name': 'Synary Smart Coffee HUTECH Thủ Đức Campus', 'address': '396 XLHN, Phường Tân Phú, Thủ Đức, Hồ Chí Minh, Việt Nam', 'lat': 10.8530, 'lng': 106.7730},
      {'name': 'Synary Coffee - Hutech', 'address': '10/80c Song Hành Xa Lộ Hà Nội, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8520, 'lng': 106.7720},
      {'name': 'Phuc Long Coffee & Tea (Phúc Long Hutech Q.9)', 'address': '10/80c XLHN, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8510, 'lng': 106.7710, 'phone': '02871001968'},
      {'name': 'Highlands coffee HUTECH khu E', 'address': 'VQ4P+28C, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8500, 'lng': 106.7700},
    ],
    'Bún bò': [
      {'name': 'Bún bò gốc huế - mai đình', 'address': '62/15a, 62 Đ. Số 385, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8490, 'lng': 106.7690, 'phone': '0379539022'},
      {'name': 'Bún Bò Thắm', 'address': '73H Đ. Trương Văn Thành, Phường Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8480, 'lng': 106.7680, 'phone': '0867708791'},
      {'name': 'Bún bò cô Út', 'address': '88C Đ. Trương Văn Thành, Khu Phố 6, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8470, 'lng': 106.7670},
    ],
    'Trà sữa': [
      {'name': 'Gong Cha Thủ Đức', 'address': '123 Man Thiện, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8460, 'lng': 106.7660, 'phone': '0281234567'},
      {'name': 'The Alley', 'address': '456 Song Hành, Tân Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8450, 'lng': 106.7650},
    ],
    'Sinh tố': [
      {'name': 'Sinh Tố Cô Ba', 'address': '789 Lê Văn Việt, Hiệp Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'lat': 10.8440, 'lng': 106.7640},
    ],
  };

  // Đề xuất món dựa trên khung giờ
  final Map<String, List<String>> _suggestionsByTimeSlot = {
    'sáng': ['Bánh mì', 'Cafe', 'Nước mía'],
    'trưa': ['Cơm', 'Mì cay', 'Bún bò'],
    'tối': ['Trà sữa', 'Sinh tố', 'Cafe'],
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _detectTimeSlot();
  }

  // Detect khung giờ hiện tại
  void _detectTimeSlot() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final currentTime = hour + minute / 60.0;

    if (currentTime >= 6.0 && currentTime <= 10.5) {
      _timeSlot = 'sáng';
    } else if (currentTime >= 11.0 && currentTime <= 14.5) {
      _timeSlot = 'trưa';
    } else if (currentTime >= 18.0 && currentTime <= 21.0) {
      _timeSlot = 'tối';
    } else {
      _timeSlot = 'khác';
    }
    _generateRecommendations();
  }

  // Tính khoảng cách Haversine (km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Bán kính Trái Đất (km)
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) * math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  // Generate recommendations dựa trên thời gian và vị trí
  void _generateRecommendations() {
    final suggestions = _suggestionsByTimeSlot[_timeSlot] ?? ['Bánh mì'];
    final allLocs = <Map<String, dynamic>>[];
    for (final category in suggestions) {
      final locations = _locationsByCategory[category] ?? [];
      for (final loc in locations) {
        final lat = loc['lat'] as double? ?? _defaultPosition.latitude;
        final lng = loc['lng'] as double? ?? _defaultPosition.longitude;
        final distance = _currentPosition != null
            ? _calculateDistance(
                _currentPosition!.latitude, _currentPosition!.longitude, lat, lng)
            : 0.0;
        allLocs.add({
          ...loc,
          'category': category,
          'distance': distance,
        });
      }
    }
    // Sort theo khoảng cách gần nhất
    _recommendations = allLocs..sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    if (mounted) setState(() {});
  }

  Future<void> _loadCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultMap();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
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
      _generateRecommendations(); // Regenerate sau khi có vị trí
    } catch (e) {
      debugPrint('Lỗi lấy vị trí: $e');
      _setDefaultMap();
    }
  }

  void _updateMapUrl(double lat, double lng) {
    _mapEmbedUrl = 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed';
    _currentViewType = 'result-map-iframe-${DateTime.now().millisecondsSinceEpoch}';
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
              ..allowFullscreen = true
              ..allow = 'geolocation; microphone; camera';
            return iframe;
          },
        );
      } catch (e) {
        debugPrint('Lỗi register result map iframe: $e');
      }
    }
    if (mounted) setState(() {});
  }

  void _setDefaultMap() {
    _updateMapUrl(_defaultPosition.latitude, _defaultPosition.longitude);
    _currentPosition = _defaultPosition;
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
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kết quả đề xuất', style: TextStyle(color: vietnamRed)),
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
              // Thời gian đề xuất
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khung giờ: $_timeSlot',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vietnamRed),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đề xuất dựa trên thời gian thực: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Bản đồ vị trí',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: vietnamRed),
                      ),
                    ),
                    Container(
                      height: 200,
                      width: double.infinity,
                      child: _mapEmbedUrl.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: vietnamRed))
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
                                    'Bản đồ chỉ hỗ trợ trên web. Vị trí: ${_currentPosition?.latitude.toStringAsFixed(4)}, ${_currentPosition?.longitude.toStringAsFixed(4)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Danh sách đề xuất (top 5 gần nhất)
              if (_recommendations.isNotEmpty)
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
                          'Đề xuất gần bạn nhất (${_recommendations.length} nơi)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vietnamRed),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 400,
                          child: ListView.builder(
                            itemCount: _recommendations.length > 5 ? 5 : _recommendations.length,
                            itemBuilder: (context, index) {
                              final rec = _recommendations[index];
                              final hasPhone = rec.containsKey('phone') && (rec['phone'] as String).isNotEmpty;
                              final subtitleText = hasPhone
                                  ? '${rec['address']}\n${rec['phone']}'
                                  : rec['address'];
                              final distanceText = '${(rec['distance'] as double).toStringAsFixed(1)} km';
                              return ListTile(
                                leading: Icon(Icons.store, color: vietnamYellow, size: 24),
                                title: Text(
                                  '${rec['name']} (${rec['category']})',
                                  style: TextStyle(fontWeight: FontWeight.w500, color: vietnamRed),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(subtitleText, style: TextStyle(color: Colors.grey[600])),
                                    Text('Khoảng cách: $distanceText', style: TextStyle(color: vietnamYellow, fontSize: 12)),
                                  ],
                                ),
                                trailing: Icon(Icons.navigation, color: vietnamYellow),
                                onTap: () => _launchMaps(rec['name'] as String, rec['address'] as String),
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
                    child: Center(child: Text('Đang tải đề xuất...')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}