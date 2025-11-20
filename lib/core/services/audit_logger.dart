import 'dart:convert';
import 'dart:developer' as developer;
import '../../database/database_helper.dart';
import 'package:uuid/uuid.dart';

// ==================== أنواع العمليات ====================

/// أنواع العمليات القابلة للتسجيل
enum AuditActionType {
  // المصادقة والجلسات
  login('login', 'تسجيل دخول', AuditSeverity.info),
  logout('logout', 'تسجيل خروج', AuditSeverity.info),
  loginFailed('login_failed', 'محاولة دخول فاشلة', AuditSeverity.warning),
  sessionExpired('session_expired', 'انتهاء الجلسة', AuditSeverity.info),
  passwordChange('password_change', 'تغيير كلمة المرور', AuditSeverity.info),
  passwordReset(
      'password_reset', 'إعادة تعيين كلمة المرور', AuditSeverity.warning),

  // المستخدمين
  userCreate('user_create', 'إنشاء مستخدم', AuditSeverity.important),
  userUpdate('user_update', 'تحديث مستخدم', AuditSeverity.info),
  userDelete('user_delete', 'حذف مستخدم', AuditSeverity.critical),
  userActivate('user_activate', 'تفعيل مستخدم', AuditSeverity.info),
  userDeactivate(
      'user_deactivate', 'إلغاء تفعيل مستخدم', AuditSeverity.warning),
  permissionChange(
      'permission_change', 'تغيير صلاحيات', AuditSeverity.important),

  // المنتجات
  productCreate('product_create', 'إضافة منتج', AuditSeverity.info),
  productUpdate('product_update', 'تحديث منتج', AuditSeverity.info),
  productDelete('product_delete', 'حذف منتج', AuditSeverity.warning),
  productPriceChange(
      'product_price_change', 'تغيير سعر منتج', AuditSeverity.important),
  stockAdjustment('stock_adjustment', 'تعديل مخزون', AuditSeverity.important),

  // المبيعات
  saleCreate('sale_create', 'إنشاء مبيعة', AuditSeverity.info),
  saleUpdate('sale_update', 'تحديث مبيعة', AuditSeverity.warning),
  saleDelete('sale_delete', 'حذف مبيعة', AuditSeverity.critical),
  saleReturn('sale_return', 'مرتجع مبيعة', AuditSeverity.info),

  // المشتريات
  purchaseCreate('purchase_create', 'إنشاء طلب شراء', AuditSeverity.info),
  purchaseUpdate('purchase_update', 'تحديث طلب شراء', AuditSeverity.info),
  purchaseApprove(
      'purchase_approve', 'اعتماد طلب شراء', AuditSeverity.important),
  purchaseReceive(
      'purchase_receive', 'استلام طلب شراء', AuditSeverity.important),

  // الديون
  debtCreate('debt_create', 'تسجيل دين', AuditSeverity.info),
  debtPayment('debt_payment', 'تسديد دين', AuditSeverity.info),
  debtWriteoff('debt_writeoff', 'إلغاء دين', AuditSeverity.critical), // النظام
  settingsChange('settings_change', 'تغيير إعدادات', AuditSeverity.important),
  databaseBackup('database_backup', 'نسخ احتياطي', AuditSeverity.important),
  databaseRestore('database_restore', 'استعادة نسخة', AuditSeverity.critical),
  dataExport('data_export', 'تصدير بيانات', AuditSeverity.warning),
  dataImport('data_import', 'استيراد بيانات', AuditSeverity.warning),

  // أمان
  securityBreach('security_breach', 'خرق أمني محتمل', AuditSeverity.critical),
  unauthorizedAccess(
      'unauthorized_access', 'محاولة وصول غير مصرح', AuditSeverity.critical),
  suspiciousActivity(
      'suspicious_activity', 'نشاط مشبوه', AuditSeverity.warning),
  ;

  const AuditActionType(this.code, this.displayName, this.severity);
  final String code;
  final String displayName;
  final AuditSeverity severity;
}

/// مستوى خطورة العملية
enum AuditSeverity {
  info('info', 'معلومات', 0),
  warning('warning', 'تحذير', 1),
  important('important', 'مهم', 2),
  critical('critical', 'حرج', 3);

  const AuditSeverity(this.code, this.displayName, this.level);
  final String code;
  final String displayName;
  final int level;
}

// ==================== AuditLogger Class ====================

