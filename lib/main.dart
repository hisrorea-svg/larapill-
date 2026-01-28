import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/init/app_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/navigation/app_navigator.dart';
import 'features/menu/screens/menu_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/force_password_change_screen.dart';
import 'features/sync/presentation/screens/sync_setup_screen.dart';
import 'features/splash/screens/splash_screen.dart';
import 'services/user_service.dart';

void main() async {
  // ✅ كل شيء داخل نفس الـ zone
  runZonedGuarded(() async {
    // 🔥 تهيئة التطبيق بالكامل عبر AppBootstrap
    await AppBootstrap.init();

    // تشغيل التطبيق
    runApp(const ProviderScope(child: LaRaPillApp()));
  }, (error, stackTrace) {
    developer.log('Zone Error: $error\nStackTrace: $stackTrace',
        name: 'CrashReports');
  });
}

class LaRaPillApp extends StatelessWidget {
  const LaRaPillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LaRaPill - نظام إدارة الصيدلية',
      theme: AppTheme.lightTheme,

      // ✅ إخفاء شريط التمرير من جميع الصفحات
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),

      initialRoute: '/',
      navigatorKey: AppNavigator.navigatorKey,
      onGenerateRoute: (settings) {
        developer.log('🔄 التنقل إلى: ${settings.name}', name: 'Navigation');

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const AppInitializer(),
              settings: settings,
            );

          case '/login':
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
              settings: settings,
            );

          case '/main':
            return MaterialPageRoute(
              builder: (context) => const MenuScreen(),
              settings: settings,
            );

          case '/force-password-change':
            final userId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) =>
                  ForcePasswordChangeScreen(userId: userId ?? ''),
              settings: settings,
            );

          case '/sync-setup':
            return MaterialPageRoute(
              builder: (context) => const SyncSetupScreen(),
              settings: settings,
            );

          default:
            return MaterialPageRoute(
              builder: (context) => const NotFoundScreen(),
              settings: settings,
            );
        }
      },
    );
  }
}

// 🔥 شاشة التهيئة الأولى
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      onComplete: () => _checkUserSession(),
    );
  }

  Future<void> _checkUserSession() async {
    try {
      // فحص جلسة المستخدم الحالي
      final currentUser = await UserService.getCurrentUser();

      if (!mounted) return;

      if (currentUser != null) {
        developer.log('👤 جلسة نشطة للمستخدم: ${currentUser.fullName}',
            name: 'Auth');
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        developer.log('🔐 لا توجد جلسة نشطة، التوجه للدخول', name: 'Auth');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      developer.log('❌ خطأ في فحص الجلسة: $e', name: 'Auth');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

// 🔥 شاشة الصفحة غير الموجودة
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحة غير موجودة', style: GoogleFonts.tajawal()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '404',
              style: GoogleFonts.tajawal(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الصفحة المطلوبة غير موجودة',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
              icon: const Icon(Icons.home),
              label: Text('العودة للرئيسية', style: GoogleFonts.tajawal()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
