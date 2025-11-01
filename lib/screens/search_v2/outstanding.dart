import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      {'name': 'GS25', 'address': '113 Đ. Tam Hà, Tam Phú, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam'},
      {'name': 'GS25 Phú Châu', 'address': '20 Phú Châu, Tam Phú, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
    ],
    'Jollibee': [
      {'name': 'Jollibee Tô Ngọc Vân', 'address': '238-238A Đ. Tô Ngọc Vân, Khu Phố 3, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '02873026879'},
    ],
    'Ministop': [
      {'name': 'CHTL - MINISTOP - S240 - Kha Vạn Cân', 'address': '819 Đ. Kha Vạn Cân, Linh Chiểu, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
    ],
    'Highlands': [
      {'name': 'Highlands Coffee Lê Trọng Tấn Bình Dương', 'address': '133 Lê Trọng Tấn, An Bình, Dĩ An, Bình Dương 75000, Việt Nam', 'phone': '02747300669'},
      {'name': 'Highlands Coffee Flora Thủ Đức', 'address': 'Tòa nhà Flora Novia, Đ. Phạm Văn Đồng, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam', 'phone': '02871091452'},
    ],
    'Phu Long': [
      {'name': 'Phúc Long Tea & Coffee - 1012 Kha Vạn Cân', 'address': '1012 Đ. Kha Vạn Cân, Linh Chiểu, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam'},
    ],
    'HTNG': [
      {'name': 'Hồng Trà Ngô Gia H247', 'address': '106 Đ. An Bình, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0989580247'},
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

  Future<void> _launchMaps(String name, String address) async {
    final origin = widget.currentPosition ?? _defaultPosition;
    final destination = '$name, $address';
    final url = _generateDirectionsUrl(origin, destination);
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Không thể mở Google Maps';
    }
  }

  // Lưu lịch sử tìm kiếm vào Firebase - SỬA: Không phân biệt auth method, tự tạo doc nếu chưa có, init cơ bản cho user mới
  Future<void> _saveToHistory(String name, String address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Không có user Auth khi lưu history');
      return;
    }
    final uid = user.uid;
    final email = user.email ?? '';
    try {
      // Ưu tiên users collection cho tất cả user (Gmail hay email/password)
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String collection = 'users';
      bool docExists = doc.exists;

      // Nếu không có trong users, thử store (fallback cho store user, nhưng ưu tiên users)
      if (!docExists) {
        doc = await FirebaseFirestore.instance.collection('store').doc(uid).get();
        collection = 'store';
        docExists = doc.exists;
      }

      Map<String, dynamic> userData = docExists ? (doc.data() as Map<String, dynamic>) : {};
      List<dynamic> history = List.from(userData['history'] ?? []);

      String fullName = '$name - $address';
      Map<String, dynamic> entry = {
        'name': fullName,
        'timestamp': Timestamp.fromDate(DateTime.now()),  // Sử dụng Timestamp Firestore chuẩn
      };

      // Xóa duplicate nếu có trong 10 item gần nhất
      history.removeWhere((item) => 
        item['name'] == fullName && 
        history.indexOf(item) >= (history.length - 10)
      );
      history.insert(0, entry);

      // Giới hạn 50 item
      if (history.length > 50) {
        history = history.sublist(0, 50);
      }

      // Nếu doc chưa tồn tại, tạo mới với data cơ bản (không phân biệt, luôn role 'user')
      if (!docExists) {
        print('📝 Tạo doc mới cho user $uid (type: user, email: $email)');
        await FirebaseFirestore.instance.collection(collection).doc(uid).set({
          'role': 'user',
          'enabled': true,
          'email': email,
          'history': history,  // Init với entry mới
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Update nếu tồn tại
        await FirebaseFirestore.instance.collection(collection).doc(uid).update({
          'history': history,
        });
      }
      print('✅ Lưu lịch sử thành công: $fullName (collection: $collection)');
    } catch (e) {
      print('❌ Error saving history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      primaryColor: vietnamRed,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
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
              Text('${widget.category ?? 'Nổi bật'}', style: const TextStyle(color: vietnamRed)),
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
                    style: const TextStyle(
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
                          style: const TextStyle(
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: vietnamRed,
                                  ),
                                ),
                                subtitle: Text(
                                  subtitleText,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                trailing: Icon(Icons.navigation, color: vietnamYellow),
                                // Gọi _saveToHistory sau _launchMaps (không thay đổi)
                                onTap: () async {
                                  await _launchMaps(location['name']!, location['address']!);
                                  await _saveToHistory(location['name']!, location['address']!);
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
}