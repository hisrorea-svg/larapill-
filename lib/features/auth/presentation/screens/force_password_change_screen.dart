import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/auth_providers.dart';

class ForcePasswordChangeScreen extends ConsumerStatefulWidget {
  final String userId;

  const ForcePasswordChangeScreen({super.key, required this.userId});

  @override
  ConsumerState<ForcePasswordChangeScreen> createState() =>
      _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState
    extends ConsumerState<ForcePasswordChangeScreen>
    with TickerProviderStateMixin {
  // ✅ Static RegExp constants for performance
  static final _upperCaseRegex = RegExp(r'[A-Z]');
  static final _lowerCaseRegex = RegExp(r'[a-z]');
  static final _digitRegex = RegExp(r'[0-9]');
  static final _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPasswords = false;
  Map<String, dynamic>? _passwordStrength;

  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _fadeAnimationController, curve: Curves.easeInOut),
    );

    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // منع الخروج
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 48,
                    maxWidth: 500,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildWarningCard(),
                      const SizedBox(height: 32),
                      _buildForm(),
                      const SizedBox(height: 32),
                      _buildChangeButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[600]!, Colors.orange[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.security,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '🔐 تغيير كلمة المرور الإجباري',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'لأمان النظام، يجب تغيير كلمة المرور قبل المتابعة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[50]!, Colors.orange[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.warning, color: Colors.red[700], size: 32),
          const SizedBox(height: 12),
          Text(
            'تحذير هام',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أنت تستخدم كلمة مرور افتراضية. لحماية النظام والبيانات، يجب تغييرها فوراً إلى كلمة مرور قوية وآمنة.',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.red[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⚠️ لن تتمكن من استخدام النظام حتى تغيير كلمة المرور',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Colors.red[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // كلمة المرور الحالية
          TextFormField(
            controller: _currentPasswordController,
            obscureText: !_showPasswords,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الحالية',
              hintText: 'أدخل كلمة المرور الحالية',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            style: const TextStyle(
              fontFamily: 'Tajawal',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'كلمة المرور الحالية مطلوبة';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // كلمة المرور الجديدة
          TextFormField(
            controller: _newPasswordController,
            obscureText: !_showPasswords,
            onChanged: _checkPasswordStrength,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              hintText: 'أدخل كلمة مرور قوية',
              prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            style: const TextStyle(
              fontFamily: 'Tajawal',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'كلمة المرور الجديدة مطلوبة';
              }
              if (value.length < 8) {
                return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
              }
              if (value == _currentPasswordController.text) {
                return 'كلمة المرور الجديدة يجب أن تختلف عن الحالية';
              }
              final strength = _checkPasswordStrengthValue(value);
              if (strength['score'] < 3) {
                return 'كلمة المرور ضعيفة جداً - يجب تحسينها';
              }
              return null;
            },
          ),

          // مؤشر قوة كلمة المرور
          if (_passwordStrength != null) ...[
            const SizedBox(height: 12),
            _buildPasswordStrengthIndicator(),
          ],

          const SizedBox(height: 20),

          // تأكيد كلمة المرور
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showPasswords,
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور الجديدة',
              hintText: 'أعد إدخال كلمة المرور الجديدة',
              prefixIcon:
                  const Icon(Icons.lock_reset, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            style: const TextStyle(
              fontFamily: 'Tajawal',
            ),
            validator: (value) {
              if (value != _newPasswordController.text) {
                return 'كلمات المرور غير متطابقة';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // خيار إظهار كلمات المرور
          CheckboxListTile(
            title: const Text('إظهار كلمات المرور',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
            value: _showPasswords,
            onChanged: (value) => setState(() => _showPasswords = value!),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = _passwordStrength!;
    final checks = strength['checks'] as Map<String, bool>;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: strength['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: strength['color'], width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                strength['score'] >= 4 ? Icons.shield : Icons.security,
                color: strength['color'],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'قوة كلمة المرور: ',
                style: TextStyle(
                    fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              Text(
                strength['strength'],
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: strength['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // شريط التقدم
          LinearProgressIndicator(
            value: strength['score'] / 5,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(strength['color']),
            minHeight: 6,
          ),

          const SizedBox(height: 12),

          // قائمة المتطلبات
          ...checks.entries.map((entry) {
            final labels = {
              'length': '✓ 8 أحرف على الأقل',
              'hasUpper': '✓ حروف كبيرة (A-Z)',
              'hasLower': '✓ حروف صغيرة (a-z)',
              'hasDigit': '✓ أرقام (0-9)',
              'hasSpecial': '✓ رموز خاصة (!@#\$%)',
            };

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    entry.value
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: entry.value ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    labels[entry.key] ?? entry.key,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: entry.value ? Colors.green[700] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChangeButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _changePassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: _isLoading ? 0 : 4,
        shadowColor: Colors.green.withValues(alpha: 0.3),
      ),
      child: _isLoading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'جاري التحديث...',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 16),
                ),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 20),
                SizedBox(width: 8),
                Text(
                  'تغيير كلمة المرور والمتابعة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      _passwordStrength = _checkPasswordStrengthValue(password);
    });
  }

  Map<String, dynamic> _checkPasswordStrengthValue(String password) {
    final checks = {
      'length': password.length >= 8,
      'hasUpper': _upperCaseRegex.hasMatch(password),
      'hasLower': _lowerCaseRegex.hasMatch(password),
      'hasDigit': _digitRegex.hasMatch(password),
      'hasSpecial': _specialCharRegex.hasMatch(password),
    };

    final score = checks.values.where((check) => check).length;
    String strength;
    Color color;

    if (score < 2) {
      strength = 'ضعيفة جداً';
      color = Colors.red;
    } else if (score < 3) {
      strength = 'ضعيفة';
      color = Colors.orange;
    } else if (score < 4) {
      strength = 'متوسطة';
      color = Colors.amber;
    } else if (score < 5) {
      strength = 'قوية';
      color = Colors.lightGreen;
    } else {
      strength = 'قوية جداً';
      color = Colors.green;
    }

    return {
      'strength': strength,
      'score': score,
      'color': color,
      'checks': checks,
    };
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Use case via Clean Architecture
      final changePasswordUseCase = ref.read(changePasswordUseCaseProvider);
      final result = await changePasswordUseCase.execute(
        userId: widget.userId,
        oldPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      // Handle result using Either pattern
      result.fold(
        (failure) {
          if (mounted) {
            AppToast.error(context, '❌ ${failure.message}');
          }
        },
        (_) async {
          if (mounted) {
            AppToast.success(context, '✅ تم تغيير كلمة المرور بنجاح');
            await Future.delayed(const Duration(milliseconds: 1500));
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/main');
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '❌ خطأ في تغيير كلمة المرور: $e',
                    style: const TextStyle(
                        fontFamily: 'Tajawal', color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
