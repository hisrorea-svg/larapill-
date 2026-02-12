import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/init/app_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/navigation/app_navigator.dart';
import 'features/menu/presentation/screens/menu_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/force_password_change_screen.dart';
import 'features/sync/presentation/screens/sync_setup_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/auth/data/repositories/user_service.dart';

void main() async {
  // ✅ كل شيء داخل نفس الـ zone
  runZonedGuarded(() async {
    // ✅ تهيئة Flutter داخل الـ zone لتجنب Zone mismatch
    WidgetsFlutterBinding.ensureInitialized();

    // 🔥 تهيئة التطبيق بالكامل عبر AppBootstrap (غير متزامن)
    final initResult = await AppBootstrap.init();

    if (initResult.status == BootstrapStatus.error) {
      developer.log('❌ Failed to initialize app: ${initResult.error}',
          name: 'Main');
      // يمكن عرض شاشة خطأ هنا
    }

    // تشغيل التطبيق (حتى لو لم تكتمل التهيئة بالكامل)
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

// 🔥 شاشة التهيئة الأولى - محسّنة
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _criticalReady = false;
  bool _fullyReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // ✅ الخطوة 1: الانتظار حتى تكون الخدمات الحرجة جاهزة
      await AppBootstrap.waitForCritical;

      if (mounted) {
        setState(() => _criticalReady = true);
      }

      // ✅ الخطوة 2: الانتظار حتى تكتمل جميع الخدمات (في الخلفية)
      final result = await AppBootstrap.waitForComplete;

      if (mounted) {
        if (result.status == BootstrapStatus.completed) {
          setState(() => _fullyReady = true);
          developer.log(
            '✅ App fully initialized in ${result.elapsedTime.inMilliseconds}ms',
            name: 'AppInitializer',
          );
        } else if (result.status == BootstrapStatus.error) {
          setState(() => _error = result.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ إذا كانت الخدمات الحرجة جاهزة، نعرض السبلاش
    // ونبدأ فحص الجلسة في الخلفية
    if (_criticalReady && _error == null) {
      return SplashScreen(
        onComplete: () => _checkUserSession(),
      );
    }

    // ✅ إذا كان هناك خطأ، نعرض شاشة خطأ
    if (_error != null) {
      return _ErrorScreen(error: _error!);
    }

    // ✅ في البداية، نعرض شاشة تحميل بسيطة
    return const _LoadingScreen();
  }

  Future<void> _checkUserSession() async {
    try {
      // انتظار اكتمال التهيئة بالكامل قبل فحص الجلسة
      if (!_fullyReady) {
        await AppBootstrap.waitForComplete;
      }

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

// ✅ شاشة تحميل بسيطة (قبل السبلاش)
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: const Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ شاشة خطأ
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'خطأ في تشغيل التطبيق',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => AppBootstrap.init(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 شاشة الصفحة غير الموجودة
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحة غير موجودة'),
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
              style: textTheme.displayMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الصفحة المطلوبة غير موجودة',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
              icon: const Icon(Icons.home),
              label: const Text('العودة للرئيسية'),
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
