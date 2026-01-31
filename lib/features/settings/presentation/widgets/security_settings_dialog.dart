import 'package:flutter/material.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/data/repositories/user_service.dart';

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
    setState(() {
      _twoFactorAuth =
          HiveStorage.getBool('two_factor_auth', defaultValue: false);
      _loginLogging = HiveStorage.getBool('login_logging', defaultValue: true);
      _autoLockScreen =
          HiveStorage.getBool('auto_lock_screen', defaultValue: false);
      _sessionTimeout = HiveStorage.getInt('session_timeout', defaultValue: 30);
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await HiveStorage.setBool('two_factor_auth', _twoFactorAuth);
    await HiveStorage.setBool('login_logging', _loginLogging);
    await HiveStorage.setBool('auto_lock_screen', _autoLockScreen);
    await HiveStorage.setInt('session_timeout', _sessionTimeout);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ إعدادات الأمان',
              style: TextStyle(
                fontFamily: 'Tajawal',
              )),
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
          const Text('إعدادات الأمان',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 18)),
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
                            const Text('القفل بعد:',
                                style: TextStyle(
                                    fontFamily: 'Tajawal', fontSize: 14)),
                            const SizedBox(width: 16),
                            DropdownButton<int>(
                              value: _sessionTimeout,
                              items: [5, 10, 15, 30, 60]
                                  .map((minutes) => DropdownMenuItem(
                                        value: minutes,
                                        child: Text('$minutes دقيقة',
                                            style: const TextStyle(
                                              fontFamily: 'Tajawal',
                                            )),
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
          child: const Text('إلغاء',
              style: TextStyle(
                fontFamily: 'Tajawal',
              )),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('حفظ',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
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
                  style: const TextStyle(
                      fontFamily: 'Tajawal', fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.grey[600])),
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
                      style: const TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: Colors.grey[600])),
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
        title: const Text('تغيير كلمة المرور',
            style: TextStyle(
              fontFamily: 'Tajawal',
            )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية',
                labelStyle: TextStyle(
                  fontFamily: 'Tajawal',
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                labelStyle: TextStyle(
                  fontFamily: 'Tajawal',
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                labelStyle: TextStyle(
                  fontFamily: 'Tajawal',
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
          ),
          ElevatedButton(
            onPressed: () async {
              // التحقق من صحة المدخلات
              if (oldPasswordController.text.isEmpty ||
                  newPasswordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى ملء جميع الحقول',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                          )),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                return;
              }

              if (newPasswordController.text.length < 6) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                          )),
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
                    const SnackBar(
                      content: Text('كلمتا المرور غير متطابقتين',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                          )),
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
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                        ),
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
                      content: Text('خطأ: $e',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                          )),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('تغيير',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
          ),
        ],
      ),
    );
  }

  void _showPasswordPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سياسة كلمات المرور',
            style: TextStyle(
              fontFamily: 'Tajawal',
            )),
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
            child: const Text('إغلاق',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
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
          Text(text,
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _logoutAllSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد',
            style: TextStyle(
              fontFamily: 'Tajawal',
            )),
        content: const Text('هل تريد تسجيل الخروج من جميع الأجهزة؟',
            style: TextStyle(
              fontFamily: 'Tajawal',
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تأكيد',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                )),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الخروج من جميع الأجهزة',
              style: TextStyle(
                fontFamily: 'Tajawal',
              )),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
