// lib/screens/view/view_food.dart (updated)
import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:html' as html;
import 'view_v2/propose_v2.dart'; // Corrected import path

class ViewFood extends StatefulWidget {
  final LatLng? currentPosition;
  const ViewFood({super.key, required this.currentPosition});

  @override
  State<ViewFood> createState() => _ViewFoodState();
}

class _ViewFoodState extends State<ViewFood> {
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

  static const LatLng _defaultPosition = LatLng(21.0278, 105.8342);

  // Categories from propose.dart for food
  final List<String> _foodCategories = ['Bánh mì', 'Mì cay', 'Cơm', 'Bún bò'];

  @override
  void initState() {
    super.initState();
    _updateMapUrl();
  }

  void _updateMapUrl() {
    final lat = widget.currentPosition?.latitude ?? _defaultPosition.latitude;
    final lng = widget.currentPosition?.longitude ?? _defaultPosition.longitude;
    _mapEmbedUrl = 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed';
    _currentViewType = 'food-map-iframe-${DateTime.now().millisecondsSinceEpoch}';
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
        debugPrint('Lỗi register food map iframe: $e');
      }
    }
    if (mounted) setState(() {});
  }

  void _navigateToPropose(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProposeV2(),
        settings: RouteSettings(
          name: '/propose_v2',
          arguments: {'currentPosition': widget.currentPosition, 'category': category},
        ),
      ),
    );
  }

  Widget _buildSuggestButton(String label) {
    return OutlinedButton(
      onPressed: () => _navigateToPropose(label),
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
              Text('Đồ ăn', style: TextStyle(color: vietnamRed)),
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
              // Greeting
              
              const SizedBox(height: 16),
              // Thanh tìm kiếm
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    style: TextStyle(color: darkTextColor),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm đồ ăn...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: vietnamYellow),
                      border: const OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: vietnamRed, width: 2.0),
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
              const SizedBox(height: 16),
              // Khoảng trống cho Google Map
              Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Container(
                  height: 200,
                  child: kIsWeb
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _mapEmbedUrl.isEmpty
                              ? Center(child: CircularProgressIndicator(color: vietnamRed))
                              : HtmlElementView(viewType: _currentViewType),
                        )
                      : Center(
                          child: Text('Bản đồ chỉ hỗ trợ trên web', style: TextStyle(color: vietnamRed)),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Đề xuất
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
                          children: _foodCategories.map((category) => _buildSuggestButton(category)).toList(),
                        ),
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