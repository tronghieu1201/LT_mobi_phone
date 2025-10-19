import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import '../search_v2/propose.dart';
import '../search_v2/outstanding.dart';

class ViewSearch extends StatefulWidget {
  final LatLng? currentPosition;
  const ViewSearch({super.key, required this.currentPosition});

  @override
  State<ViewSearch> createState() => _ViewSearchState();
}

class _ViewSearchState extends State<ViewSearch> {
  final TextEditingController _searchController = TextEditingController();
  String _mapEmbedUrl = '';
  String _currentViewType = '';

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
    _updateMapUrl(widget.currentPosition ?? _defaultPosition);
  }

  void _updateMapUrl(LatLng position) {
    _mapEmbedUrl = _generateEmbedUrl(position.latitude, position.longitude);
    _currentViewType = 'search-map-iframe-${DateTime.now().millisecondsSinceEpoch}';
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
        debugPrint('Lỗi register search map iframe: $e');
      }
    }
    if (mounted) setState(() {});
  }

  String _generateEmbedUrl(double lat, double lng, {int zoom = 15}) {
    return 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=${zoom}&output=embed';
  }

  Widget _buildImageContainer(String imagePath) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Outstanding(currentPosition: widget.currentPosition),
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
            builder: (_) => Propose(currentPosition: widget.currentPosition),
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

    final List<String> highlightImages = [
      'assets/img/gs25R.jpg',
      'assets/img/Jollibee.jpg',
      'assets/img/ministop.jpg',
      'assets/img/pharmacity.png',
      'assets/img/starbucks.jpg',
      'assets/img/cafe.png',
      'assets/img/kfc.jpg',
      'assets/img/durex.webp',
      'assets/img/phuclong.jpg',
    ];

    final List<String> suggestLabels = [
      'Bánh mì',
      'Mỳ canh',
      'Cơm sườn',
      'Nước mía',
      'Trà sửa',
      'Cafe',
      'Thăng hoa',
      'Cháo',
      'Bún',
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
              // Ô vị trí của bạn (thu nhỏ lại: padding nhỏ hơn, text ngắn gọn)
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // Giảm từ 16 xuống 12
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Thu nhỏ row
                    children: [
                      Icon(Icons.location_on, color: vietnamYellow, size: 20), // Icon nhỏ hơn
                      const SizedBox(width: 6), // Giảm khoảng cách
                      Text(
                        'Vị trí hiện tại', // Ngắn gọn hơn
                        style: TextStyle(fontSize: 14, color: vietnamRed), // Font nhỏ hơn
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), // Giảm khoảng cách
              // Bản đồ nhỏ (khoảng trống đổ bản đồ vào, fixed height)
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
                                    'Bản đồ chỉ hỗ trợ trên web. Vị trí: ${widget.currentPosition?.latitude.toStringAsFixed(4)}, ${widget.currentPosition?.longitude.toStringAsFixed(4)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                    ),
                  ],
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
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: _buildImageContainer(highlightImages[0]),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: _buildImageContainer(highlightImages[1]),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: _buildImageContainer(highlightImages[2]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: _buildImageContainer(highlightImages[3]),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: _buildImageContainer(highlightImages[4]),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: _buildImageContainer(highlightImages[5]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: _buildImageContainer(highlightImages[6]),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: _buildImageContainer(highlightImages[7]),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: _buildImageContainer(highlightImages[8]),
                                ),
                              ),
                            ],
                          ),
                        ],
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