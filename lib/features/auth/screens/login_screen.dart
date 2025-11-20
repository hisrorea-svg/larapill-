import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/user_service.dart';
import '../../../core/security/advanced_rate_limiter.dart';
import '../../../database/database_helper.dart';
import '../../../core/utils/input_sanitizer.dart';
import 'dart:developer' as developer;
import 'package:pelaicons/pelaicons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _usernameError;
  String? _passwordError;
  String _pharmacyName = 'صيدلية فارماكليك';
  String _pharmacyNameEn = 'LaRaPill Pharmacy';

  // Animation controllers
  late AnimationController _shakeAnimationController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
          parent: _shakeAnimationController, curve: Curves.elasticIn),
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _fadeAnimationController, curve: Curves.easeInOut),
    );

    _fadeAnimationController.forward();
    _loadPharmacyName();
  }

  Future<void> _loadPharmacyName() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final result = await db.query('pharmacy_settings', limit: 1);
      if (result.isNotEmpty) {
        if (mounted) {
          setState(() {
            if (result.first['name_ar'] != null) {
              _pharmacyName = result.first['name_ar'] as String;
            }
            if (result.first['name_en'] != null) {
              _pharmacyNameEn = result.first['name_en'] as String;
            }
          });
        }
      }
    } catch (e) {
      // استخدام الأسماء الافتراضية في حالة الخطأ
      developer.log('خطأ في تحميل اسم الصيدلية: $e', name: 'Login');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _shakeAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with gradient overlay
          Positioned.fill(
            child: Stack(
              children: [
                // Background image
                Image.asset(
                  'assets/images/loginscrren.webp',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to solid color if image fails to load
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.8),
                            AppColors.primary.withValues(alpha: 0.6),
                            const Color(0xFF4A90E2),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Gradient overlay for better readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Login form content
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: Card(
                          elevation: 24,
                          shadowColor: Colors.black.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          color: Colors.white.withValues(alpha: 0.95),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildHeader(),
                                    const SizedBox(height: 32),
                                    _buildUsernameField(),
                                    const SizedBox(height: 20),
                                    _buildPasswordField(),
                                    const SizedBox(height: 8),
                                    _buildForgotPasswordLink(),
                                    const SizedBox(height: 24),
                                    _buildLoginButton(),
                                    const SizedBox(height: 24),
                                    _buildFooter(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo with shadow and animation
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.7)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Pelaicons.fingerprintScanningBold,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'مرحباً بك',
          style: GoogleFonts.tajawal(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          _pharmacyName,
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _pharmacyNameEn,
          style: GoogleFonts.tajawal(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _usernameController,
          inputFormatters: InputSanitizer.usernameFormatters,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'اسم المستخدم',
            hintText: 'أدخل اسم المستخدم',
            prefixIcon: Icon(
              Icons.person_outline,
              color:
                  _usernameError != null ? AppColors.error : AppColors.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _usernameError != null ? AppColors.error : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _usernameError != null ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _usernameError != null
                    ? AppColors.error
                    : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: GoogleFonts.tajawal(),
          onChanged: (value) {
            if (_usernameError != null) {
              setState(() => _usernameError = null);
            }
          },
          onFieldSubmitted: (_) =>
              FocusScope.of(context).nextFocus(), // الانتقال للحقل التالي
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null; // نستخدم custom error handling
            }
            if (InputSanitizer.containsXss(value) ||
                InputSanitizer.containsSqlInjection(value)) {
              return 'اسم المستخدم يحتوي على أحرف غير مسموح بها';
            }
            return null;
          },
        ),
        // Custom error message under field
        if (_usernameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  _usernameError!,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          inputFormatters: [
            FilteringTextInputFormatter.deny(
                RegExp(r'[<>{}]')), // منع أحرف خطيرة
          ],
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            hintText: 'أدخل كلمة المرور',
            prefixIcon: Icon(
              Icons.lock_outline,
              color:
                  _passwordError != null ? AppColors.error : AppColors.primary,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: _passwordError != null
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _passwordError != null ? AppColors.error : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _passwordError != null ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _passwordError != null
                    ? AppColors.error
                    : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: GoogleFonts.tajawal(),
          onChanged: (value) {
            if (_passwordError != null) {
              setState(() => _passwordError = null);
            }
          },
          onFieldSubmitted: (_) {
            if (!_isLoading) {
              _login();
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return null; // نستخدم custom error handling
            }
            if (InputSanitizer.containsXss(value)) {
              return 'كلمة المرور تحتوي على أحرف غير مسموح بها';
            }
            return null;
          },
        ),
        // Custom error message under field
        if (_passwordError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  _passwordError!,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: _showForgotPasswordDialog,
        child: Text(
          'نسيت كلمة المرور؟',
          style: GoogleFonts.tajawal(
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isLoading ? 0 : 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'تسجيل الدخول',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Version info
        Text(
          'الإصدار 1.0.0',
          style: GoogleFonts.tajawal(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        // Copyright
        Text(
          '© 2025 LaRaPill. جميع الحقوق محفوظة',
          style: GoogleFonts.tajawal(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _login() async {
    // Clear previous errors
    setState(() {
      _usernameError = null;
      _passwordError = null;
    });

    // Validate fields
    bool hasError = false;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      setState(() => _usernameError = 'يرجى إدخال اسم المستخدم');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'يرجى إدخال كلمة المرور');
      hasError = true;
    }

    if (hasError) {
      _shakeAnimationController.forward().then((_) {
        _shakeAnimationController.reverse();
      });
      return;
    }

    // 🔒 فحص Rate Limiting قبل المحاولة
    final rateLimitCheck = await AdvancedRateLimiter.checkAttempt(username);

    if (!rateLimitCheck['canAttempt']) {
      final remaining = rateLimitCheck['remaining'] as Duration;
      final level = rateLimitCheck['level'] as int;

      setState(() {
        _usernameError =
            AdvancedRateLimiter.getWarningMessage(level, remaining);
      });

      // تسجيل المحاولة المحظورة
      developer.log('🚫 محاولة دخول محظورة: $username (المستوى: $level)',
          name: 'Security');

      _shakeAnimationController.forward().then((_) {
        _shakeAnimationController.reverse();
      });
      return;
    }

    // عرض تحذير إذا كان قريباً من الحد الأقصى
    if (rateLimitCheck.containsKey('attemptsLeft') &&
        rateLimitCheck['attemptsLeft'] <= 2) {
      final attemptsLeft = rateLimitCheck['attemptsLeft'] as int;
      setState(() {
        _usernameError = '⚠️ تبقى لك $attemptsLeft محاولات قبل المنع';
      });
    }

    setState(() => _isLoading = true);

    try {
      developer.log('🔐 محاولة تسجيل الدخول للمستخدم: $username',
          name: 'Login');

      final result = await UserService.login(username, password);

      if (!mounted) return;

      if (result['success']) {
        // 🎉 نجح تسجيل الدخول - مسح المحاولات الفاشلة
        await AdvancedRateLimiter.clearAttempts(username);

        final user = result['user'] as User;
        developer.log('✅ تم تسجيل الدخول بنجاح: ${user.fullName}',
            name: 'Login');

        // فحص إجبار تغيير كلمة المرور
        if (user.forcePasswordChange) {
          developer.log('🔐 إجبار تغيير كلمة المرور للمستخدم: ${user.username}',
              name: 'Login');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🔐 يجب تغيير كلمة المرور الافتراضية',
                        style: GoogleFonts.tajawal(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
          }

          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/force-password-change',
              arguments: user.id,
            );
          }
          return;
        }

        // Success animation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'مرحباً ${user.fullName}',
                      style: GoogleFonts.tajawal(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        // 🚨 فشل تسجيل الدخول - تسجيل المحاولة الفاشلة
        final failureData =
            await AdvancedRateLimiter.recordFailedAttempt(username);

        developer.log(
            '❌ فشل تسجيل الدخول: ${result['error']} (المستوى: ${failureData['level']})',
            name: 'Login');

        // عرض رسالة خطأ مناسبة
        final error = result['error'] ?? 'خطأ في تسجيل الدخول';
        if (error.contains('كلمة المرور')) {
          setState(() => _passwordError = 'كلمة المرور خاطئة');
        } else if (error.contains('المستخدم')) {
          setState(() => _usernameError = 'المستخدم غير موجود');
        } else {
          setState(() {
            _usernameError = 'تحقق من بيانات الدخول';
            _passwordError = 'تحقق من بيانات الدخول';
          });
        }

        // تحذير إضافي حسب مستوى الخطر
        if (failureData['level'] > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🔒 محاولات متكررة مشبوهة. سيتم منعك من المحاولة قريباً.',
                style: GoogleFonts.tajawal(color: Colors.white),
              ),
              backgroundColor: Colors.orange[700],
              duration: const Duration(seconds: 4),
            ),
          );
        }

        // Shake animation for error
        _shakeAnimationController.forward().then((_) {
          _shakeAnimationController.reverse();
        });
      }
    } catch (e) {
      developer.log('❌ خطأ في تسجيل الدخول: $e', name: 'Login');
      if (mounted) {
        setState(() {
          _usernameError = 'حدث خطأ في الاتصال';
          _passwordError = 'حاول مرة أخرى';
        });

        _shakeAnimationController.forward().then((_) {
          _shakeAnimationController.reverse();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('نسيت كلمة المرور؟', style: GoogleFonts.tajawal()),
          ],
        ),
        content: Text(
          'يرجى التواصل مع مدير النظام لإعادة تعيين كلمة المرور.',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً',
                style: GoogleFonts.tajawal(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
