import 'pages/exploreBorrowPage.dart';
import 'pages/tagManagementPage.dart';
import 'pages/storageLocationsPage.dart';
import 'services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'services/firebase_auth_service.dart';
import 'pages/authPage.dart';
import 'widgets/navigationSidebar.dart';
import 'pages/homePage.dart';
import 'pages/studyDocumentsPage.dart';
import 'pages/borrowManagementPage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CashewStudyApp());
}

class CashewStudyApp extends StatelessWidget {
  const CashewStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Tài liệu Học tập - Cashew Cloud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD81B60), // Cashew Pink/Rose accent
          primary: const Color(0xFFD81B60),
          surface: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Cổng kiểm soát xác thực: Bắt buộc đăng nhập Firebase trước khi vào ứng dụng
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FirebaseAuthService(),
      builder: (context, _) {
        final auth = FirebaseAuthService();
        if (!auth.isSignedIn) {
          return const AuthPage();
        }
        return const MainLayoutScreen();
      },
    );
  }
}

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 1; // Mặc định mở tab Tài liệu học tập

  @override
  void initState() {
    super.initState();
    SupabaseService().fetchOnlineDocuments();
  }

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    final pages = [
      HomePage(onNavigate: _onNavigate),
      const StudyDocumentsPage(),
      ExploreBorrowPage(onNavigate: _onNavigate),
      BorrowManagementPage(onNavigate: _onNavigate),
      const TagManagementPage(),
      const StorageLocationsPage(),
    ];

    if (isDesktop) {
      // Bố cục Desktop / Web với Sidebar điều hướng bên trái
      return Scaffold(
        body: Row(
          children: [
            NavigationSidebar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onNavigate,
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
          ],
        ),
      );
    } else {
      // Bố cục Mobile với thanh điều hướng bên dưới
      return Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          height: 65,
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavigate,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 3,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFF7D8DF),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 22),
              selectedIcon: Icon(Icons.home_rounded, size: 22, color: Color(0xFFD81B60)),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined, size: 22),
              selectedIcon: Icon(Icons.menu_book_rounded, size: 22, color: Color(0xFFD81B60)),
              label: 'Tài liệu',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined, size: 22),
              selectedIcon: Icon(Icons.explore_rounded, size: 22, color: Color(0xFFD81B60)),
              label: 'Khám phá',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_added_outlined, size: 22),
              selectedIcon: Icon(Icons.bookmark_added_rounded, size: 22, color: Color(0xFFD81B60)),
              label: 'Đang mượn',
            ),
            NavigationDestination(
              icon: Icon(Icons.label_outlined, size: 22),
              selectedIcon: Icon(Icons.label_rounded, size: 22, color: Color(0xFFD81B60)),
              label: 'Thẻ Tag',
            ),
            NavigationDestination(
              icon: Icon(Icons.warehouse_outlined, size: 22),
              selectedIcon: Icon(Icons.warehouse_rounded, size: 22, color: Color(0xFFD81B60)),
              label: 'Kho lưu',
            ),
          ],
        ),
      );
    }
  }
}
