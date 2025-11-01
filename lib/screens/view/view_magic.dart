// lib/screens/view/view_magic.dart (updated - Giao diện trắng + Tự động chuyển)
import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:html' as html;
import 'view_v2/propose_v2.dart'; // Corrected import path

class ViewMagic extends StatefulWidget {
  final LatLng? currentPosition;
  const ViewMagic({super.key, required this.currentPosition});

  @override
  State<ViewMagic> createState() => _ViewMagicState();
}

class _ViewMagicState extends State<ViewMagic> {
  String _mapEmbedUrl = '';
  String _currentViewType = '';

  // --- Bảng màu (Sẽ bị ghi đè thành màu trắng) ---
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color darkTextColor = Colors.black87;
  static Color lightTextColor = Colors.white;
  static Color backgroundColor = Colors.grey[50]!;

  static const LatLng _defaultPosition = LatLng(21.0278, 105.8342);

  final List<String> _magicCategories = ['Chè'];

  @override
  void initState() {
    super.initState();
    // _updateMapUrl(); // Không cần update map nữa vì màn hình này vô hình
    
    // NEW: TỰ ĐỘNG CHUYỂN HƯỚNG (Tự động "ấn" Chè)
    // Chạy ngay sau khi frame đầu tiên được build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Tự động điều hướng với category 'Chè'
        _navigateToPropose('Chè'); 
      }
    });
  }

  // (Hàm _updateMapUrl giữ nguyên, mặc dù không được gọi)
  void _updateMapUrl() {
    final lat = widget.currentPosition?.latitude ?? _defaultPosition.latitude;
    final lng = widget.currentPosition?.longitude ?? _defaultPosition.longitude;
    _mapEmbedUrl = 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed';
    _currentViewType = 'magic-map-iframe-${DateTime.now().millisecondsSinceEpoch}';
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
        debugPrint('Lỗi register magic map iframe: $e');
      }
    }
    if (mounted) setState(() {});
  }

  void _navigateToPropose(String category) {
    // Sử dụng pushReplacement để người dùng không thể back lại màn hình trắng này
    Navigator.pushReplacement(
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

  // Nút này cũng vô hình (vì toàn bộ màn hình là trắng)
  Widget _buildSuggestButton(String label) {
    return OutlinedButton(
      onPressed: () => _navigateToPropose(label),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white, width: 1.5), // <<< VÔ HÌNH
        backgroundColor: Colors.white, // <<< VÔ HÌNH
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white, // <<< VÔ HÌNH
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // GHI ĐÈ TẤT CẢ MÀU SẮC THÀNH TRẮNG ĐỂ "VÔ HÌNH"
    final theme = Theme.of(context).copyWith(
      primaryColor: Colors.white, // <<< VÔ HÌNH
      scaffoldBackgroundColor: Colors.white, // <<< VÔ HÌNH
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white, // <<< VÔ HÌNH
        elevation: 0, // <<< VÔ HÌNH
        iconTheme: IconThemeData(color: Colors.white), // <<< VÔ HÌNH
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Chè', style: TextStyle(color: Colors.white)), // <<< VÔ HÌNH
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  'assets/img/VietNam.png',
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), // <<< VÔ HÌNH
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Body cũng là màu trắng, chỉ hiển thị 1 loading indicator màu trắng
        // để đảm bảo màn hình có gì đó đang build trước khi chuyển hướng
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white, // <<< VÔ HÌNH
          ),
        ),
      ),
    );
  }
}