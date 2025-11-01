import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Propose extends StatefulWidget {
  final LatLng? currentPosition;
  final String? category;
  const Propose({super.key, required this.currentPosition, this.category});

  @override
  State<Propose> createState() => _ProposeState();
}

class _ProposeState extends State<Propose> {
  String _mapEmbedUrl = '';
  static const LatLng _defaultPosition = LatLng(10.7769, 106.7009); // Fallback TP. Hồ Chí Minh
  String _currentViewType = '';

  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color backgroundColor = Colors.grey[50]!;

  final Map<String, List<Map<String, String>>> _locationsByCategory = {
    'Bánh mì': [
      {'name': 'Lò Bánh Mì An Tiêm', 'address': 'VQC5+J4M, Lê Trọng Tấn, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0909992888'},
      {'name': 'Ba Dẹo - Bò Kho Bánh Mì - Hủ Tiếu Bò Kho', 'address': '10 Đ. Trần Thị Vững, An Bình, Dĩ An, Bình Dương, Việt Nam'},
      {'name': 'Tiệm Bánh Mì Hoàng Phúc', 'address': '9 Lê Trọng Tấn, An Bình, Thành Phố, Bình Dương, Việt Nam', 'phone': '0399028979'},
      {'name': 'Bánh mỳ hà nội', 'address': '4b Bình Đường 3, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0971587844'},
      {'name': 'Lò Bánh Mì Hằng', 'address': '1242, Đường Kha Vạn Cân, Phường Linh Tây, Quận Thủ Đứ, Phường Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0909100868'},
      {'name': 'Bánh Mì', 'address': 'VQ97+89X, Phường Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0936979653'},
      {'name': 'Lò Bánh Mì Út Tâm', 'address': '1360 Đ. Kha Vạn Cân, Phường Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0966300142'},
    ],
    'Mì cay': [
      {'name': 'Mỳ cay nam hàn xuyên á', 'address': '125 QL1A, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0938525997'},
    ],
    'Cơm': [
      {'name': 'Cơm gà xối mỡ Bảo Như', 'address': '64 Đ. số 12, An Bình, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0902982950'},
      {'name': 'Tiệm Cơm Phát Ký', 'address': 'VQ94+4R4, Đào Trinh Nhất, Phường An Bình, Thị Xã Dĩ An, Tỉnh Bình Dương, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0373983727'},
      {'name': 'Cơm gà xối mỡ 455 chi nhánh 3', 'address': '129 Đ. Đào Trinh Nhất, An Bình, Dĩ An, Bình Dương, Việt Nam'},
      {'name': 'Quán Gà Ta Thanh Thư', 'address': '115 Đ. An Bình, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0368006162'},
      {'name': 'Quán Cơm Minh Hiếu', 'address': 'Bình Đường 2, Phường An Bình, Tỉnh Bình Dương, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0935099880'},
      {'name': 'Cơm Bầu Bí', 'address': 'h8 đường số 3, Bình Đường 2An Bình,Tx. Dĩ An, Bình, Đường Số 3, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0937303986'},
      {'name': 'Cơm tấm - Ngon tấm tắc 2', 'address': '53 Đ.Số 6, An Bình, Dĩ An, Bình Dương 70000, Việt Nam', 'phone': '0899159268'},
      {'name': 'Cơm bình dân Cô Liên', 'address': '71a Đ.Số 6, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0933686508'},
      {'name': 'Cơm Tấm CẬU ÚT', 'address': '10 Đường Số 2, p, Dĩ An, Bình Dương, Việt Nam', 'phone': '0338382721'},
      {'name': 'Cơm tấm - Ngon tấm tắc 1', 'address': '12/2 Đ. Trần Thị Vững, An Bình, Dĩ An, Bình Dương 70000, Việt Nam', 'phone': '0977068938'},
    ],
    'Bún bò': [
      {'name': 'Bún bò Cô Hồng', 'address': '66 Đ. An Bình, Khu dân cư Him Lam Phú Đông, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
      {'name': 'Bún bò Cô Thu', 'address': '79 Hồ Tùng Mậu, Linh Tây, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
      {'name': 'Phở 1111', 'address': '82 Hồ Tùng Mậu, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0904289539'},
      {'name': 'Bún Bò Bà Ba chi nhánh Đào Trinh Nhất', 'address': 'giao với đường, 10a29 ( góc 2 mặt tiền ngã ba, 4 Đ. Đào Trinh Nhất, Linh Tây, Thủ Đức, Thành phố Hồ Chí Minh 71310, Việt Nam', 'phone': '0988178501'},
      {'name': 'Quán bún bò + bún riêu (lẩu bò)', 'address': '19 Đ. Đào Trinh Nhất, Linh Tây, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam'},
      {'name': 'Bún Bò Huế - Chả Vĩ Dạ', 'address': 'VQF6+35H, Dương Đình Nghệ, Phường Linh Trung, Dĩ An, Bình Dương, Việt Nam'},
      {'name': 'Quán gà ta, bún bò Thủy Trinh', 'address': '1 Đ. Số 13, Linh Tây, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0978737094'},
      {'name': 'Bún Bò Phú Qúy', 'address': '979 Đ. Kha Vạn Cân, Linh Chiểu, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0976918702'},
      {'name': 'Quán bún bò Huế THIÊN OANH', 'address': '65 Đ. Đào Trinh Nhất, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0903659540'},
      {'name': 'Bún Bò Bà Năm', 'address': 'VQC4+V8Q, Chu Văn An, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0908646533'},
    ],
    'Nước mía': [
      {'name': 'Nước Mía Cốt Dừa', 'address': 'Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
    ],
    'Cafe': [
      {'name': 'Coffee & Billiard Cao Su', 'address': '82 Đ. số 12, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0909715219'},
      {'name': 'KIEN RAU coffee', 'address': '19 Đ. số 12, An Bình, Thủ Đức, Thành phố Hồ Chí Minh 70000, Việt Nam'},
      {'name': 'HIM LAM Coffee', 'address': '14 Đ. Trần Thị Vững, An Bình, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
      {'name': 'Trầm Coffee&Food', 'address': 'Đường B, Trưng Trắc, Dĩ An, Bình Dương 75000, Việt Nam', 'phone': '0997997979'},
      {'name': 'Lâu Đài Phố - Castle Land Coffee', 'address': 'KDC Himlam Phú Đông, Đường D/Số 1 Đ. Trần Thị Vững, P, Dĩ An, Bình Dương, Việt Nam'},
      {'name': 'Be You Coffee & Tea', 'address': 'đường số 1, Trần Thị Vững, phường Linh Tây, xã An Bình, Dĩ An tỉnh Bình Dương, Tỉnh Bình Dương, Bình Dương 590000, Việt Nam', 'phone': '0794109468'},
      {'name': 'Puppy Coffee', 'address': 'VQ83+WXR, KDC Himlam Phú Đông,Đường P, Đ. Trần Thị Vững, An Bình, Dĩ An, Bình Dương, Việt Nam'},
      {'name': 'RIO THE COFFEE', 'address': '02 Đường Số 1, Khu Dân Cư Him Lam, Dĩ An, Bình Dương, Việt Nam', 'phone': '0949812955'},
      {'name': 'Coffee Trường Hải', 'address': 'H33 TP, Đ. Số 5/H34 Đường 2, Khu Dân Cư Bình, Dĩ An, Bình Dương 75000, Việt Nam', 'phone': '0985055335'},
      {'name': 'Cafe 365', 'address': 'C4 Lê Trọng Tấn, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0962276828'},
      {'name': 'Cà phê sân vườn 1111', 'address': 'Bình/Đường 2/2 Bình Dương, An Bình, Dĩ An, Bình Dương 75000, Việt Nam', 'phone': '0777994136'},
    ],
    'Trà sữa': [
      {'name': 'TRÀ SỮA MOON', 'address': '42 Đường số 4, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0918128578'},
      {'name': 'tiệm trà sữa 96', 'address': '42 Đ. Số 7, Bình Đường 2, Dĩ An, Bình Dương, Việt Nam', 'phone': '0379833184'},
      {'name': 'Trà Sữa Panda Moon An Bình', 'address': 'Đ. Số 5/24 Đường 2, khu phố bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0962378201'},
      {'name': 'Trà sữa Hello', 'address': 'VQC5+M78, Lê Trọng Tấn, An Bình, Dĩ An, Bình Dương, Việt Nam', 'phone': '0984299075'},
      {'name': 'Trà Sữa AMI', 'address': '145a Lê Trọng Tấn, khu phố bình đường 2, Dĩ An, Bình Dương 75000, Việt Nam'},
      {'name': 'Trà sữa Tí Hon', 'address': '62 đường Hồ Tùng Mậu, An Bình, Thủ Đức, Thành phố Hồ Chí Minh 700000, Việt Nam', 'phone': '0982372673'},
      {'name': 'AZA trà sữa và hơn thế nữa', 'address': '83 Đ. An Bình, An Bình, Dĩ An, Bình Dương 75300, Việt Nam', 'phone': '0913777535'},
      {'name': 'Trà sữa Vân Anh 2', 'address': '40 Đ. Đào Trinh Nhất, Linh Tây, Thủ Đức, Bình Dương, Việt Nam', 'phone': '0377332251'},
    ],
    'Sinh tố': [
      {'name': 'Sinh tố, nước ép Lem Juice', 'address': '62 Đ. số 12, An Bình, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0342776133'},
    ],
    'Nước ép': [
      {'name': 'SINH TỐ - NƯỚC ÉP TITO', 'address': '5 Đ. Hoàng Diệu 2, Phường Linh Trung, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0949389323'},
      {'name': 'Trang My Café Mang Về Sinh Tố - Nước ÉP', 'address': 'An Bình, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam'},
      {'name': 'Milano Coffee. Trà trái cây tươi, rau má, sinh tố, nước ép nguyên chất', 'address': '853 Đ. Kha Vạn Cân, Linh Chiểu, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0937985353'},
      {'name': 'ReViet Juice', 'address': '7 Số 1, Linh Xuân, Thủ Đức, Thành phố Hồ Chí Minh, Việt Nam', 'phone': '0931855775'},
    ],
  };

  List<Map<String, String>> get _locations => _locationsByCategory[widget.category ?? 'Bánh mì'] ?? [];

  @override
  void initState() {
    super.initState();
    final position = widget.currentPosition ?? _defaultPosition;
    _updateMapUrl(position);
  }

  void _updateMapUrl(LatLng position) {
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
              Text('${widget.category ?? 'Đề xuất'}', style: const TextStyle(color: vietnamRed)),
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