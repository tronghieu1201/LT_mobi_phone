import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui; // Cho platformViewRegistry trên web
import 'dart:html' as html; // Cho IFrameElement trên web
import 'package:url_launcher/url_launcher.dart'; // Fallback cho mobile
import 'package:geolocator/geolocator.dart'; // Lấy vị trí user
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Cho LatLng

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _mapEmbedUrl = ''; // URL dynamic sẽ update với vị trí user
  static const LatLng _defaultPosition = LatLng(21.0278, 105.8342); // Fallback Hồ Gươl
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation(); // Tự động load vị trí khi mở screen
    if (kIsWeb) {
      try {
        // Register iframe factory (sẽ dùng URL dynamic sau)
        ui.platformViewRegistry.registerViewFactory(
          'google-maps-iframe',
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
        debugPrint('Lỗi register iframe: $e');
      }
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      // Kiểm tra GPS enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Bật GPS để lấy vị trí chính xác.');
        _setDefaultMap();
        return;
      }

      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Cần quyền vị trí để cập nhật map.');
          _setDefaultMap();
          return;
        }
      }

      // Lấy vị trí (tương tự JS: enableHighAccuracy, timeout)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Timeout như JS
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Cập nhật URL embed với vị trí user (không cần key, như JS code)
      _updateMapUrl(_currentPosition!.latitude, _currentPosition!.longitude);
      _showSnackBar('Đã cập nhật vị trí của bạn!');
    } catch (e) {
      debugPrint('Lỗi lấy vị trí: $e');
      _showSnackBar('Sử dụng vị trí mặc định do lỗi: $e');
      _setDefaultMap();
    }
  }

  void _updateMapUrl(double lat, double lng) {
    // Generate URL embed dynamic với vị trí user (không cần key, như JS: q=lat,lng&hl=vi&z=15&output=embed)
    _mapEmbedUrl = 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed';
    if (kIsWeb && mounted) {
      // Re-register iframe với URL mới trên web
      ui.platformViewRegistry.registerViewFactory(
        'google-maps-iframe',
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
      setState(() {}); // Refresh UI
    }
  }

  void _setDefaultMap() {
    _updateMapUrl(_defaultPosition.latitude, _defaultPosition.longitude);
    _currentPosition = _defaultPosition;
  }

  String _generateEmbedUrl(double lat, double lng) {
    return 'https://www.google.com/maps?q=${lat},${lng}&hl=vi&z=15&output=embed';
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openMapInBrowser() async {
    String urlToOpen = _mapEmbedUrl.isNotEmpty ? _mapEmbedUrl : _generateEmbedUrl(_defaultPosition.latitude, _defaultPosition.longitude);
    final Uri url = Uri.parse(urlToOpen);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Không thể mở bản đồ.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bản đồ (Vị trí: ${_currentPosition != null ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}' : 'Mặc định'} )'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentLocation, // Refresh vị trí
          ),
        ],
      ),
      body: kIsWeb
          ? Column(
              children: [
                Expanded(
                  child: _mapEmbedUrl.isEmpty
                      ? const Center(child: CircularProgressIndicator()) // Loading
                      : HtmlElementView(viewType: 'google-maps-iframe'),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Vị trí hiện tại: ${_currentPosition != null ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}' : 'Chưa load'}'),
                  ElevatedButton(
                    onPressed: _openMapInBrowser,
                    child: const Text('Mở Google Maps (Mobile)'),
                  ),
                ],
              ),
            ),
    );
  }
}