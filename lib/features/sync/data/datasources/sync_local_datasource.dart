import 'dart:async';
import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';

import '../../../../database/database_helper.dart';
import '../models/models.dart';

/// Interface for local sync data operations
abstract class SyncLocalDataSource {
  // Terminal Config
  Future<TerminalConfigModel?> getTerminalConfig();
  Future<void> saveTerminalConfig(TerminalConfigModel config);

  // Sync Queue
  Future<void> enqueueSale(String saleId, Map<String, dynamic> saleData);
  Future<List<SyncQueueModel>> getPendingSales({int limit = 50});
  Future<List<SyncQueueModel>> getFailedSales();
  Future<void> markSynced(String id);
  Future<void> markFailed(String id, String errorMessage);
  Future<int> getPendingSalesCount();
  Future<int> cleanupSyncedItems({int olderThanDays = 7});
  Stream<int> watchPendingSalesCount();
}

/// Implementation of local sync data source using SQLite
class SyncLocalDataSourceImpl implements SyncLocalDataSource {
  final DatabaseHelper _dbHelper;

  // Stream controller for pending count
  final _pendingCountController = StreamController<int>.broadcast();

  SyncLocalDataSourceImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<TerminalConfigModel?> getTerminalConfig() async {
    try {
      final db = await _dbHelper.database;

      final results = await db.query(
        'terminal_config',
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      // Convert key-value rows to a single map
      final configMap = <String, dynamic>{};
      for (final row in results) {
        final key = row['key'] as String?;
        final value = row['value'] as String?;
        if (key != null && value != null) {
          configMap[key] = value;
        }
      }

      // Check if we have the full config from the first row
      // The terminal_config table might be using a different structure
      if (results.first.containsKey('terminal_id')) {
        return TerminalConfigModel.fromMap(results.first);
      }

      // Parse from key-value format
      return TerminalConfigModel(
        terminalId: configMap['terminal_id'] as String? ?? '',
        name: configMap['name'] as String? ?? '',
        type: configMap['type'] as String? ?? 'cashier',
        masterIp: configMap['master_ip'] as String? ?? '',
        masterPort:
            int.tryParse(configMap['master_port']?.toString() ?? '8080') ??
                8080,
        createdAt: configMap['created_at'] as String? ??
            DateTime.now().toIso8601String(),
        updatedAt: configMap['updated_at'] as String? ??
            DateTime.now().toIso8601String(),
      );
    } catch (e) {
      developer.log('Error getting terminal config: $e',
          name: 'SyncLocalDataSource');
      return null;
    }
  }

  @override
  Future<void> saveTerminalConfig(TerminalConfigModel config) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();

      // Delete existing config
      await db.delete('terminal_config');

      // Insert new config as key-value pairs
      final configMap = config.toMap();
      for (final entry in configMap.entries) {
        await db.insert('terminal_config', {
          'key': entry.key,
          'value': entry.value?.toString() ?? '',
          'updated_at': now,
        });
      }

      developer.log('Terminal config saved: ${config.terminalId}',
          name: 'SyncLocalDataSource');
    } catch (e) {
      developer.log('Error saving terminal config: $e',
          name: 'SyncLocalDataSource');
      rethrow;
    }
  }

  @override
  Future<void> enqueueSale(String saleId, Map<String, dynamic> saleData) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();

      final model = SyncQueueModel(
        id: const Uuid().v4(),
        action: 'sale',
        saleId: saleId,
        payload: saleData.toString(), // Will be properly encoded by model
        createdAt: now,
        updatedAt: now,
      );

      await db.insert('sync_queue', {
        'id': model.id,
        'action': model.action,
        'sale_id': saleId,
        'payload': model.payload,
        'status': 'pending',
        'retry_count': 0,
        'created_at': now,
        'updated_at': now,
      });

      // Notify listeners
      _updatePendingCount();

      developer.log('Sale enqueued for sync: $saleId',
          name: 'SyncLocalDataSource');
    } catch (e) {
      developer.log('Error enqueueing sale: $e', name: 'SyncLocalDataSource');
      rethrow;
    }
  }

  @override
  Future<List<SyncQueueModel>> getPendingSales({int limit = 50}) async {
    try {
      final db = await _dbHelper.database;

      final results = await db.query(
        'sync_queue',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
        limit: limit,
      );

      return results.map((row) => SyncQueueModel.fromMap(row)).toList();
    } catch (e) {
      developer.log('Error getting pending sales: $e',
          name: 'SyncLocalDataSource');
      return [];
    }
  }

  @override
  Future<List<SyncQueueModel>> getFailedSales() async {
    try {
      final db = await _dbHelper.database;

      final results = await db.query(
        'sync_queue',
        where: 'status = ? AND retry_count < 5',
        whereArgs: ['failed'],
        orderBy: 'created_at ASC',
      );

      return results.map((row) => SyncQueueModel.fromMap(row)).toList();
    } catch (e) {
      developer.log('Error getting failed sales: $e',
          name: 'SyncLocalDataSource');
      return [];
    }
  }

  @override
  Future<void> markSynced(String id) async {
    try {
      final db = await _dbHelper.database;

      await db.update(
        'sync_queue',
        {
          'status': 'synced',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      _updatePendingCount();
    } catch (e) {
      developer.log('Error marking synced: $e', name: 'SyncLocalDataSource');
      rethrow;
    }
  }

  @override
  Future<void> markFailed(String id, String errorMessage) async {
    try {
      final db = await _dbHelper.database;

      await db.rawUpdate(
        '''
        UPDATE sync_queue
        SET status = 'failed',
            retry_count = retry_count + 1,
            error_message = ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [errorMessage, DateTime.now().toIso8601String(), id],
      );

      _updatePendingCount();
    } catch (e) {
      developer.log('Error marking failed: $e', name: 'SyncLocalDataSource');
      rethrow;
    }
  }

  @override
  Future<int> getPendingSalesCount() async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue WHERE status = ?',
        ['pending'],
      );

      return result.first['count'] as int? ?? 0;
    } catch (e) {
      developer.log('Error getting pending count: $e',
          name: 'SyncLocalDataSource');
      return 0;
    }
  }

  @override
  Future<int> cleanupSyncedItems({int olderThanDays = 7}) async {
    try {
      final db = await _dbHelper.database;
      final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));

      final deleted = await db.delete(
        'sync_queue',
        where: 'status = ? AND updated_at < ?',
        whereArgs: ['synced', cutoff.toIso8601String()],
      );

      developer.log('Cleaned up $deleted synced items',
          name: 'SyncLocalDataSource');
      return deleted;
    } catch (e) {
      developer.log('Error cleaning up: $e', name: 'SyncLocalDataSource');
      return 0;
    }
  }

  @override
  Stream<int> watchPendingSalesCount() {
    // Emit initial count
    _updatePendingCount();
    return _pendingCountController.stream;
  }

  void _updatePendingCount() async {
    final count = await getPendingSalesCount();
    _pendingCountController.add(count);
  }

  void dispose() {
    _pendingCountController.close();
  }
}
