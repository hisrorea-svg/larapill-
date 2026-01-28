import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../database/database_helper.dart';
import '../../../core/services/password_hasher.dart';
import '../../../services/pharmacy_settings_service.dart';
import '../widgets/notification_settings_dialog.dart';
import '../widgets/security_settings_dialog.dart';
import '../widgets/system_log_dialog.dart';
import '../presentation/providers/settings_providers.dart';
import '../presentation/utils/user_entity_mapper.dart';
import '../presentation/utils/error_handler.dart';
import '../../../core/exceptions/app_exceptions.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../../network/presentation/screens/network_settings_screen.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_toast.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final settings = [
      _SettingCard(
        title: 'إدارة المستخدمين',
        subtitle: 'إضافة وتعديل المستخدمين',
        icon: Icons.people,
        color: AppColors.primary,
        onTap: () => _showUsersManagement(),
      ),
      _SettingCard(
        title: 'إعدادات الصيدلية',
        subtitle: 'معلومات الصيدلية والبيانات',
        icon: Icons.local_pharmacy,
        color: Colors.teal,
        onTap: () => _showPharmacySettings(),
      ),
      _SettingCard(
        title: 'النسخ الاحتياطي',
        subtitle: 'حفظ واستعادة البيانات',
        icon: Icons.backup,
        color: AppColors.success,
        onTap: () => _showBackupOptions(),
      ),
      _SettingCard(
        title: 'سجل النظام',
        subtitle: 'متابعة الأنشطة',
        icon: Icons.history,
        color: AppColors.warning,
        onTap: () => SystemLogDialog.show(context),
      ),
      _SettingCard(
        title: 'قاعدة البيانات',
        subtitle: 'فحص وتنظيف',
        icon: Icons.storage,
        color: AppColors.secondary,
        onTap: () => _showDatabaseOptions(),
      ),
      _SettingCard(
        title: 'الإشعارات',
        subtitle: 'إعدادات التنبيهات',
        icon: Icons.notifications,
        color: Colors.orange,
        onTap: () => NotificationSettingsDialog.show(context),
      ),
      _SettingCard(
        title: 'الأمان',
        subtitle: 'كلمات المرور',
        icon: Icons.security,
        color: Colors.red,
        onTap: () => SecuritySettingsDialog.show(context),
      ),
      _SettingCard(
        title: 'إعدادات الشبكة',
        subtitle: 'ربط الأجهزة عبر LAN',
        icon: Icons.lan,
        color: Colors.indigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NetworkSettingsScreen()),
        ),
      ),
      _SettingCard(
        title: 'حول التطبيق',
        subtitle: 'معلومات النسخة',
        icon: Icons.info_outline,
        color: AppColors.info,
        onTap: () => _showAbout(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: settings.length,
                    itemBuilder: (context, index) => settings[index],
                  ),
                ),
              ),
            ),
    );
  }

  void _showBackupOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.backup, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Text('النسخ الاحتياطي', style: GoogleFonts.tajawal(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(
              icon: Icons.add_circle_outline,
              title: 'إنشاء نسخة احتياطية',
              subtitle: 'حفظ نسخة من البيانات الحالية',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                _createBackup();
              },
            ),
            const SizedBox(height: 12),
            _buildDialogOption(
              icon: Icons.restore,
              title: 'استعادة نسخة احتياطية',
              subtitle: 'استرجاع البيانات من نسخة سابقة',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                _showRestoreOptions();
              },
            ),
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

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final dbHelper = DatabaseHelper();
      final result = await dbHelper.createBackup();
      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          _showSnackBar('تم إنشاء النسخة الاحتياطية بنجاح', AppColors.success);
        } else {
          throw DatabaseException(
            'فشل إنشاء النسخة الاحتياطية',
            userMessage: 'فشل إنشاء النسخة الاحتياطية. يرجى المحاولة مرة أخرى.',
            operation: 'backup',
          );
        }
      }
    } on sqflite.DatabaseException catch (e, stackTrace) {
      if (mounted) {
        setState(() => _isLoading = false);
        SettingsErrorHandler.handleError(
          context,
          DatabaseException(
            'خطأ في قاعدة البيانات أثناء إنشاء النسخة الاحتياطية',
            userMessage: 'حدث خطأ في قاعدة البيانات. يرجى المحاولة مرة أخرى.',
            originalError: e,
            stackTrace: stackTrace,
            operation: 'backup',
          ),
        );
      }
    } on AppException catch (e, stackTrace) {
      if (mounted) {
        setState(() => _isLoading = false);
        SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _isLoading = false);
        final appException = convertToAppException(e, stackTrace: stackTrace);
        SettingsErrorHandler.handleError(
          context,
          appException,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _showRestoreOptions() async {
    try {
      final dbHelper = DatabaseHelper();
      final backups = await dbHelper.getBackupsList();
      if (!mounted) return;
      if (backups.isEmpty) {
        _showSnackBar('لا توجد نسخ احتياطية متاحة', AppColors.warning);
        return;
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('استعادة نسخة احتياطية', style: GoogleFonts.tajawal()),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView.builder(
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final backup = backups[index];
                return ListTile(
                  leading: const Icon(Icons.backup, color: AppColors.primary),
                  title:
                      Text(backup['name'] ?? '', style: GoogleFonts.tajawal()),
                  subtitle: Text(backup['date'] ?? '',
                      style: GoogleFonts.tajawal(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    _restoreBackup(backup);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.tajawal()),
            ),
          ],
        ),
      );
    } on sqflite.DatabaseException catch (e, stackTrace) {
      if (mounted) {
        SettingsErrorHandler.handleError(
          context,
          DatabaseException(
            'خطأ في قاعدة البيانات أثناء تحميل النسخ الاحتياطية',
            userMessage:
                'فشل تحميل قائمة النسخ الاحتياطية. يرجى المحاولة مرة أخرى.',
            originalError: e,
            stackTrace: stackTrace,
            operation: 'query',
            tableName: 'backups',
          ),
        );
      }
    } on AppException catch (e, stackTrace) {
      if (mounted) {
        SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        final appException = convertToAppException(e, stackTrace: stackTrace);
        SettingsErrorHandler.handleError(
          context,
          appException,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الاستعادة', style: GoogleFonts.tajawal()),
        content: Text(
            'هل تريد استعادة هذه النسخة؟ سيتم استبدال البيانات الحالية.',
            style: GoogleFonts.tajawal()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text('استعادة', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final dbHelper = DatabaseHelper();
        await dbHelper.restoreBackup(backup['path']);
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar(
              'تم استعادة النسخة الاحتياطية بنجاح', AppColors.success);
        }
      } on sqflite.DatabaseException catch (e, stackTrace) {
        if (mounted) {
          setState(() => _isLoading = false);
          SettingsErrorHandler.handleError(
            context,
            DatabaseException(
              'خطأ في قاعدة البيانات أثناء استعادة النسخة الاحتياطية',
              userMessage: 'فشل استعادة النسخة الاحتياطية. تأكد من صحة الملف.',
              originalError: e,
              stackTrace: stackTrace,
              operation: 'restore',
            ),
          );
        }
      } on FileException catch (e, stackTrace) {
        if (mounted) {
          setState(() => _isLoading = false);
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } on AppException catch (e, stackTrace) {
        if (mounted) {
          setState(() => _isLoading = false);
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } catch (e, stackTrace) {
        if (mounted) {
          setState(() => _isLoading = false);
          final appException = convertToAppException(e, stackTrace: stackTrace);
          SettingsErrorHandler.handleError(
            context,
            appException,
            stackTrace: stackTrace,
          );
        }
      }
    }
  }

  void _showDatabaseOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.storage, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Text('إدارة قاعدة البيانات',
                style: GoogleFonts.tajawal(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(
              icon: Icons.check_circle_outline,
              title: 'فحص سلامة البيانات',
              subtitle: 'التحقق من صحة قاعدة البيانات',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                _checkDatabaseIntegrity();
              },
            ),
            const SizedBox(height: 12),
            _buildDialogOption(
              icon: Icons.cleaning_services,
              title: 'تنظيف البيانات القديمة',
              subtitle: 'حذف السجلات القديمة غير المستخدمة',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                _cleanOldData();
              },
            ),
            const SizedBox(height: 12),
            _buildDialogOption(
              icon: Icons.restart_alt,
              title: 'إعادة تعيين قاعدة البيانات',
              subtitle: 'حذف جميع البيانات (خطير)',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _resetDatabase();
              },
            ),
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

  Future<void> _checkDatabaseIntegrity() async {
    setState(() => _isLoading = true);
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // فحص سلامة قاعدة البيانات
      final result = await db.rawQuery('PRAGMA integrity_check');
      final isOk = result.isNotEmpty && result.first['integrity_check'] == 'ok';

      // فحص الجداول الأساسية
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");

      // فحص عدد السجلات في كل جدول
      final tableStats = <String, int>{};
      for (var table in tables) {
        final tableName = table['name'] as String;
        final countResult =
            await db.rawQuery('SELECT COUNT(*) FROM $tableName');
        final count = countResult.first.values.first as int;
        tableStats[tableName] = count;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOk
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOk ? Icons.check_circle : Icons.warning,
                    color: isOk ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Text('فحص قاعدة البيانات',
                    style: GoogleFonts.tajawal(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow('حالة السلامة', isOk ? 'سليمة ✓' : 'تحتاج فحص'),
                  const Divider(),
                  Text('إحصائيات الجداول:',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...tableStats.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: GoogleFonts.tajawal()),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${entry.value}',
                              style: GoogleFonts.tajawal(
                                color: AppColors.info,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('خطأ في فحص قاعدة البيانات: $e', AppColors.error);
      }
    }
  }

  Future<void> _cleanOldData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تنظيف البيانات', style: GoogleFonts.tajawal()),
        content:
            Text('هل تريد حذف البيانات القديمة؟', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تنظيف', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;

        int totalDeleted = 0;

        // حذف المبيعات القديمة (أكثر من سنة)
        final oldSalesDate = DateTime.now()
            .subtract(const Duration(days: 365))
            .toIso8601String();
        final salesDeleted = await db.delete(
          'sales',
          where: 'created_at < ?',
          whereArgs: [oldSalesDate],
        );
        totalDeleted += salesDeleted;

        // حذف السجلات القديمة (أكثر من 6 أشهر)
        final oldLogsDate = DateTime.now()
            .subtract(const Duration(days: 180))
            .toIso8601String();
        final logsDeleted = await db.delete(
          'system_logs',
          where: 'created_at < ?',
          whereArgs: [oldLogsDate],
        );
        totalDeleted += logsDeleted;

        // حذف المنتجات المنتهية (منتهية منذ أكثر من 90 يوم)
        final expiredDate =
            DateTime.now().subtract(const Duration(days: 90)).toIso8601String();
        final expiredDeleted = await db.delete(
          'products',
          where: 'expiry_date < ? AND quantity = 0',
          whereArgs: [expiredDate],
        );
        totalDeleted += expiredDeleted;

        // حذف النسخ الاحتياطية القديمة (أكثر من 3 أشهر)
        final oldBackupDate =
            DateTime.now().subtract(const Duration(days: 90)).toIso8601String();
        final backupsDeleted = await db.delete(
          'backups',
          where: 'created_at < ?',
          whereArgs: [oldBackupDate],
        );
        totalDeleted += backupsDeleted;

        // تحسين قاعدة البيانات
        await db.execute('VACUUM');

        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar(
              'تم حذف $totalDeleted سجل قديم بنجاح', AppColors.success);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar('خطأ في التنظيف: $e', AppColors.error);
        }
      }
    }
  }

  Future<void> _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('تحذير!', style: GoogleFonts.tajawal(color: AppColors.error)),
        content: Text('سيتم حذف جميع البيانات بشكل نهائي!\nهل أنت متأكد؟',
            style: GoogleFonts.tajawal()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('حذف كل شيء', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;

        // الحصول على قائمة جميع الجداول
        final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");

        // حذف جميع البيانات من كل جدول
        for (var table in tables) {
          final tableName = table['name'] as String;
          if (tableName != 'users') {
            // عدم حذف جدول المستخدمين
            await db.delete(tableName);
          }
        }

        // إعادة إنشاء البيانات الأساسية الافتراضية
        await dbHelper.database.then((db) async {
          // إعادة إدراج إعدادات الصيدلية الافتراضية
          final pharmacyExists = await db.query('pharmacy_settings', limit: 1);
          if (pharmacyExists.isEmpty) {
            await db.insert('pharmacy_settings', {
              'name_ar': 'صيدلية فارماكليك',
              'name_en': 'LaRaPill Pharmacy',
              'license_number': '',
              'phone': '',
              'mobile': '',
              'email': '',
              'website': '',
              'address': '',
              'city': '',
              'tax_number': '',
              'commercial_registration': '',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        });

        // تحسين قاعدة البيانات
        await db.execute('VACUUM');

        if (mounted) {
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle,
                        color: AppColors.success),
                  ),
                  const SizedBox(width: 12),
                  Text('تم بنجاح', style: GoogleFonts.tajawal(fontSize: 18)),
                ],
              ),
              content: Text(
                'تم إعادة تعيين قاعدة البيانات بنجاح.\nسيتم إعادة تشغيل التطبيق.',
                style: GoogleFonts.tajawal(),
                textAlign: TextAlign.center,
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // إعادة توجيه المستخدم لشاشة تسجيل الدخول
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('موافق', style: GoogleFonts.tajawal()),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar('خطأ في إعادة التعيين: $e', AppColors.error);
        }
      }
    }
  }

  void _showUsersManagement() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.people,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'إدارة المستخدمين',
                      style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final usersAsync = ref.watch(usersProvider);

                    return usersAsync.when(
                      data: (users) {
                        if (users.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'لا يوجد مستخدمون',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // تحويل UserEntity إلى Map للعرض
                        final usersMap =
                            UserEntityMapper.toDisplayMapList(users);

                        return ListView.builder(
                          itemCount: usersMap.length,
                          itemBuilder: (context, index) {
                            final user = usersMap[index];
                            return _buildUserItem(user);
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(
                                'حدث خطأ في تحميل المستخدمين',
                                style: GoogleFonts.tajawal(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                error.toString(),
                                style: GoogleFonts.tajawal(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref.invalidate(usersProvider);
                                },
                                icon: const Icon(Icons.refresh),
                                label: Text('إعادة المحاولة',
                                    style: GoogleFonts.tajawal()),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _addNewUser();
                  },
                  icon: const Icon(Icons.person_add),
                  label:
                      Text('إضافة مستخدم جديد', style: GoogleFonts.tajawal()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (user['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            user['icon'] as IconData,
            color: user['color'] as Color,
            size: 24,
          ),
        ),
        title: Text(
          user['name'],
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '@${user['username']}',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (user['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user['role'],
                style: GoogleFonts.tajawal(
                  fontSize: 10,
                  color: user['color'] as Color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 18, color: AppColors.info),
                  const SizedBox(width: 12),
                  Text('تعديل', style: GoogleFonts.tajawal()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'permissions',
              child: Row(
                children: [
                  const Icon(Icons.security,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Text('الصلاحيات', style: GoogleFonts.tajawal()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reset_password',
              child: Row(
                children: [
                  const Icon(Icons.lock_reset, size: 18, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text('إعادة تعيين كلمة المرور', style: GoogleFonts.tajawal()),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 18, color: AppColors.error),
                  const SizedBox(width: 12),
                  Text('حذف',
                      style: GoogleFonts.tajawal(color: AppColors.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            _handleUserAction(value, user);
          },
        ),
      ),
    );
  }

  void _showPharmacySettings() async {
    // تحميل إعدادات الصيدلية من قاعدة البيانات
    Map<String, dynamic>? pharmacyData;
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final result = await db.query('pharmacy_settings', limit: 1);
      if (result.isNotEmpty) {
        pharmacyData = result.first;
      }
    } catch (e) {
      pharmacyData = null;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_pharmacy,
                        color: Colors.teal, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إعدادات الصيدلية',
                          style: GoogleFonts.tajawal(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'معلومات الصيدلية والبيانات الأساسية',
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),

              // المحتوى
              Expanded(
                child: SingleChildScrollView(
                  child: _PharmacySettingsForm(
                    pharmacyData: pharmacyData,
                    onSaved: () {
                      // تحديث الـ provider لتحديث اسم الصيدلية في كل الشاشات
                      ref.invalidate(pharmacyInfoProvider);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUserAction(String action, Map<String, dynamic> user) {
    Navigator.pop(context); // إغلاق نافذة المستخدمين أولاً

    switch (action) {
      case 'edit':
        _editUser(user);
        break;
      case 'permissions':
        _editPermissions(user);
        break;
      case 'reset_password':
        _resetPassword(user);
        break;
      case 'delete':
        _deleteUser(user);
        break;
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, color: AppColors.info),
            ),
            const SizedBox(width: 12),
            Text('تعديل المستخدم', style: GoogleFonts.tajawal(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  labelStyle: GoogleFonts.tajawal(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                style: GoogleFonts.tajawal(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  labelStyle: GoogleFonts.tajawal(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                style: GoogleFonts.tajawal(),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: GoogleFonts.tajawal(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                style: GoogleFonts.tajawal(),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
            child: Text('حفظ', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        // التحقق من صحة البيانات
        if (nameController.text.trim().isEmpty) {
          throw ValidationException(
            'الاسم الكامل مطلوب',
            userMessage: 'الرجاء إدخال الاسم الكامل',
            fieldName: 'full_name',
          );
        }

        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;

        await db.update(
          'users',
          {
            'full_name': nameController.text.trim(),
            'email': emailController.text.trim().isEmpty
                ? null
                : emailController.text.trim(),
            'phone': phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [user['id']],
        );

        _showSnackBar('تم تحديث بيانات المستخدم بنجاح', AppColors.success);
        setState(() {}); // إعادة تحميل البيانات
      } on sqflite.DatabaseException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(
            context,
            DatabaseException(
              'خطأ في قاعدة البيانات أثناء تحديث المستخدم',
              userMessage: 'فشل تحديث بيانات المستخدم. يرجى المحاولة مرة أخرى.',
              originalError: e,
              stackTrace: stackTrace,
              operation: 'update',
              tableName: 'users',
            ),
          );
        }
      } on ValidationException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } on NotFoundException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } on AppException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } catch (e, stackTrace) {
        final appException = convertToAppException(e, stackTrace: stackTrace);
        if (mounted) {
          SettingsErrorHandler.handleError(
            context,
            appException,
            stackTrace: stackTrace,
          );
        }
      }
    }

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  Future<void> _editPermissions(Map<String, dynamic> user) async {
    final permissions = <String, bool>{
      'sales': false,
      'inventory': false,
      'reports': false,
      'suppliers': false,
      'users': false,
    };

    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.security, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('صلاحيات ${user['name']}',
                    style: GoogleFonts.tajawal(fontSize: 18)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: permissions.keys.map((key) {
                final names = {
                  'sales': 'المبيعات',
                  'inventory': 'المخزون',
                  'reports': 'التقارير',
                  'suppliers': 'الموردين',
                  'users': 'إدارة المستخدمين',
                };
                return CheckboxListTile(
                  title: Text(names[key]!, style: GoogleFonts.tajawal()),
                  value: permissions[key],
                  onChanged: (value) {
                    setState(() {
                      permissions[key] = value ?? false;
                    });
                  },
                  activeColor: AppColors.primary,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.tajawal()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, permissions),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: Text('حفظ', style: GoogleFonts.tajawal()),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        final selectedPermissions =
            result.entries.where((e) => e.value).map((e) => e.key).toList();

        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;

        await db.update(
          'users',
          {
            'permissions': selectedPermissions.join(','),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [user['id']],
        );

        _showSnackBar('تم تحديث الصلاحيات بنجاح', AppColors.success);
      } catch (e) {
        _showSnackBar('خطأ في تحديث الصلاحيات: $e', AppColors.error);
      }
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_reset, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('إعادة تعيين كلمة المرور',
                  style: GoogleFonts.tajawal(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إعادة تعيين كلمة المرور للمستخدم: ${user['name']}',
                style: GoogleFonts.tajawal()),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                labelStyle: GoogleFonts.tajawal(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
              style: GoogleFonts.tajawal(),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                labelStyle: GoogleFonts.tajawal(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              style: GoogleFonts.tajawal(),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                        style: GoogleFonts.tajawal()),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (passwordController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('كلمات المرور غير متطابقة',
                        style: GoogleFonts.tajawal()),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('إعادة تعيين', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;

        // تشفير كلمة المرور الجديدة
        final hashedPassword = PasswordHasher.hash(passwordController.text);

        await db.update(
          'users',
          {
            'password_hash': hashedPassword,
            'force_password_change': 1,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [user['id']],
        );

        _showSnackBar('تم إعادة تعيين كلمة المرور بنجاح', AppColors.success);
      } on sqflite.DatabaseException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(
            context,
            DatabaseException(
              'خطأ في قاعدة البيانات أثناء إعادة تعيين كلمة المرور',
              userMessage:
                  'فشل إعادة تعيين كلمة المرور. يرجى المحاولة مرة أخرى.',
              originalError: e,
              stackTrace: stackTrace,
              operation: 'update',
              tableName: 'users',
            ),
          );
        }
      } on ValidationException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } on NotFoundException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } on AppException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } catch (e, stackTrace) {
        final appException = convertToAppException(e, stackTrace: stackTrace);
        if (mounted) {
          SettingsErrorHandler.handleError(
            context,
            appException,
            stackTrace: stackTrace,
          );
        }
      }
    }

    passwordController.dispose();
    confirmController.dispose();
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    if (user['username'] == 'admin') {
      _showSnackBar('لا يمكن حذف مدير النظام', AppColors.error);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text('تأكيد الحذف', style: GoogleFonts.tajawal(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من حذف المستخدم "${user['name']}"؟',
                style: GoogleFonts.tajawal(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('هذا الإجراء لا يمكن التراجع عنه.',
                style:
                    GoogleFonts.tajawal(fontSize: 12, color: AppColors.error),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('حذف', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;

        await db.delete(
          'users',
          where: 'id = ?',
          whereArgs: [user['id']],
        );

        _showSnackBar('تم حذف المستخدم بنجاح', AppColors.success);
        setState(() {}); // إعادة تحميل البيانات
      } on sqflite.DatabaseException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(
            context,
            DatabaseException(
              'خطأ في قاعدة البيانات أثناء حذف المستخدم',
              userMessage: 'فشل حذف المستخدم. يرجى المحاولة مرة أخرى.',
              originalError: e,
              stackTrace: stackTrace,
              operation: 'delete',
              tableName: 'users',
            ),
          );
        }
      } on BusinessRuleException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } on NotFoundException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } on AppException catch (e, stackTrace) {
        if (mounted) {
          SettingsErrorHandler.handleError(context, e, stackTrace: stackTrace);
        }
      } catch (e, stackTrace) {
        final appException = convertToAppException(e, stackTrace: stackTrace);
        if (mounted) {
          SettingsErrorHandler.handleError(
            context,
            appException,
            stackTrace: stackTrace,
          );
        }
      }
    }
  }

  Future<void> _addNewUser() async {
    final usernameController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'cashier';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_add, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text('إضافة مستخدم جديد',
                  style: GoogleFonts.tajawal(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم *',
                    labelStyle: GoogleFonts.tajawal(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.account_circle),
                  ),
                  style: GoogleFonts.tajawal(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل *',
                    labelStyle: GoogleFonts.tajawal(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  style: GoogleFonts.tajawal(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    labelStyle: GoogleFonts.tajawal(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  style: GoogleFonts.tajawal(),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    labelStyle: GoogleFonts.tajawal(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  style: GoogleFonts.tajawal(),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور *',
                    labelStyle: GoogleFonts.tajawal(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  style: GoogleFonts.tajawal(),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'الدور الوظيفي *',
                    labelStyle: GoogleFonts.tajawal(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.work),
                  ),
                  style: GoogleFonts.tajawal(color: Colors.black),
                  items: [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('مدير', style: GoogleFonts.tajawal()),
                    ),
                    DropdownMenuItem(
                      value: 'pharmacist',
                      child: Text('صيدلي', style: GoogleFonts.tajawal()),
                    ),
                    DropdownMenuItem(
                      value: 'cashier',
                      child: Text('كاشير', style: GoogleFonts.tajawal()),
                    ),
                    DropdownMenuItem(
                      value: 'manager',
                      child: Text('مدير فرع', style: GoogleFonts.tajawal()),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: GoogleFonts.tajawal()),
            ),
            ElevatedButton(
              onPressed: () {
                if (usernameController.text.isEmpty ||
                    nameController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('الرجاء ملء الحقول المطلوبة',
                          style: GoogleFonts.tajawal()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                          style: GoogleFonts.tajawal()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('إضافة', style: GoogleFonts.tajawal()),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;

        // تشفير كلمة المرور قبل التخزين
        final hashedPassword = PasswordHasher.hash(passwordController.text);

        await db.insert('users', {
          'username': usernameController.text,
          'full_name': nameController.text,
          'email': emailController.text.isEmpty ? null : emailController.text,
          'phone': phoneController.text.isEmpty ? null : phoneController.text,
          'password_hash': hashedPassword,
          'role': selectedRole,
          'is_active': 1,
          'force_password_change': 0,
          'created_at': DateTime.now().toIso8601String(),
        });

        _showSnackBar('تم إضافة المستخدم بنجاح', AppColors.success);
        setState(() {}); // إعادة تحميل البيانات
      } catch (e) {
        _showSnackBar('خطأ في إضافة المستخدم: $e', AppColors.error);
      }
    }

    usernameController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline, color: AppColors.info),
            ),
            const SizedBox(width: 12),
            Text('حول التطبيق', style: GoogleFonts.tajawal(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نظام إدارة الصيدليات',
                style: GoogleFonts.tajawal(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('الإصدار', '1.0.0'),
            _buildInfoRow('تاريخ البناء', '2025-10-13'),
            _buildInfoRow('المطور', 'فريق التطوير'),
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

  Widget _buildDialogOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
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
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.tajawal(color: Colors.grey[600])),
          Text(value, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    if (color == AppColors.success) {
      AppToast.success(context, message);
    } else if (color == AppColors.error) {
      AppToast.error(context, message);
    } else if (color == AppColors.warning) {
      AppToast.warning(context, message);
    } else {
      AppToast.info(context, message);
    }
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.tajawal(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget لنموذج إعدادات الصيدلية
class _PharmacySettingsForm extends StatefulWidget {
  final Map<String, dynamic>? pharmacyData;
  final VoidCallback? onSaved;

  const _PharmacySettingsForm({this.pharmacyData, this.onSaved});

  @override
  State<_PharmacySettingsForm> createState() => _PharmacySettingsFormState();
}

class _PharmacySettingsFormState extends State<_PharmacySettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameEnController;
  late TextEditingController _licenseController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _taxNumberController;
  late TextEditingController _commercialRegController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.pharmacyData ?? {};

    _nameController =
        TextEditingController(text: data['name_ar'] ?? 'صيدلية فارماكليك');
    _nameEnController =
        TextEditingController(text: data['name_en'] ?? 'LaRaPill Pharmacy');
    _licenseController =
        TextEditingController(text: data['license_number'] ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _mobileController = TextEditingController(text: data['mobile'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _websiteController = TextEditingController(text: data['website'] ?? '');
    _addressController = TextEditingController(text: data['address'] ?? '');
    _cityController = TextEditingController(text: data['city'] ?? '');
    _taxNumberController =
        TextEditingController(text: data['tax_number'] ?? '');
    _commercialRegController =
        TextEditingController(text: data['commercial_registration'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _taxNumberController.dispose();
    _commercialRegController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات أساسية
          _buildSectionTitle('المعلومات الأساسية', Icons.info_outline),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _nameController,
            label: 'اسم الصيدلية (عربي)',
            icon: Icons.local_pharmacy,
            required: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _nameEnController,
            label: 'اسم الصيدلية (English)',
            icon: Icons.local_pharmacy,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _licenseController,
            label: 'رقم الترخيص',
            icon: Icons.badge,
          ),

          const SizedBox(height: 24),

          // معلومات الاتصال
          _buildSectionTitle('معلومات الاتصال', Icons.contact_phone),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            label: 'الهاتف',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _mobileController,
            label: 'الجوال',
            icon: Icons.smartphone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _websiteController,
            label: 'الموقع الإلكتروني',
            icon: Icons.language,
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: 24),

          // العنوان
          _buildSectionTitle('العنوان', Icons.location_on),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: 'العنوان',
            icon: Icons.home,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _cityController,
            label: 'المدينة',
            icon: Icons.location_city,
          ),

          const SizedBox(height: 24),

          // المعلومات الضريبية
          _buildSectionTitle('المعلومات الضريبية', Icons.receipt_long),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _taxNumberController,
            label: 'الرقم الضريبي',
            icon: Icons.money,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _commercialRegController,
            label: 'رقم السجل التجاري',
            icon: Icons.business,
          ),

          const SizedBox(height: 32),

          // أزرار الحفظ والإلغاء
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', style: GoogleFonts.tajawal()),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('حفظ الإعدادات', style: GoogleFonts.tajawal()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        labelStyle: GoogleFonts.tajawal(),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: GoogleFonts.tajawal(),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'هذا الحقل مطلوب';
              }
              return null;
            }
          : null,
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final data = {
        'name_ar': _nameController.text.trim(),
        'name_en': _nameEnController.text.trim(),
        'license_number': _licenseController.text.trim(),
        'phone': _phoneController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'tax_number': _taxNumberController.text.trim(),
        'commercial_registration': _commercialRegController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // التحقق من وجود سجل
      final existing = await db.query('pharmacy_settings', limit: 1);

      if (existing.isEmpty) {
        // إدراج سجل جديد
        data['created_at'] = DateTime.now().toIso8601String();
        await db.insert('pharmacy_settings', data);
      } else {
        // تحديث السجل الموجود
        await db.update(
          'pharmacy_settings',
          data,
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }

      // مسح الكاش ليتم إعادة تحميل البيانات
      await _clearPharmacyCache();

      if (mounted) {
        // تحديث الـ providers
        widget.onSaved?.call();

        Navigator.pop(context);
        AppToast.success(context, 'تم حفظ إعدادات الصيدلية بنجاح');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'خطأ في حفظ الإعدادات: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // مسح كاش إعدادات الصيدلية
  Future<void> _clearPharmacyCache() async {
    try {
      PharmacySettingsService.instance.clearCache();
    } catch (e) {
      // تجاهل الخطأ
    }
  }
}
