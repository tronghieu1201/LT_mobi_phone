import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:html' as html;
import '../search_v2/propose.dart';
import '../search_v2/outstanding.dart';

class ViewSearch extends StatefulWidget {
  final LatLng? currentPosition;
  const ViewSearch({super.key, this.currentPosition});

  @override
  State<ViewSearch> createState() => _ViewSearchState();
}

class _ViewSearchState extends State<ViewSearch> {
  final TextEditingController _searchController = TextEditingController();
  String _mapEmbedUrl = '';
  String _currentViewType = 'search-google-maps-iframe'; // Fixed viewType giống home_user.dart
  LatLng? _currentPosition;

  // --- Bảng màu Cờ Đỏ Sao Vàng ---
  // Màu Đỏ cờ (màu nhấn chính)
  static const Color vietnamRed = Color(0xFFDA251D);
  // Màu Vàng sao (màu nhấn phụ)
  static const Color vietnamYellow = Color(0xFFFFC107); // (Màu Amber 500-600)
  // Màu chữ chính (trên nền trắng)
  static Color darkTextColor = Colors.black87;
  // Màu chữ phụ (trên nền đỏ)
  static Color lightTextColor = Colors.white;
  // Màu nền chính
  static Color backgroundColor = Colors.grey[50]!; // Nền hơi xám 1 chút cho dịu mắt

  static const LatLng _defaultPosition = LatLng(21.0278, 105.8342); // Fallback Hà Nội

  @override
  void initState() {
    super.initState();
    if (widget.currentPosition != null) {
      _currentPosition = widget.currentPosition;
      _updateMapUrl(_currentPosition!);
    } else {
      _loadCurrentPosition();
    }
    // Register factory một lần với viewType fixed, sẽ update src sau
    if (kIsWeb) {
      try {
        ui.platformViewRegistry.registerViewFactory(
          _currentViewType,
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
        debugPrint('Lỗi register search map iframe: $e');
      }
    }
  }

  // Hàm tự động lấy vị trí hiện tại
  Future<void> _loadCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra service GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _updateMapUrl(_defaultPosition);
      if (mounted) setState(() {});
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _updateMapUrl(_defaultPosition);
        if (mounted) setState(() {});
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _updateMapUrl(_defaultPosition);
      if (mounted) setState(() {});
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // Lấy vị trí hiện tại
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    _updateMapUrl(_currentPosition!);
  }

  void _updateMapUrl(LatLng position) {
    _mapEmbedUrl = _generateEmbedUrl(position.latitude, position.longitude);
    if (kIsWeb && mounted) {
      // Re-register factory với src mới, viewType fixed giống home_user.dart
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
      setState(() {});
    }
  }

  String _generateEmbedUrl(double lat, double lng, {int zoom = 15}) {
    return 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=${zoom}&output=embed';
  }

  Widget _buildImageContainer(String imagePath, String category) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Outstanding(currentPosition: _currentPosition ?? _defaultPosition, category: category),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: vietnamYellow, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestButton(String label) {
    return OutlinedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Propose(currentPosition: _currentPosition ?? _defaultPosition, category: label),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: vietnamYellow, width: 1.5),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: vietnamYellow,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final List<Map<String, String>> highlightData = [
      {'path': 'assets/img/gs25R.jpg', 'category': 'GS25'},
      {'path': 'assets/img/Jollibee.jpg', 'category': 'Jollibee'},
      {'path': 'assets/img/ministop.jpg', 'category': 'Ministop'},
      {'path': 'assets/img/Highlands.png', 'category': 'Highlands'},
      {'path': 'assets/img/phuclong.jpg', 'category': 'Phu Long'},
      {'path': 'assets/img/HTNG.png', 'category': 'HTNG'},
    ];

    final List<String> suggestLabels = [
      'Bánh mì',
      'Mì cay',
      'Cơm',
      'Nước mía',
      'Cafe',
      'Bún bò',
    ];

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tìm kiếm', style: TextStyle(color: vietnamRed)),
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
              // Ô vị trí của bạn (hiển thị vị trí đang load hoặc đã load)
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: vietnamYellow, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _currentPosition == null
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Vị trí hiện tại: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                                style: TextStyle(fontSize: 12, color: vietnamRed),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (_currentPosition != null)
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: _loadCurrentPosition,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bản đồ nhỏ (giao diện giống home_user.dart: Container height 180, decoration border + shadow, không Card/title)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: vietnamYellow.withOpacity(0.5)),
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
                        ? Center(child: CircularProgressIndicator(color: vietnamRed))
                        : kIsWeb
                            ? const HtmlElementView(viewType: 'search-google-maps-iframe')
                            : Center(
                                child: Text(
                                  'Bản đồ chỉ hỗ trợ trên web',
                                  style: TextStyle(color: vietnamYellow.withOpacity(0.8)),
                                ),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Thanh tìm kiếm (giữ nguyên vị trí sau bản đồ)
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: darkTextColor),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.search, color: vietnamYellow),
                      border: const OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: vietnamRed, width: 2.0), // Viền focus màu ĐỎ
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (value) {
                      // Xử lý search nếu cần
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Note Đề xuất (sửa: các button)
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đề xuất',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: vietnamRed),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        alignment: Alignment.center,
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          alignment: WrapAlignment.center,
                          children: suggestLabels.map((label) => _buildSuggestButton(label)).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Note Nổi bật gần đây (sửa: 9 ô vuông hình ảnh 3x3)
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nổi bật gần đây',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: vietnamRed),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                        ),
                        itemCount: highlightData.length,
                        itemBuilder: (context, index) {
                          return _buildImageContainer(
                            highlightData[index]['path']!,
                            highlightData[index]['category']!,
                          );
                        },
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