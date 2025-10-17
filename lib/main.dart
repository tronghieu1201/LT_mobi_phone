import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_admin.dart';
import 'screens/home_user.dart';
import 'screens/home_store.dart';
import 'screens/home_store1.dart';
import 'screens/home_store2.dart';
import 'screens/home_store3.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Gọi init auth persistence và tạo admin một lần (KHÔNG signIn tự động)
  final authService = AuthService();
  await authService.initAuth();
  await authService.ensureDefaultAdmin();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login Firebase',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const AuthWrapper(), // ✅ Wrap để check auth state tự động (nếu có session cũ)
    );
  }
}

// ✅ Wrapper để listen auth state và auto-navigate (chỉ nếu đã login từ trước)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // ✅ Đã có session cũ, fetch role và navigate
          return FutureBuilder<String?>(
            future: _getRoleFromUid(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = roleSnapshot.data;
              final email = snapshot.data!.email ?? '';

              if (role == 'admin') {
                return const HomeAdminScreen();
              } else if (role == 'user') {
                return const HomeUserScreen();
              } else if (role == 'store') {
                // ✅ Phân biệt store theo email
                if (email == 'store1@gmail.com') {
                  return const HomeStore1Screen();
                } else if (email == 'store2@gmail.com') {
                  return const HomeStore2Screen();
                } else if (email == 'store3@gmail.com') {
                  return const HomeStore3Screen();
                } else {
                  return const HomeStoreScreen();
                }
              } else {
                // Role không hợp lệ, logout và về login
                FirebaseAuth.instance.signOut();
                return const LoginScreen();
              }
            },
          );
        }

        // ✅ Không có session, về LoginScreen (mặc định khi run app)
        return const LoginScreen();
      },
    );
  }

  // ✅ Helper để fetch role từ UID
  Future<String?> _getRoleFromUid(String uid) async {
    // Kiểm tra users
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>?;
      final isEnabled = userData?['enabled'] ?? true;
      if (isEnabled != false) {
        return userData?['role'];
      }
    }

    // Kiểm tra store
    DocumentSnapshot storeDoc = await FirebaseFirestore.instance.collection('store').doc(uid).get();
    if (storeDoc.exists) {
      final storeData = storeDoc.data() as Map<String, dynamic>?;
      final isEnabled = storeData?['enabled'] ?? true;
      if (isEnabled != false) {
        return storeData?['role'];
      }
    }

    return null;
  }
}