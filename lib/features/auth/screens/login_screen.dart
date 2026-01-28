import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pelaicons/pelaicons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/user_service.dart';
import '../../../core/security/advanced_rate_limiter.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _usernameError;
  String? _passwordError;

  // Animation controllers
  late final AnimationController _shakeAnimationController;
  late final Animation<double> _shakeAnimation;
  late final AnimationController _fadeAnimationController;
  late final Animation<double> _fadeAnimation;

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _fadeAnimationController, curve: Curves.easeOutQuart),
    );

    _fadeAnimationController.forward();
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
    // الحصول على معلومات الصيدلية من المزود
    final pharmacyInfoAsync = ref.watch(pharmacyInfoProvider);
    final pharmacyName = pharmacyInfoAsync.value?['name'] ?? 'صيدلية فارماكليك';
    final pharmacyNameEn =
        pharmacyInfoAsync.value?['english_name'] ?? 'LaRaPill Pharmacy';

    return Scaffold(
      body: Stack(
        children: [
          // Background
          const _LoginBackground(),

          // Login Form
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    // ✅ تحسين الأداء: بناء الفورم مرة واحدة وتمريره كـ child
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
                                _Header(
                                  pharmacyName: pharmacyName,
                                  pharmacyNameEn: pharmacyNameEn,
                                ),
                                const SizedBox(height: 32),
                                _UsernameField(
                                  controller: _usernameController,
                                  errorText: _usernameError,
                                  onChanged: () {
                                    if (_usernameError != null) {
                                      setState(() => _usernameError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),
                                _PasswordField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  errorText: _passwordError,
                                  isLoading: _isLoading,
                                  onToggleVisibility: () {
                                    setState(() =>
                                        _obscurePassword = !_obscurePassword);
                                  },
                                  onChanged: () {
                                    if (_passwordError != null) {
                                      setState(() => _passwordError = null);
                                    }
                                  },
                                  onSubmitted: (_) {
                                    _login();
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
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
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: _isLoading ? 0 : 4,
                                      shadowColor: AppColors.primary
                                          .withValues(alpha: 0.3),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
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
                                ),
                                const SizedBox(height: 24),
                                const _Footer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
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

  Future<void> _login() async {
    if (_isLoading) return;

    // Clear previous errors
    setState(() {
      _usernameError = null;
      _passwordError = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    bool hasError = false;

    if (username.isEmpty) {
      setState(() => _usernameError = 'يرجى إدخال اسم المستخدم');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'يرجى إدخال كلمة المرور');
      hasError = true;
    }

    if (hasError) {
      _triggerShake();
      return;
    }

    // 🔒 Security Check
    final rateLimitCheck = await AdvancedRateLimiter.checkAttempt(username);
    if (!rateLimitCheck['canAttempt']) {
      final remaining = rateLimitCheck['remaining'] as Duration;
      final level = rateLimitCheck['level'] as int;
      setState(() {
        _usernameError =
            AdvancedRateLimiter.getWarningMessage(level, remaining);
      });
      _triggerShake();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await UserService.login(username, password);

      if (!mounted) return;

      if (result['success']) {
        await _handleSuccessfulLogin(result, username);
      } else {
        await _handleFailedLogin(result, username);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameError = 'حدث خطأ في الاتصال';
          _passwordError = 'حاول مرة أخرى';
        });
        _triggerShake();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSuccessfulLogin(
      Map<String, dynamic> result, String username) async {
    await AdvancedRateLimiter.clearAttempts(username);
    final user = result['user'] as User;

    if (user.forcePasswordChange) {
      if (mounted) {
        _showSnackBar(
          context,
          '🔐 يجب تغيير كلمة المرور الافتراضية',
          color: Colors.orange[700]!,
          icon: Icons.security,
        );
        // تأخير بسيط قبل التوجيه
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/force-password-change',
            arguments: user.id,
          );
        }
      }
      return;
    }

    if (mounted) {
      _showSnackBar(
        context,
        'مرحباً ${user.fullName}',
        color: AppColors.success,
        icon: Icons.check_circle,
      );
    }

    // تحديث الـ providers
    ref.invalidate(currentUserProvider);
    ref.invalidate(userDisplayNameProvider);

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  Future<void> _handleFailedLogin(
      Map<String, dynamic> result, String username) async {
    final failureData = await AdvancedRateLimiter.recordFailedAttempt(username);
    final error = result['error'] ?? 'خطأ في تسجيل الدخول';

    setState(() {
      if (error.contains('كلمة المرور')) {
        _passwordError = 'كلمة المرور خاطئة';
      } else if (error.contains('المستخدم')) {
        _usernameError = 'المستخدم غير موجود';
      } else {
        _usernameError = 'تحقق من بيانات الدخول';
        _passwordError = 'تحقق من بيانات الدخول';
      }
    });

    if (failureData['level'] > 0 && mounted) {
      _showSnackBar(
        context,
        '🔒 محاولات متكررة مشبوهة. سيتم منعك من المحاولة قريباً.',
        color: Colors.orange[700]!,
      );
    }

    _triggerShake();
  }

  void _triggerShake() {
    _shakeAnimationController.forward().then((_) {
      _shakeAnimationController.reverse();
    });
  }

  void _showSnackBar(BuildContext context, String message,
      {required Color color, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.tajawal(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const _ForgotPasswordDialog(),
    );
  }
}

// -----------------------------------------------------------------------------
// Component Widgets (Extracted for Performance)
// -----------------------------------------------------------------------------

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Image.asset(
            'assets/images/loginscrren.webp',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
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
    );
  }
}

class _Header extends StatelessWidget {
  final String pharmacyName;
  final String pharmacyNameEn;

  const _Header({required this.pharmacyName, required this.pharmacyNameEn});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          pharmacyName,
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          pharmacyNameEn,
          style: GoogleFonts.tajawal(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onChanged;

  const _UsernameField({
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          inputFormatters: InputSanitizer.usernameFormatters,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'اسم المستخدم',
            hintText: 'أدخل اسم المستخدم',
            prefixIcon: Icon(
              Icons.person_outline,
              color: errorText != null ? AppColors.error : AppColors.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.primary,
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
          onChanged: (_) => onChanged(),
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        if (errorText != null)
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
                  errorText!,
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
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final String? errorText;
  final bool isLoading;
  final VoidCallback onToggleVisibility;
  final VoidCallback onChanged;
  final ValueChanged<String> onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.obscureText,
    required this.errorText,
    required this.isLoading,
    required this.onToggleVisibility,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[<>{}]')),
          ],
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            hintText: 'أدخل كلمة المرور',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: errorText != null ? AppColors.error : AppColors.primary,
            ),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: errorText != null
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.primary,
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
          onChanged: (_) => onChanged(),
          onFieldSubmitted: (val) {
            if (!isLoading) onSubmitted(val);
          },
        ),
        if (errorText != null)
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
                  errorText!,
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
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'الإصدار 1.0.0',
          style: GoogleFonts.tajawal(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
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
}

class _ForgotPasswordDialog extends StatelessWidget {
  const _ForgotPasswordDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
    );
  }
}
