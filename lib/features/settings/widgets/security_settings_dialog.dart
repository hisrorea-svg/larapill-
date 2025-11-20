import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/user_service.dart';

class SecuritySettingsDialog extends StatefulWidget {
  const SecuritySettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SecuritySettingsDialog(),
    );
  }

  @override
  State<SecuritySettingsDialog> createState() => _SecuritySettingsDialogState();
}

class _SecuritySettingsDialogState extends State<SecuritySettingsDialog> {
  bool _twoFactorAuth = false;
  bool _loginLogging = true;
  bool _autoLockScreen = false;
  int _sessionTimeout = 30;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _twoFactorAuth = prefs.getBool('two_factor_auth') ?? false;
      _loginLogging = prefs.getBool('login_logging') ?? true;
      _autoLockScreen = prefs.getBool('auto_lock_screen') ?? false;
      _sessionTimeout = prefs.getInt('session_timeout') ?? 30;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('two_factor_auth', _twoFactorAuth);
    await prefs.setBool('login_logging', _loginLogging);
    await prefs.setBool('auto_lock_screen', _autoLockScreen);
    await prefs.setInt('session_timeout', _sessionTimeout);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ إعدادات الأمان', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.security, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Text('إعدادات الأمان', style: GoogleFonts.tajawal(fontSize: 18)),
        ],
      ),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSecurityOption(
                      icon: Icons.password,
                      title: 'تغيير كلمة المرور',
                      subtitle: 'تحديث كلمة مرور الدخول',
                      color: AppColors.primary,
                      onTap: _changePassword,
                    ),
                    const Divider(height: 24),
                    _buildSecuritySetting(
                      title: 'المصادقة الثنائية',
                      subtitle: 'طبقة حماية إضافية للحساب',
                      value: _twoFactorAuth,
                      onChanged: (value) =>
                          setState(() => _twoFactorAuth = value),
                      icon: Icons.verified_user,
                      color: AppColors.success,
                    ),
                    const Divider(height: 24),
                    _buildSecuritySetting(
                      title: 'تسجيل عمليات الدخول',
                      subtitle: 'حفظ سجل لجميع محاولات تسجيل الدخول',
                      value: _loginLogging,
                      onChanged: (value) =>
                          setState(() => _loginLogging = value),
                      icon: Icons.history,
                      color: AppColors.info,
                    ),
                    const Divider(height: 24),
                    _buildSecuritySetting(
                      title: 'قفل الشاشة التلقائي',
                      subtitle: 'قفل النظام عند عدم النشاط',
                      value: _autoLockScreen,
                      onChanged: (value) =>
                          setState(() => _autoLockScreen = value),
                      icon: Icons.lock_clock,
                      color: AppColors.warning,
                    ),
                    if (_autoLockScreen) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(right: 48),
                        child: Row(
                          children: [
                            Text('القفل بعد:',
                                style: GoogleFonts.tajawal(fontSize: 14)),
                            const SizedBox(width: 16),
                            DropdownButton<int>(
                              value: _sessionTimeout,
                              items: [5, 10, 15, 30, 60]
                                  .map((minutes) => DropdownMenuItem(
                                        value: minutes,
                                        child: Text('$minutes دقيقة',
                                            style: GoogleFonts.tajawal()),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _sessionTimeout = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    _buildSecurityOption(
                      icon: Icons.policy,
                      title: 'سياسة كلمات المرور',
                      subtitle: 'متطلبات وقواعد كلمات المرور',
                      color: AppColors.secondary,
                      onTap: _showPasswordPolicy,
                    ),
                    const Divider(height: 24),
                    _buildSecurityOption(
                      icon: Icons.exit_to_app,
                      title: 'تسجيل خروج من جميع الأجهزة',
                      subtitle: 'إنهاء جميع الجلسات النشطة',
                      color: AppColors.error,
                      onTap: _logoutAllSessions,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.tajawal()),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildSecuritySetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.tajawal(
                      fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
        ),
      ],
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: GoogleFonts.tajawal(
                          fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تغيير كلمة المرور', style: GoogleFonts.tajawal()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الحالية',
                labelStyle: GoogleFonts.tajawal(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                labelStyle: GoogleFonts.tajawal(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                labelStyle: GoogleFonts.tajawal(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () async {
              // التحقق من صحة المدخلات
              if (oldPasswordController.text.isEmpty ||
                  newPasswordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('يرجى ملء جميع الحقول',
                          style: GoogleFonts.tajawal()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                return;
              }

              if (newPasswordController.text.length < 6) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                          style: GoogleFonts.tajawal()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                return;
              }

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('كلمتا المرور غير متطابقتين',
                          style: GoogleFonts.tajawal()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                return;
              }

              try {
                // الحصول على المستخدم الحالي
                final currentUser = await UserService.getCurrentUser();
                if (currentUser == null) {
                  throw Exception('لا يوجد مستخدم مسجل دخول');
                }

                // محاولة تغيير كلمة المرور
                final result = await UserService.changePassword(
                  userId: currentUser.id,
                  oldPassword: oldPasswordController.text,
                  newPassword: newPasswordController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['success']
                            ? 'تم تغيير كلمة المرور بنجاح'
                            : result['error'] ?? 'فشل تغيير كلمة المرور',
                        style: GoogleFonts.tajawal(),
                      ),
                      backgroundColor: result['success']
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e', style: GoogleFonts.tajawal()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text('تغيير', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  void _showPasswordPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('سياسة كلمات المرور', style: GoogleFonts.tajawal()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPolicyItem('الحد الأدنى 8 أحرف'),
            _buildPolicyItem('يجب أن تحتوي على حرف كبير'),
            _buildPolicyItem('يجب أن تحتوي على حرف صغير'),
            _buildPolicyItem('يجب أن تحتوي على رقم'),
            _buildPolicyItem('يجب أن تحتوي على رمز خاص (@#\$%...)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.tajawal(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _logoutAllSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد', style: GoogleFonts.tajawal()),
        content: Text('هل تريد تسجيل الخروج من جميع الأجهزة؟',
            style: GoogleFonts.tajawal()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('تأكيد', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل الخروج من جميع الأجهزة',
              style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
