import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/init/app_bootstrap.dart';

/// 🚀 شاشة السبلاش المحسّنة
/// 
/// الميزات:
/// - ✅ الانتظار حتى تكتمل الخدمات الحرجة فقط (ليس كل الخدمات)
/// - ✅ عرض حالة التحميل الحقيقية
/// - ✅ الحد الأدنى لعرض الشعار (1 ثانية) لتحسين UX
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _horizontalSlide;
  late Animation<double> _fadeAnimation;

  // ✅ حالة التحميل
  String _statusText = 'جاري التحميل...';
  double _progress = 0.0;
  bool _isReady = false;

  // ✅ توقيتات
  final _minDisplayDuration = const Duration(seconds: 1);
  DateTime? _displayStartTime;

  @override
  void initState() {
    super.initState();
    _displayStartTime = DateTime.now();
    _setupAnimations();
    _startLoadingProcess();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _horizontalSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeInOut,
      ),
    );

    _slideController.forward();
  }

  /// ✅ بدء عملية التحميل
  Future<void> _startLoadingProcess() async {
    try {
      // ✅ الخطوة 1: الخدمات الحرجة (سريعة)
      setState(() {
        _statusText = 'جاري تهيئة النظام...';
        _progress = 0.3;
      });

      await AppBootstrap.waitForCritical;

      // ✅ الخطوة 2: الانتظار حتى اكتمال جميع الخدمات في الخلفية
      setState(() {
        _statusText = 'جاري تحميل البيانات...';
        _progress = 0.6;
      });

      // ✅ انتظار اكتمال التهيئة (أو timeout)
      final result = await AppBootstrap.waitForComplete.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log('⏱️ Splash timeout - proceeding anyway', name: 'Splash');
          return const BootstrapResult(
            status: BootstrapStatus.completed,
            elapsedTime: Duration(seconds: 5),
          );
        },
      );

      setState(() {
        _progress = 1.0;
        _statusText = 'جاهز!';
        _isReady = true;
      });

      developer.log(
        '✅ Splash: Init completed in ${result.elapsedTime.inMilliseconds}ms',
        name: 'Splash',
      );

      // ✅ الانتظار حتى انتهاء الحد الأدنى للعرض
      await _waitForMinDisplay();

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      developer.log('❌ Splash error: $e', name: 'Splash');
      setState(() {
        _statusText = 'حدث خطأ، جاري المحاولة...';
        _progress = 0.0;
      });

      // ✅ إعادة المحاولة بعد ثانية
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _startLoadingProcess();
      }
    }
  }

  /// ✅ الانتظار حتى انتهاء الحد الأدنى للعرض
  Future<void> _waitForMinDisplay() async {
    if (_displayStartTime == null) return;

    final elapsed = DateTime.now().difference(_displayStartTime!);
    if (elapsed < _minDisplayDuration) {
      final remaining = _minDisplayDuration - elapsed;
      await Future.delayed(remaining);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            // ✅ أشكال زخرفية خلفية
            _buildBackgroundShapes(),

            // ✅ المحتوى الرئيسي
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ شعار التطبيق المتحرك
                    AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_horizontalSlide.value, 0),
                          child: child,
                        );
                      },
                      child: _buildLogo(),
                    ),

                    const SizedBox(height: 32),

                    // ✅ اسم التطبيق
                    const Column(
                      children: [
                        Text(
                          'LaRaPill',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'نظام إدارة الصيدلية الشامل',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ✅ شريط التقدم (بدلاً من CircularProgressIndicator)
                    SizedBox(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ✅ نص الحالة
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusText,
                        key: ValueKey(_statusText),
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                    // ✅ مؤشر "جاهز" (يظهر عند الاكتمال)
                    if (_isReady)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ✅ حقوق النشر
            const Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Text(
                '© 2026 LaRaPill',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: Colors.black45,
                ),
              ),
            ),

            // ✅ إصدار التطبيق
            Positioned(
              top: 30,
              right: 30,
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/images/app_icon.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        // ✅ دائرة كبيرة في الأعلى
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(15),
            ),
          ),
        ),
        // ✅ دائرة في الأسفل
        Positioned(
          bottom: -100,
          left: -50,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(10),
            ),
          ),
        ),
      ],
    );
  }
}
