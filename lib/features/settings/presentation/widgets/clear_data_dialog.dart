import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/app_reset_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/providers/app_providers.dart';
// Audit log accessed through database
import '../../../../core/database/drift/database_provider.dart';
import '../dialogs/super_admin_auth_dialog.dart';
import '../dialogs/delete_confirmation_dialog.dart';

/// حوار تأكيد مسح بيانات التطبيق (مع حماية Super Admin)
class ClearDataDialog extends ConsumerStatefulWidget {
  const ClearDataDialog({super.key});

  static Future<void> show(BuildContext parentContext, WidgetRef ref) async {
    return showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) => const ClearDataDialog(),
    );
  }

  @override
  ConsumerState<ClearDataDialog> createState() => _ClearDataDialogState();
}

class _ClearDataDialogState extends ConsumerState<ClearDataDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
          SizedBox(width: 8),
          Text(
            'تنبيه هام!',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سيتم حذف جميع البيانات التالية نهائياً:',
            style:
                TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _BulletItem('جميع المنتجات والمخزون'),
          _BulletItem('المبيعات والفواتير'),
          _BulletItem('العملاء والموردين'),
          _BulletItem('الإعدادات والتفضيلات'),
          _BulletItem('قاعدة البيانات بالكامل'),
          SizedBox(height: 16),
          Text(
            '⚠️ لا يمكن التراجع عن هذا الإجراء!',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'إلغاء',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _confirmClear,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
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
              : const Icon(Icons.delete_forever),
          label: Text(
            _isLoading ? 'جاري المسح...' : 'نعم، امسح الكل',
            style:
                const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClear() async {
    // 🔐 PHASE 1: Super Admin Authentication
    final authenticated = await SuperAdminAuthDialog.authenticate(context, ref);
    if (!authenticated) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // 🔐 PHASE 2: Double Confirmation
    if (!mounted) return;
    final confirmed = await DeleteConfirmationDialog.confirm(
      context,
      operationType: 'مسح جميع البيانات والكاش',
      warningMessage: 'سيتم حذف قاعدة البيانات + الكاش + الإعدادات نهائياً',
    );
    if (!confirmed) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Get current user before clearing (for audit log)
    final currentUser = ref.read(currentUserProvider).value;

    if (!mounted) return;
    setState(() => _isLoading = true);

    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // مسح البيانات
      await AppResetService.clearAllData();

      // 📝 PHASE 3: Audit Logging
      try {
        if (currentUser != null) {
          final db = ref.read(appDatabaseProvider);
          await db.auditLogDriftDao.logDatabaseReset(
            userId: currentUser.id,
            userName: currentUser.fullName.isNotEmpty ? currentUser.fullName : currentUser.username,
            operationType: 'clear_all_data',
            additionalMetadata: {
              'note': 'Database file deleted, full app reset executed',
            },
          );
        }
      } catch (e) {
        // Audit logging failure shouldn't stop the operation
        debugPrint('⚠️ Audit logging failed (expected after DB clear): $e');
      }

      // Close loading dialog and show success
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        AppToast.success(context, 'تم مسح جميع البيانات بنجاح');
      }

      // ✅ Force app exit
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        SystemNavigator.pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        AppToast.error(context, 'فشل في مسح البيانات: $e');
        setState(() => _isLoading = false);
      }
    }
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
        ],
      ),
    );
  }
}
