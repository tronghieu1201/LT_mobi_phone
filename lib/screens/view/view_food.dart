import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:html' as html;

class ViewFood extends StatefulWidget {
  final LatLng? currentPosition;
  const ViewFood({super.key, required this.currentPosition});

  @override
  State<ViewFood> createState() => _ViewFoodState();
}

class _ViewFoodState extends State<ViewFood> {
  String _mapEmbedUrl = '';
  String _currentViewType = '';

  static const LatLng _defaultPosition = LatLng(21.0278, 105.8342);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      primaryColor: const Color(0xFF81D4FA),
      scaffoldBackgroundColor: const Color(0xFFE3F2FD),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF81D4FA),
        foregroundColor: Colors.black87,
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Food'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              
              const SizedBox(height: 16),
              // Thanh tìm kiếm
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm đồ ăn...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF81D4FA)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (value) {
                  // Xử lý search nếu cần
                },
              ),
              const SizedBox(height: 16),
              // Khoảng trống cho Google Map
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBDEFB)),
                ),
                child: kIsWeb
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _mapEmbedUrl.isEmpty
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF81D4FA)))
                            : HtmlElementView(viewType: _currentViewType),
                      )
                    : const Center(
                        child: Text('Bản đồ chỉ hỗ trợ trên web', style: TextStyle(color: Color(0xFF81D4FA))),
                      ),
              ),
              const SizedBox(height: 20),
              // Đề xuất
              const Text(
                'Đề xuất',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF81D4FA)),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF81D4FA)),
                ),
                child: const Center(
                  child: Text(
                    'Danh sách đề xuất đồ ăn (thêm nội dung sau)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Nổi bật gần đây
              const Text(
                'Nổi bật gần đây',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF81D4FA)),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF81D4FA)),
                ),
                child: const Center(
                  child: Text(
                    'Danh sách nổi bật gần đây (thêm nội dung sau)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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