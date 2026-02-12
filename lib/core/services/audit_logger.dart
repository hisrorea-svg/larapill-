import 'dart:convert';
import 'dart:developer' as developer;
import '../database/drift/daos/audit_log_drift_dao.dart';
import '../database/drift/app_database.dart';
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
  static AuditLogger? _instance;
  static AuditLogDriftDao? _dao;

  final Uuid _uuid = const Uuid();

  factory AuditLogger() {
    _instance ??= AuditLogger._internal();
    return _instance!;
  }

  AuditLogger._internal();

  /// Initialize with DAO from DI
  static void init(AuditLogDriftDao dao) {
    _dao = dao;
  }

  // ==================== تسجيل العمليات ====================

  /// تسجيل عملية في سجل التدقيق
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
    if (_dao == null) {
      throw Exception('AuditLogger not initialized. Call init() first.');
    }

    try {
      final auditId = _uuid.v4();
      final now = DateTime.now();

      await _dao!.logAction(
        actionType: action.code,
        actionName: action.displayName,
        severity: action.severity.code,
        userId: userId,
        userName: userName,
        entityType: entityType,
        entityId: entityId,
        description: description,
        metadata: metadata != null ? jsonEncode(metadata) : null,
        isSuccess: isSuccess,
        errorMessage: errorMessage,
      );

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
  Future<List<AuditLogEntry>> getLogs({
    String? userId,
    String? actionType,
    AuditSeverity? minSeverity,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    if (_dao == null) return [];

    try {
      return await _dao!.getLogsFiltered(
        userId: userId,
        actionType: actionType,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      developer.log('❌ خطأ في جلب سجلات التدقيق: $e', name: 'AuditLogger');
      return [];
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
