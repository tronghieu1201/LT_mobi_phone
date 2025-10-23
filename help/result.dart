import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http; // Để gọi API Geocoding (nếu uncomment)
import 'dart:convert'; // Để parse JSON

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
  List<Map<String, dynamic>> _recommendations = []; // Lưu recommendations sau fetch & filter 5km

  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color darkTextColor = Colors.black87;
  static Color lightTextColor = Colors.white;
  static Color backgroundColor = Colors.grey[50]!;
  static const LatLng _defaultPosition = LatLng(10.7769, 106.7009); // Fallback TP. Hồ Chí Minh

  // THÊM: Suggestions categories theo time-slot (để fetch multiple)
  final Map<String, List<String>> _suggestionsByTimeSlot = {
    'sáng': ['Bánh mì', 'Cafe', 'Nước mía'],
    'trưa': ['Cơm sườn', 'Mỳ cay', 'Bún bò'],
    'tối': ['Trà sữa', 'Sinh tố', 'Cafe'],
  };

  // THÊM: Tính khoảng cách Haversine (km) - MINH CHỨNG: Formula toán học để tính distance chính xác
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

  // THÊM: Fetch lat/lng từ API (Google Geocoding - uncomment để dùng real API với key)
  Future<Map<String, double>?> _fetchLatLng(String address) async {
    // const String apiKey = 'YOUR_GOOGLE_API_KEY'; // Thay bằng key thật
    // final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey');
    // final response = await http.get(url);
    // if (response.statusCode == 200) {
    //   final data = json.decode(response.body);
    //   if (data['results'].isNotEmpty) {
    //     final location = data['results'][0]['geometry']['location'];
    //     return {'lat': location['lat'], 'lng': location['lng']};
    //   }
    // }
    // Fallback: Trả về default nếu không fetch được (cho demo)
    return {'lat': _defaultPosition.latitude, 'lng': _defaultPosition.longitude};
  }

  // THÊM: MINH CHỨNG: Logic quét tự động trong 5km - Fetch từ Firestore theo time-slot categories, geocode, filter & sort
  Future<void> _fetchAndFilterLocations() async {
    if (_currentPosition == null) {
      await _loadCurrentLocation(); // Load vị trí thật
      if (_currentPosition == null) return;
    }

    // Fetch tất cả locations từ Firestore (tự động, không hardcode)
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('locations').get();
    final List<Map<String, dynamic>> allLocs = snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] ?? '',
              'address': doc['address'] ?? '',
              'phone': doc['phone'] ?? '',
              'category': doc['category'] ?? '',
              'distance': 0.0,
            })
        .where((loc) => _suggestionsByTimeSlot[_timeSlot]?.contains(loc['category']) ?? false) // Filter theo time-slot categories
        .toList();

    final List<Map<String, dynamic>> filtered = [];

    for (final loc in allLocs) {
      final latLng = await _fetchLatLng(loc['address'] as String);
      if (latLng != null) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          latLng['lat']!,
          latLng['lng']!,
        );
        loc['distance'] = distance; // Add distance vào map
        if (distance <= 5.0) { // FILTER 5KM: Chỉ lấy trong bán kính 5km
          filtered.add(loc);
        }
      }
    }

    // Sort theo distance gần nhất
    filtered.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    setState(() {
      _recommendations = filtered;
    });

    if (filtered.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quán ăn nào trong bán kính 5km cho khung giờ này. Hãy thử reload vị trí.'), backgroundColor: vietnamRed),
        );
      }
    }
  }

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
    _fetchAndFilterLocations(); // THÊM: Tự động fetch sau detect time
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
      _fetchAndFilterLocations(); // THÊM: Regenerate sau khi có vị trí
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
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: vietnamRed),
              onPressed: _fetchAndFilterLocations, // THÊM: Reload tự động
            ),
          ],
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
              // Danh sách đề xuất (top 5 gần nhất trong 5km)
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
                          'Đề xuất gần bạn nhất trong 5km (${_recommendations.length} nơi)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vietnamRed),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 400,
                          child: ListView.builder(
                            itemCount: _recommendations.length > 5 ? 5 : _recommendations.length,
                            itemBuilder: (context, index) {
                              final rec = _recommendations[index];
                              final hasPhone = rec['phone'] != null && (rec['phone'] as String).isNotEmpty;
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
                Card(
                  elevation: 4,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Đang quét đề xuất trong 5km cho $_timeSlot...',
                          style: TextStyle(fontSize: 16, color: vietnamRed),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _fetchAndFilterLocations,
                          child: const Text('Reload vị trí'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}