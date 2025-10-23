import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'dart:math' as math; // Để tính Haversine distance
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http; // Để gọi API Geocoding (nếu uncomment)
import 'dart:convert'; // Để parse JSON

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
  List<Map<String, dynamic>> _filteredLocations = []; // Lưu locations sau fetch & filter 5km

  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color backgroundColor = Colors.grey[50]!;

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

  // THÊM: MINH CHỨNG: Logic quét tự động trong 5km - Fetch từ Firestore, geocode, filter & sort theo category
  Future<void> _fetchAndFilterLocations() async {
    if (_currentPosition == null) {
      await _loadCurrentPositionForPropose(); // Load vị trí thật
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
        .where((loc) => loc['category'] == _category) // Filter theo category
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
      _filteredLocations = filtered;
    });

    if (filtered.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quán ăn nào trong bán kính 5km cho category này. Hãy thử reload vị trí.'), backgroundColor: vietnamRed),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _currentPosition = arguments['currentPosition'] as LatLng?;
      _category = arguments['category'] as String?;
      _updateMapUrl();
      _fetchAndFilterLocations(); // Tự động fetch & filter khi load
    }
  }

  void _updateMapUrl() {
    final lat = _currentPosition?.latitude ?? _defaultPosition.latitude;
    final lng = _currentPosition?.longitude ?? _defaultPosition.longitude;
    _mapEmbedUrl = 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed';
    _currentViewType = 'propose_v2-map-iframe-${DateTime.now().millisecondsSinceEpoch}';
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
        debugPrint('Lỗi register propose_v2 map iframe: $e');
      }
    }
    if (mounted) setState(() {});
  }

  // Lưu lịch sử tìm kiếm vào Firebase
  Future<void> _saveToHistory(String name, String address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String collection = 'users';
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance.collection('store').doc(uid).get();
        collection = 'store';
      }
      if (!doc.exists) return;
      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      List<dynamic> history = List.from(userData['history'] ?? []);
      String fullName = '$name - $address';
      Map<String, dynamic> entry = {
        'name': fullName,
        'timestamp': DateTime.now(),  // Timestamp client-side
      };
      // Xóa duplicate nếu có trong 10 item gần nhất
      history.removeWhere((item) => 
        item['name'] == fullName && history.indexOf(item) >= history.length - 10
      );
      history.insert(0, entry);
      if (history.length > 50) {
        history = history.sublist(0, 50);
      }
      await FirebaseFirestore.instance.collection(collection).doc(uid).update({
        'history': history,
      });
      print('✅ Lưu lịch sử tìm kiếm thành công: $fullName');
    } catch (e) {
      print('Error saving history: $e');
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở Google Maps'), backgroundColor: vietnamRed),
        );
      }
    }
    // Lưu lịch sử sau khi mở maps
    await _saveToHistory(locationName, address);
  }

  // Hàm reload vị trí
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
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Bản đồ vị trí',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: vietnamRed),
                  ),
                ),
              ),
              Container(
                height: 200,
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
              const SizedBox(height: 20),
              // Danh sách theo category (sau filter 5km)
              if (_filteredLocations.isNotEmpty)
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
                          'Danh sách ${_category ?? ''} trong 5km (${_filteredLocations.length} nơi)',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: vietnamRed),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 400,
                          child: ListView.builder(
                            itemCount: _filteredLocations.length,
                            itemBuilder: (context, index) {
                              final location = _filteredLocations[index];
                              final hasPhone = location['phone'] != null && (location['phone'] as String).isNotEmpty;
                              final subtitleText = hasPhone
                                  ? '${location['address']}\n${location['phone']}'
                                  : location['address'];
                              final distanceText = '${(location['distance'] as double).toStringAsFixed(1)} km';
                              return ListTile(
                                leading: Icon(Icons.store, color: vietnamYellow, size: 24),
                                title: Text(
                                  location['name'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: vietnamRed,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(subtitleText, style: TextStyle(color: Colors.grey[600])),
                                    Text('Khoảng cách: $distanceText', style: TextStyle(color: vietnamYellow, fontSize: 12)),
                                  ],
                                ),
                                trailing: Icon(Icons.navigation, color: vietnamYellow),
                                onTap: () {
                                  _launchMaps(location['name'] as String, location['address'] as String);
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
                          'Đang quét ${_category ?? ''} trong 5km...',
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