/// 📝 نظام تسجيل شامل للعمليات الحساسة (Audit Logger)
/// يسجل جميع العمليات المهمة مع تفاصيل كاملة للمراجعة والأمان
class AuditLogger {
  static final AuditLogger _instance = AuditLogger._internal();
  factory AuditLogger() => _instance;
  AuditLogger._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  // ==================== تسجيل العمليات ====================  /// تسجيل عملية في سجل التدقيق
  Future<String> log({
    required AuditActionType action,
    required String userId,
    String? userName,
    String? entityType, // نوع الكيان (product, sale, user, etc.)
    String? entityId, // معرف الكيان
    String? description, // وصف تفصيلي
    Map<String, dynamic>? metadata, // بيانات إضافية
    String? ipAddress,
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    try {
      final db = await _dbHelper.database;
      final auditId = _uuid.v4();
      final now = DateTime.now();

      final auditLog = {
        'id': auditId,
        'action_type': action.code,
        'action_name': action.displayName,
        'severity': action.severity.code,
        'user_id': userId,
        'user_name': userName,
        'entity_type': entityType,
        'entity_id': entityId,
        'description': description,
        'metadata': metadata != null ? jsonEncode(metadata) : null,
        'ip_address': ipAddress ?? '127.0.0.1',
        'is_success': isSuccess ? 1 : 0,
        'error_message': errorMessage,
        'created_at': now.toIso8601String(),
      };

      await db.insert('audit_logs', auditLog);

      // تسجيل في الـ console للتطوير
      final icon = _getSeverityIcon(action.severity);
      final status = isSuccess ? '✅' : '❌';
      developer.log(
        '$icon $status ${action.displayName} - المستخدم: ${userName ?? userId}${description != null ? ' - $description' : ''}',
        name: 'AuditLogger',
        level: action.severity.level * 300,
        time: now,
      );

      return auditId;
    } catch (e) {
      developer.log(
        '❌ فشل تسجيل العملية في Audit Log: $e',
        name: 'AuditLogger',
        error: e,
      );
      rethrow;
    }
  }

  // ==================== دوال مساعدة سريعة ====================

  /// تسجيل عملية تسجيل دخول
  Future<void> logLogin(String userId, String userName, {String? ipAddress}) {
    return log(
      action: AuditActionType.login,
      userId: userId,
      userName: userName,
      description: 'تسجيل دخول ناجح للمستخدم $userName',
      ipAddress: ipAddress,
    );
  }

  /// تسجيل محاولة دخول فاشلة
  Future<void> logFailedLogin(String username,
      {String? reason, String? ipAddress}) {
    return log(
      action: AuditActionType.loginFailed,
      userId: 'unknown',
      userName: username,
      description: 'محاولة دخول فاشلة: $username',
      errorMessage: reason,
      ipAddress: ipAddress,
      isSuccess: false,
    );
  }

  /// تسجيل عملية تسجيل خروج
  Future<void> logLogout(String userId, String userName) {
    return log(
      action: AuditActionType.logout,
      userId: userId,
      userName: userName,
      description: 'تسجيل خروج للمستخدم $userName',
    );
  }

  /// تسجيل إنشاء منتج
  Future<void> logProductCreate(
    String userId,
    String userName,
    String productId,
    String productName, {
    Map<String, dynamic>? details,
  }) {
    return log(
      action: AuditActionType.productCreate,
      userId: userId,
      userName: userName,
      entityType: 'product',
      entityId: productId,
      description: 'إضافة منتج جديد: $productName',
      metadata: details,
    );
  }

  /// تسجيل تحديث منتج
  Future<void> logProductUpdate(
    String userId,
    String userName,
    String productId,
    String productName, {
    Map<String, dynamic>? changes,
  }) {
    return log(
      action: AuditActionType.productUpdate,
      userId: userId,
      userName: userName,
      entityType: 'product',
      entityId: productId,
      description: 'تحديث منتج: $productName',
      metadata: changes,
    );
  }

  /// تسجيل تغيير سعر منتج
  Future<void> logPriceChange(
    String userId,
    String userName,
    String productId,
    String productName,
    double oldPrice,
    double newPrice,
  ) {
    return log(
      action: AuditActionType.productPriceChange,
      userId: userId,
      userName: userName,
      entityType: 'product',
      entityId: productId,
      description: 'تغيير سعر $productName من $oldPrice إلى $newPrice',
      metadata: {
        'old_price': oldPrice,
        'new_price': newPrice,
        'change_amount': newPrice - oldPrice,
        'change_percentage':
            ((newPrice - oldPrice) / oldPrice * 100).toStringAsFixed(2),
      },
    );
  }

  /// تسجيل تعديل مخزون
  Future<void> logStockAdjustment(
    String userId,
    String userName,
    String productId,
    String productName,
    double oldStock,
    double newStock,
    String reason,
  ) {
    return log(
      action: AuditActionType.stockAdjustment,
      userId: userId,
      userName: userName,
      entityType: 'product',
      entityId: productId,
      description:
          'تعديل مخزون $productName من $oldStock إلى $newStock - السبب: $reason',
      metadata: {
        'old_stock': oldStock,
        'new_stock': newStock,
        'adjustment': newStock - oldStock,
        'reason': reason,
      },
    );
  }

  /// تسجيل إنشاء مبيعة
  Future<void> logSaleCreate(
    String userId,
    String userName,
    String saleId,
    double totalAmount, {
    String? customerName,
    int? itemsCount,
  }) {
    return log(
      action: AuditActionType.saleCreate,
      userId: userId,
      userName: userName,
      entityType: 'sale',
      entityId: saleId,
      description:
          'إنشاء مبيعة بمبلغ $totalAmount د.ع${customerName != null ? ' للعميل $customerName' : ''}',
      metadata: {
        'total_amount': totalAmount,
        'customer_name': customerName,
        'items_count': itemsCount,
      },
    );
  }

  /// تسجيل حذف مبيعة
  Future<void> logSaleDelete(
    String userId,
    String userName,
    String saleId,
    double totalAmount,
    String reason,
  ) {
    return log(
      action: AuditActionType.saleDelete,
      userId: userId,
      userName: userName,
      entityType: 'sale',
      entityId: saleId,
      description: 'حذف مبيعة بمبلغ $totalAmount د.ع - السبب: $reason',
      metadata: {
        'total_amount': totalAmount,
        'reason': reason,
      },
    );
  }

  /// تسجيل إنشاء مستخدم
  Future<void> logUserCreate(
    String creatorId,
    String creatorName,
    String newUserId,
    String newUsername,
    String role,
  ) {
    return log(
      action: AuditActionType.userCreate,
      userId: creatorId,
      userName: creatorName,
      entityType: 'user',
      entityId: newUserId,
      description: 'إنشاء مستخدم جديد: $newUsername بدور $role',
      metadata: {
        'new_username': newUsername,
        'role': role,
      },
    );
  }

  /// تسجيل تغيير صلاحيات
  Future<void> logPermissionChange(
    String userId,
    String userName,
    String targetUserId,
    String targetUsername,
    List<String> oldPermissions,
    List<String> newPermissions,
  ) {
    final added =
        newPermissions.where((p) => !oldPermissions.contains(p)).toList();
    final removed =
        oldPermissions.where((p) => !newPermissions.contains(p)).toList();

    return log(
      action: AuditActionType.permissionChange,
      userId: userId,
      userName: userName,
      entityType: 'user',
      entityId: targetUserId,
      description: 'تغيير صلاحيات المستخدم $targetUsername',
      metadata: {
        'target_username': targetUsername,
        'added_permissions': added,
        'removed_permissions': removed,
        'old_permissions': oldPermissions,
        'new_permissions': newPermissions,
      },
    );
  }

  /// تسجيل نشاط مشبوه
  Future<void> logSuspiciousActivity(
    String userId,
    String description, {
    String? ipAddress,
    Map<String, dynamic>? details,
  }) {
    return log(
      action: AuditActionType.suspiciousActivity,
      userId: userId,
      description: description,
      metadata: details,
      ipAddress: ipAddress,
    );
  }

  /// تسجيل نسخ احتياطي
  Future<void> logDatabaseBackup(
    String userId,
    String userName,
    String backupPath, {
    int? fileSize,
  }) {
    return log(
      action: AuditActionType.databaseBackup,
      userId: userId,
      userName: userName,
      description: 'إنشاء نسخة احتياطية: $backupPath',
      metadata: {
        'backup_path': backupPath,
        'file_size': fileSize,
      },
    );
  }

  // ==================== استعلام السجلات ====================

  /// جلب سجلات التدقيق حسب المعايير
  Future<List<Map<String, dynamic>>> getLogs({
    String? userId,
    AuditActionType? actionType,
    AuditSeverity? minSeverity,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final db = await _dbHelper.database;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        whereClause += ' AND user_id = ?';
        whereArgs.add(userId);
      }

      if (actionType != null) {
        whereClause += ' AND action_type = ?';
        whereArgs.add(actionType.code);
      }

      if (minSeverity != null) {
        final severities = AuditSeverity.values
            .where((s) => s.level >= minSeverity.level)
            .map((s) => "'${s.code}'")
            .join(',');
        whereClause += ' AND severity IN ($severities)';
      }

      if (startDate != null) {
        whereClause += ' AND created_at >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND created_at <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final results = await db.query(
        'audit_logs',
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return results;
    } catch (e) {
      developer.log('❌ خطأ في جلب سجلات التدقيق: $e', name: 'AuditLogger');
      return [];
    }
  }

  /// حصول على إحصائيات السجلات
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (startDate != null) {
        whereClause += ' AND created_at >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND created_at <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM audit_logs WHERE $whereClause',
        whereArgs.isEmpty ? null : whereArgs,
      );

      final bySeverity = await db.rawQuery(
        'SELECT severity, COUNT(*) as count FROM audit_logs WHERE $whereClause GROUP BY severity',
        whereArgs.isEmpty ? null : whereArgs,
      );

      final byAction = await db.rawQuery(
        'SELECT action_type, action_name, COUNT(*) as count FROM audit_logs WHERE $whereClause GROUP BY action_type ORDER BY count DESC LIMIT 10',
        whereArgs.isEmpty ? null : whereArgs,
      );

      return {
        'total_logs': (totalResult.first['count'] as int?) ?? 0,
        'by_severity': bySeverity,
        'top_actions': byAction,
      };
    } catch (e) {
      developer.log('❌ خطأ في جلب إحصائيات التدقيق: $e', name: 'AuditLogger');
      return {};
    }
  }

  // ==================== دوال مساعدة ====================

  String _getSeverityIcon(AuditSeverity severity) {
    switch (severity) {
      case AuditSeverity.info:
        return 'ℹ️';
      case AuditSeverity.warning:
        return '⚠️';
      case AuditSeverity.important:
        return '🔔';
      case AuditSeverity.critical:
        return '🔴';
    }
  }
}
