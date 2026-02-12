/// Audit Logs Drift DAO
library audit_log_drift_dao;

import 'package:drift/drift.dart';
import '../../../../../core/database/drift/app_database.dart';
import 'package:uuid/uuid.dart';

part 'audit_log_drift_dao.g.dart';

@DriftAccessor(tables: [AuditLogs])
class AuditLogDriftDao extends DatabaseAccessor<AppDatabase>
    with _$AuditLogDriftDaoMixin {
  AuditLogDriftDao(super.db);

  /// Log a generic action
  Future<void> logAction({
    required String actionType,
    required String actionName,
    required String severity,
    required String userId,
    String? userName,
    String? entityType,
    String? entityId,
    String? description,
    String? metadata,
    bool isSuccess = true,
    String? errorMessage,
  }) {
    return into(auditLogs).insert(
      AuditLogsCompanion.insert(
        id: const Uuid().v4(),
        actionType: actionType,
        actionName: actionName,
        severity: severity,
        userId: userId,
        userName: Value(userName),
        entityType: Value(entityType),
        entityId: Value(entityId),
        description: Value(description),
        metadata: Value(metadata),
        isSuccess: Value(isSuccess),
        errorMessage: Value(errorMessage),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Specialized: Log Sale creation
  Future<void> logSaleCreate(
    String userId,
    String userName,
    String saleId,
    double total, {
    String? customerName,
    int? itemsCount,
  }) {
    return logAction(
      actionType: 'CREATE',
      actionName: 'فاتورة مبيعات',
      severity: 'info',
      userId: userId,
      userName: userName,
      entityType: 'sale',
      entityId: saleId,
      description:
          'بيع بقيمة $total للعميل ${customerName ?? "نقدي"} ($itemsCount مواد)',
    );
  }

  /// Specialized: Log Database Reset (CRITICAL operation)
  Future<void> logDatabaseReset({
    required String userId,
    required String userName,
    required String operationType, // 'reset_database' or 'clear_all_data'
    String? backupFileName,
    Map<String, dynamic>? additionalMetadata,
  }) {
    final metadata = {
      'timestamp': DateTime.now().toIso8601String(),
      if (backupFileName != null) 'backup_file': backupFileName,
      if (additionalMetadata != null) ...additionalMetadata,
    };

    return logAction(
      actionType: 'DELETE',
      actionName: operationType == 'reset_database'
          ? 'إعادة تعيين قاعدة البيانات'
          : 'مسح جميع البيانات',
      severity: 'critical', // 🔴 CRITICAL operation!
      userId: userId,
      userName: userName,
      entityType: 'system',
      entityId: 'database',
      description: operationType == 'reset_database'
          ? 'تم إعادة تعيين قاعدة البيانات (حذف البيانات مع الاحتفاظ بالمستخدمين)'
          : 'تم مسح جميع البيانات والكاش',
      metadata: metadata.isNotEmpty ? metadata.toString() : null,
    );
  }

  /// Get recent logs
  Future<List<AuditLogEntry>> getRecentLogs({int limit = 100}) {
    return (select(auditLogs)
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get logs with optional filtering
  Future<List<AuditLogEntry>> getLogsFiltered({
    String? userId,
    String? actionType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    final query = select(auditLogs);

    // Build where clause dynamically
    if (userId != null ||
        actionType != null ||
        startDate != null ||
        endDate != null) {
      query.where((l) {
        Expression<bool> condition = const Constant(true);

        if (userId != null) {
          condition = condition & l.userId.equals(userId);
        }
        if (actionType != null) {
          condition = condition & l.actionType.equals(actionType);
        }
        if (startDate != null) {
          condition = condition & l.createdAt.isBiggerOrEqualValue(startDate);
        }
        if (endDate != null) {
          condition = condition & l.createdAt.isSmallerOrEqualValue(endDate);
        }

        return condition;
      });
    }

    return (query
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit))
        .get();
  }
}
