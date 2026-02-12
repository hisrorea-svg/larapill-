/// System Logs Drift DAO - Type-safe database access for system logs
library system_logs_drift_dao;

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/database/drift/app_database.dart';
import '../../../../../core/database/drift/database_provider.dart';

part 'system_logs_drift_dao.g.dart';

/// DAO for SystemLogs table with type-safe queries
@DriftAccessor(tables: [SystemLogs])
class SystemLogsDriftDao extends DatabaseAccessor<AppDatabase>
    with _$SystemLogsDriftDaoMixin {
  SystemLogsDriftDao(super.db);

  // 📝 WRITE OPERATIONS

  /// Log a debug message
  Future<void> debug(
    String category,
    String title, {
    Map<String, dynamic>? details,
    String? userId,
    String? userName,
  }) async {
    await _insertLog(
      level: 'debug',
      category: category,
      title: title,
      details: details,
      userId: userId,
      userName: userName,
    );
  }

  /// Log an info message
  Future<void> info(
    String category,
    String title, {
    Map<String, dynamic>? details,
    String? userId,
    String? userName,
  }) async {
    await _insertLog(
      level: 'info',
      category: category,
      title: title,
      details: details,
      userId: userId,
      userName: userName,
    );
  }

  /// Log a warning
  Future<void> warning(
    String category,
    String title, {
    Map<String, dynamic>? details,
    String? userId,
    String? userName,
  }) async {
    await _insertLog(
      level: 'warning',
      category: category,
      title: title,
      details: details,
      userId: userId,
      userName: userName,
    );
  }

  /// Log an error
  Future<void> error(
    String category,
    String title, {
    Object? error,
    StackTrace? stackTrace,
    String? errorCode,
    Map<String, dynamic>? details,
    String? userId,
    String? userName,
  }) async {
    await _insertLog(
      level: 'error',
      category: category,
      title: title,
      details: details,
      error: error,
      stackTrace: stackTrace,
      errorCode: errorCode,
      userId: userId,
      userName: userName,
    );
  }

  /// Log a fatal error
  Future<void> fatal(
    String category,
    String title, {
    Object? error,
    StackTrace? stackTrace,
    String? errorCode,
    Map<String, dynamic>? details,
    String? userId,
    String? userName,
  }) async {
    await _insertLog(
      level: 'fatal',
      category: category,
      title: title,
      details: details,
      error: error,
      stackTrace: stackTrace,
      errorCode: errorCode,
      userId: userId,
      userName: userName,
    );
  }

  /// Insert a log entry
  Future<void> _insertLog({
    required String level,
    required String category,
    required String title,
    Map<String, dynamic>? details,
    Object? error,
    StackTrace? stackTrace,
    String? errorCode,
    String? userId,
    String? userName,
  }) async {
    try {
      // Add error details if provided
      final Map<String, dynamic> logDetails = {...?details};
      if (error != null) {
        logDetails['error'] = error.toString();
      }

      await into(systemLogs).insert(
        SystemLogsCompanion.insert(
          id: const Uuid().v4(),
          level: level,
          category: category,
          title: title,
          details: logDetails.isNotEmpty
              ? Value(jsonEncode(logDetails))
              : const Value.absent(),
          userId: userId != null ? Value(userId) : const Value.absent(),
          userName: userName != null ? Value(userName) : const Value.absent(),
          errorCode:
              errorCode != null ? Value(errorCode) : const Value.absent(),
          stackTrace: stackTrace != null
              ? Value(stackTrace.toString())
              : const Value.absent(),
          createdAt: DateTime.now(),
        ),
      );

      // Also log to console for debugging
      developer.log(
        '[$level][$category] $title',
        name: 'SystemLogs',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (e) {
      // Don't throw - logging should never crash the app
      developer.log(
        'Failed to write log: $e',
        name: 'SystemLogs',
        error: e,
      );
    }
  }

  // 📖 READ OPERATIONS

  /// Get all logs ordered by date desc
  Future<List<SystemLogEntry>> getAllLogs({int limit = 100}) {
    return (select(systemLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get logs by level
  Future<List<SystemLogEntry>> getLogsByLevel(
    String level, {
    int limit = 100,
  }) {
    return (select(systemLogs)
          ..where((t) => t.level.equals(level))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get logs by category
  Future<List<SystemLogEntry>> getLogsByCategory(
    String category, {
    int limit = 100,
  }) {
    return (select(systemLogs)
          ..where((t) => t.category.equals(category))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get logs for a specific user
  Future<List<SystemLogEntry>> getLogsByUser(
    String userId, {
    int limit = 100,
  }) {
    return (select(systemLogs)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get logs within date range
  Future<List<SystemLogEntry>> getLogsInDateRange(
    DateTime start,
    DateTime end, {
    int limit = 1000,
  }) {
    return (select(systemLogs)
          ..where((t) => t.createdAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  // 📊 STATISTICS

  /// Get log count by level
  Future<Map<String, int>> getLogCountByLevel() async {
    final levels = ['debug', 'info', 'warning', 'error', 'fatal'];
    final result = <String, int>{};

    for (final level in levels) {
      final count = await (selectOnly(systemLogs)
            ..addColumns([systemLogs.id.count()])
            ..where(systemLogs.level.equals(level)))
          .map((row) => row.read(systemLogs.id.count()) ?? 0)
          .getSingle();
      result[level] = count;
    }

    return result;
  }

  /// Get recent errors count
  Future<int> getRecentErrorsCount({int hours = 24}) async {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return await (selectOnly(systemLogs)
          ..addColumns([systemLogs.id.count()])
          ..where(systemLogs.level.isIn(['error', 'fatal']))
          ..where(systemLogs.createdAt.isBiggerOrEqualValue(cutoff)))
        .map((row) => row.read(systemLogs.id.count()) ?? 0)
        .getSingle();
  }

  // 🗑️ CLEANUP

  /// Delete logs older than specified days
  Future<int> deleteOldLogs(int daysToKeep) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    return await (delete(systemLogs)
          ..where((t) => t.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Delete all logs (use with caution)
  Future<int> deleteAllLogs() async {
    return await delete(systemLogs).go();
  }
}

/// Provider for SystemLogsDriftDao
final systemLogsDriftDaoProvider = Provider<SystemLogsDriftDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SystemLogsDriftDao(db);
});
