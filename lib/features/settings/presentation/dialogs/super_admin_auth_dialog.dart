import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../features/auth/data/repositories/user_service.dart';

/// Dialog for Super Admin authentication before critical operations
class SuperAdminAuthDialog extends ConsumerStatefulWidget {
  const SuperAdminAuthDialog({super.key});

  /// Show the authentication dialog
  /// Returns true if authentication successful, false otherwise
  static Future<bool> authenticate(BuildContext context, WidgetRef ref) async {
    // 1. Check if current user is admin
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.value;

    if (currentUser == null) {
      if (context.mounted) {
        AppToast.error(context, 'لم يتم العثور على معلومات المستخدم');
      }
      return false;
    }

    // 2. Check if user is admin
    if (!currentUser.isAdmin) {
      if (context.mounted) {
        AppToast.error(
          context,
          '⛔ هذه العملية محصورة على مدير النظام فقط',
        );
      }
      return false;
    }

    // 3. Request password re-entry
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const SuperAdminAuthDialog(),
    );

    return result ?? false;
  }

  @override
  ConsumerState<SuperAdminAuthDialog> createState() =>
      _SuperAdminAuthDialogState();
}

class _SuperAdminAuthDialogState extends ConsumerState<SuperAdminAuthDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      AppToast.error(context, 'الرجاء إدخال كلمة المرور');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Verify password
      final isValid = await UserService.verifyPassword(
        username: currentUser.username,
        password: password,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (isValid) {
          Navigator.of(context).pop(true); // Success
        } else {
          AppToast.error(context, '❌ كلمة المرور غير صحيحة');
          _passwordController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'حدث خطأ في التحقق: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تأكيد صلاحية المدير',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'عملية حساسة تتطلب تأكيد',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentUser?.fullName ?? '',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${currentUser?.username ?? ''}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Password field
          const Text(
            'أدخل كلمة المرور للتأكيد:',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !_isLoading,
            autofocus: true,
            onSubmitted: (_) => _verifyPassword(),
            decoration: InputDecoration(
              hintText: 'كلمة المرور',
              hintStyle: const TextStyle(fontFamily: 'Tajawal'),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'إلغاء',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _verifyPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check_circle),
          label: Text(
            _isLoading ? 'جاري التحقق...' : 'تحقق',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
