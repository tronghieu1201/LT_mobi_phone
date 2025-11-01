// Updated file: view_ad_home.dart (Enhanced image addition: auto-copy to app documents/img on mobile, use Image.file for runtime images; Fixed null safety & async)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For demo storage (replace with Firestore in production)
import 'dart:convert'; // For JSON encoding/decoding
import 'package:file_picker/file_picker.dart'; // Add to pubspec.yaml: file_picker: ^6.1.1
import 'package:flutter/foundation.dart' show kIsWeb; // For web detection
import 'package:path_provider/path_provider.dart'; // NEW: For app documents directory
import 'dart:io'; // NEW: For File operations

class ViewAdHomeScreen extends StatefulWidget {
  const ViewAdHomeScreen({super.key});
  @override
  State<ViewAdHomeScreen> createState() => _ViewAdHomeScreenState();
}

class _ViewAdHomeScreenState extends State<ViewAdHomeScreen> {
  // NEW: Demo data with 'type' for actions (e.g., 'developing', 'food', 'drink', 'magic')
  List<Map<String, dynamic>> _categories = [
    {'label': 'Đồ ăn', 'icon': 'Icons.restaurant', 'type': 'food', 'visible': true},
    {'label': 'Đi chợ', 'icon': 'Icons.shopping_cart', 'type': 'developing', 'visible': true},
    {'label': 'Đồ uống', 'icon': 'Icons.local_drink', 'type': 'drink', 'visible': true},
    {'label': 'Giao hàng', 'icon': 'Icons.delivery_dining', 'type': 'developing', 'visible': true},
    {'label': 'Tin nhắn', 'icon': 'Icons.message', 'type': 'developing', 'visible': true},
    {'label': 'Tính cách của bạn', 'icon': 'Icons.psychology', 'type': 'developing', 'visible': true},
    {'label': 'Ưu ái', 'icon': 'Icons.favorite', 'type': 'developing', 'visible': true},
    {'label': 'Mua nợ', 'icon': 'Icons.payment', 'type': 'developing', 'visible': true},
  ];
  List<String> _voucherImages = [
    'assets/img/ss1.jpg',
    'assets/img/ss2.jpg',
    'assets/img/ss3.jpg',
  ];
  List<String> _morningImages = [
    'assets/img/5.jpg',
    'assets/img/2.jpg',
    'assets/img/4.jpg',
    'assets/img/3.jpg',
  ];
  List<String> _afternoonImages = [
    'assets/img/6.jpg',
    'assets/img/1.jpg',
    'assets/img/7.png',
  ];
  List<String> _eveningImages = [
    'assets/img/OIP.webp',
    'assets/img/9.webp',
    'assets/img/10.jpg',
  ];
  // Colors from home_admin
  static const Color vietnamRed = Color(0xFFDA251D);
  static const Color vietnamYellow = Color(0xFFFFC107);
  static Color backgroundColor = Colors.grey[50]!;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    // Demo: Load from SharedPreferences (in production, use Firestore)
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString('home_categories');
    if (categoriesJson != null) {
      setState(() {
        _categories = List<Map<String, dynamic>>.from(
          jsonDecode(categoriesJson).map((x) => Map<String, dynamic>.from(x))
        );
      });
    }
    // Load images
    final voucherJson = prefs.getStringList('voucher_images');
    if (voucherJson != null) setState(() => _voucherImages = List.from(voucherJson));
    final morningJson = prefs.getStringList('morning_images');
    if (morningJson != null) setState(() => _morningImages = List.from(morningJson));
    final afternoonJson = prefs.getStringList('afternoon_images');
    if (afternoonJson != null) setState(() => _afternoonImages = List.from(afternoonJson));
    final eveningJson = prefs.getStringList('evening_images');
    if (eveningJson != null) setState(() => _eveningImages = List.from(eveningJson));
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_categories', jsonEncode(_categories));
    await prefs.setStringList('voucher_images', List<String>.from(_voucherImages));
    await prefs.setStringList('morning_images', List<String>.from(_morningImages));
    await prefs.setStringList('afternoon_images', List<String>.from(_afternoonImages));
    await prefs.setStringList('evening_images', List<String>.from(_eveningImages));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu cấu hình! (Home user cần reload để áp dụng)')),
      );
    }
  }

  bool _isValidIcon(String iconStr) {
    // Simple validation: check if starts with 'Icons.' and has known icon
    return iconStr.startsWith('Icons.') && iconStr.split('.').length == 2;
  }

  void _addCategory() {
    final labelController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            // REMOVED: Icon field, default to Icons.star
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              if (labelController.text.isNotEmpty) {
                setState(() {
                  _categories.add({
                    'label': labelController.text,
                    'icon': 'Icons.star', // Default to star
                    'type': 'magic', // Default to 'magic'
                    'visible': true,
                  });
                });
                _saveConfig();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đầy đủ')),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _editCategory(int index) {
    final labelController = TextEditingController(text: _categories[index]['label']);
    final iconController = TextEditingController(text: _categories[index]['icon']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Icon (e.g., Icons.restaurant)'),
            ),
            // REMOVED: Type dropdown, keep existing type unchanged
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              if (labelController.text.isNotEmpty &&
                  iconController.text.isNotEmpty &&
                  _isValidIcon(iconController.text)) {
                setState(() {
                  _categories[index]['label'] = labelController.text;
                  _categories[index]['icon'] = iconController.text;
                  // Type remains unchanged
                });
                _saveConfig();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đầy đủ và icon hợp lệ (Icons.xxx)')),
                );
              }
            },
            child: const Text('Sửa'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Category?'),
        content: Text('Xóa ${_categories[index]['label']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              setState(() => _categories.removeAt(index));
              _saveConfig();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _toggleVisibility(int index) {
    setState(() {
      _categories[index]['visible'] = !_categories[index]['visible'];
    });
    _saveConfig();
  }

  // NEW: Helper to copy image to app's documents/img directory (mobile only)
  Future<String?> _copyImageToAppDir(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imgDir = Directory('${directory.path}/img');
      await imgDir.create(recursive: true);
      final filename = sourcePath.split('/').last;
      final targetPath = '${imgDir.path}/$filename';
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(targetPath);
        return targetPath;
      }
      return null;
    } catch (e) {
      debugPrint('Error copying image: $e');
      return null;
    }
  }

  Future<void> _addImage(List<String> imageList, String section) async {
    String? newPath;
    if (kIsWeb) {
      // On web, prompt for manual path input (since can't auto-save to assets)
      final controller = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Thêm $section'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Đường dẫn (e.g., assets/img/new.jpg)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            TextButton(
              onPressed: () {
                newPath = controller.text;
                Navigator.pop(context);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
    } else {
      // On mobile/desktop, use file picker and auto-copy to app dir
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final sourcePath = result.files.single.path!;
        newPath = await _copyImageToAppDir(sourcePath);
      }
    }
    // FIX: Safe null check with ?.
    final lastName = newPath?.split('/').last ?? 'unknown';
    if (newPath?.isNotEmpty == true && !imageList.any((p) => p.split('/').last == lastName)) {  // Tweak: tránh duplicate by filename
      setState(() {
        imageList.add(newPath!); // Use ! after null check
      });
      _saveConfig();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm $section: $lastName')),
      );
    } else if (newPath?.isNotEmpty != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể thêm hình!')),
      );
    }
  }

  void _editImage(List<String> imageList, int index, String section) {
    final controller = TextEditingController(text: imageList[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa đường dẫn hình $section'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  imageList[index] = controller.text;
                });
                _saveConfig();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đường dẫn không được rỗng!')),
                );
              }
            },
            child: const Text('Sửa'),
          ),
        ],
      ),
    );
  }

  // FIXED: Make async for await calls
  Future<void> _deleteImage(List<String> imageList, int index, String section) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hình?'),
        content: Text('Xóa hình cho $section?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              // FIXED: Await directory
              final directory = await getApplicationDocumentsDirectory();
              final path = imageList[index];
              if (!kIsWeb && path.startsWith(directory.path)) {
                final file = File(path);
                if (await file.exists()) {
                  await file.delete();
                }
              }
              setState(() => imageList.removeAt(index));
              _saveConfig();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // NEW: Dynamic image loader: asset for web/static, file for runtime/mobile
  Widget _loadImage(String path) {
    if (kIsWeb || path.startsWith('assets/')) {
      return Image.asset(
        path,
        height: 60,
        width: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 60),
      );
    } else {
      return Image.file(
        File(path),
        height: 60,
        width: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 60),
      );
    }
  }

  void _viewImage(String path) {
    // For demo, show dialog with image (in production, use full screen)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          height: 300,
          width: 300,
          child: _loadImage(path),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Home User'),
        backgroundColor: vietnamRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: backgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Categories - Balanced with fixed height, fixed overflow
          SizedBox(
            height: 300, // Fixed height for balance
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded( // FIX: Use Expanded to prevent overflow
                          flex: 1,
                          child: const Text(
                            'Quản lý tìm kiếm',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vietnamRed),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox( // FIX: Constrain button width
                          width: 80,
                          child: ElevatedButton.icon(
                            onPressed: _addCategory,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Thêm', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vietnamYellow,
                              foregroundColor: vietnamRed,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return ListTile(
                            title: Text(cat['label']),
                            // UPDATED: Removed Type from subtitle, only show Label (title) as primary
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.visibility, color: cat['visible'] ? vietnamYellow : Colors.grey),
                                  onPressed: () => _toggleVisibility(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: vietnamYellow),
                                  onPressed: () => _editCategory(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCategory(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Section Images - Repeat for each with balanced height, fixed overflow
          _buildImageSection('Khuyến mãi', _voucherImages),
          const SizedBox(height: 16),
          _buildImageSection('Buổi sáng', _morningImages),
          const SizedBox(height: 16),
          _buildImageSection('Buổi trưa', _afternoonImages),
          const SizedBox(height: 16),
          _buildImageSection('Buổi tối', _eveningImages),
        ],
      ),
    );
  }

  Widget _buildImageSection(String section, List<String> imageList) {
    return SizedBox(
      height: 250, // Balanced height
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // FIX: Use Expanded to prevent overflow
                    flex: 1,
                    child: Text(
                      '$section Images',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: vietnamRed),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox( // FIX: Constrain button width
                    width: 100,
                    child: ElevatedButton.icon(
                      onPressed: () => _addImage(imageList, section),
                      icon: const Icon(Icons.add_photo_alternate, size: 16),
                      label: const Text('Thêm Ảnh', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vietnamYellow,
                        foregroundColor: vietnamRed,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageList.length,
                  itemBuilder: (context, index) {
                    final imgPath = imageList[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _viewImage(imgPath),
                            child: _loadImage(imgPath),
                          ),
                          Flexible( // FIX: Wrap text to prevent overflow
                            child: Text(
                              imgPath.split('/').last,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16, color: vietnamYellow),
                                onPressed: () => _editImage(imageList, index, section),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                onPressed: () => _deleteImage(imageList, index, section), // FIXED: Now async
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}