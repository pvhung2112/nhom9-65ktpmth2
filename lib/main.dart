import 'services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'services/firebase_auth_service.dart';
import 'pages/authPage.dart';
import 'widgets/navigationSidebar.dart';
import 'pages/homePage.dart';
import 'pages/studyDocumentsPage.dart';
import 'pages/studyCoursesPage.dart';
import 'pages/studyGoalsPage.dart';
import 'pages/studyDocumentSearchPage.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    final pages = [
      HomePage(onNavigate: _onNavigate),
      const StudyDocumentsPage(),
      const CoursesPage(),
      const StudyGoalsPage(),
      const DocumentSearchPage(),
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
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavigate,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
            NavigationDestination(icon: Icon(Icons.menu_book_rounded), label: 'Tài liệu'),
            NavigationDestination(icon: Icon(Icons.school_rounded), label: 'Môn học'),
            NavigationDestination(icon: Icon(Icons.flag_rounded), label: 'Mục tiêu'),
            NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Tìm kiếm'),
          ],
        ),
      );
    }
  }
}
