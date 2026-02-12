import 'dart:async';
import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';

import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../infrastructure/sync_api_client.dart';
import '../models/models.dart';
import '../../../../core/database/drift/daos/daos.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../features/pos/data/repositories/sales_repository.dart';
import '../../infrastructure/sync_server.dart';

/// Implementation of SyncRepository
///
/// Architecture (v2.x): Repository → DAO directly
/// ```
/// UI → Controller → Repository → SyncDriftDao → Database
/// ```
class SyncRepositoryImpl implements SyncRepository {
  final SyncDriftDao _syncDao;
  final SyncApiClient _apiClient;
  final ProductDriftDao _productDao;
  final SalesRepository _salesRepository;
  SyncServer? _server;

  // Stream controller for pending count
  final _pendingCountController = StreamController<int>.broadcast();

  // Status stream
  final _statusController = StreamController<SyncStatusEntity>.broadcast();
  SyncStatusEntity _currentStatus = SyncStatusEntity.initial;

  SyncRepositoryImpl({
    required SyncDriftDao syncDao,
    SyncApiClient? apiClient,
    required ProductDriftDao productDao,
    required SalesRepository salesRepository,
  })  : _syncDao = syncDao,
        _apiClient = apiClient ?? SyncApiClientImpl(),
        _productDao = productDao,
        _salesRepository = salesRepository {
    // Connect Drift stream to our controller
    _syncDao.watchPendingCount().listen((count) {
      _pendingCountController.add(count);
    });
  }

  // ============ Terminal Configuration ============

  @override
  Future<Either<SyncFailure, TerminalConfigEntity>> getTerminalConfig() async {
    try {
      final configMap = await _syncDao.getTerminalConfig();

      if (configMap.isEmpty) {
        return const Either.left(NotConfiguredFailure());
      }

      final model = _mapConfigFromDao(configMap);
      return Either.right(model.toEntity());
    } catch (e, stack) {
      developer.log('Error getting config: $e',
          name: 'SyncRepository', stackTrace: stack);
      return Either.left(DatabaseFailure(
        'فشل قراءة إعدادات الجهاز',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, Unit>> saveTerminalConfig(
      TerminalConfigEntity config) async {
    try {
      final configMap = <String, String>{
        'terminal_id': config.terminalId,
        'name': config.name,
        'type': config.type.name,
        'master_ip': config.masterIp,
        'master_port': config.masterPort.toString(),
        'created_at': config.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _syncDao.saveTerminalConfig(configMap);
      developer.log('Terminal config saved: ${config.terminalId}',
          name: 'SyncRepository');
      return const Either.right(Unit.unit);
    } catch (e, stack) {
      developer.log('Error saving config: $e',
          name: 'SyncRepository', stackTrace: stack);
      return Either.left(DatabaseFailure(
        'فشل حفظ إعدادات الجهاز',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, bool>> isMaster() async {
    final result = await getTerminalConfig();
    return result.map((config) => config.isMaster);
  }

  @override
  Future<Either<SyncFailure, bool>> isCashier() async {
    final result = await getTerminalConfig();
    return result.map((config) => config.isCashier);
  }

  // ============ Sync Queue Operations ============

  @override
  Future<Either<SyncFailure, Unit>> enqueueSale({
    required String saleId,
    required Map<String, dynamic> saleData,
  }) async {
    try {
      await _syncDao.enqueue(
        id: const Uuid().v4(),
        action: 'sale:$saleId',
        payload: saleData.toString(),
      );

      developer.log('Sale enqueued for sync: $saleId', name: 'SyncRepository');

      _updateStatus((s) => s.copyWith(
            pendingSalesCount: s.pendingSalesCount + 1,
          ));
      return const Either.right(Unit.unit);
    } catch (e) {
      developer.log('Error enqueueing sale: $e', name: 'SyncRepository');
      return Either.left(DatabaseFailure(
        'فشل إضافة المبيعة للقائمة',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, List<SyncQueueEntity>>> getPendingSales({
    int limit = 50,
  }) async {
    try {
      final entries = await _syncDao.getPending(limit: limit);
      final models = entries.map(_mapEntryToModel).toList();
      return Either.right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      developer.log('Error getting pending sales: $e', name: 'SyncRepository');
      return Either.left(DatabaseFailure(
        'فشل جلب المبيعات المعلّقة',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, List<SyncQueueEntity>>> getFailedSales() async {
    try {
      final entries = await _syncDao.getFailed();
      final models = entries.map(_mapEntryToModel).toList();
      return Either.right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      developer.log('Error getting failed sales: $e', name: 'SyncRepository');
      return Either.left(DatabaseFailure(
        'فشل جلب المبيعات الفاشلة',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, Unit>> markSynced(String id) async {
    try {
      await _syncDao.markSynced(id);
      return const Either.right(Unit.unit);
    } catch (e) {
      developer.log('Error marking synced: $e', name: 'SyncRepository');
      return Either.left(DatabaseFailure(
        'فشل تحديث حالة المزامنة',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, Unit>> markFailed(
      String id, String errorMessage) async {
    try {
      await _syncDao.markFailed(id, errorMessage);
      return const Either.right(Unit.unit);
    } catch (e) {
      developer.log('Error marking failed: $e', name: 'SyncRepository');
      return Either.left(DatabaseFailure(
        'فشل تحديث حالة الفشل',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, int>> getPendingSalesCount() async {
    try {
      final count = await _syncDao.getPendingCount();
      return Either.right(count);
    } catch (e) {
      developer.log('Error getting pending count: $e', name: 'SyncRepository');
      return Either.left(DatabaseFailure(
        'فشل عد المبيعات المعلّقة',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Stream<int> watchPendingSalesCount() {
    return _pendingCountController.stream;
  }

  @override
  Future<Either<SyncFailure, int>> cleanupSyncedItems() async {
    try {
      final deleted = await _syncDao.cleanupSyncedItems();
      developer.log('Cleaned up $deleted synced items', name: 'SyncRepository');
      return Either.right(deleted);
    } catch (e) {
      developer.log('Error cleaning up: $e', name: 'SyncRepository');
      return Either.left(DatabaseFailure(
        'فشل تنظيف العناصر القديمة',
        technicalMessage: e.toString(),
      ));
    }
  }

  // ============ Network Discovery ============

  @override
  Future<Either<SyncFailure, DiscoveryResultEntity>> discoverServer({
    int port = 8080,
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      final result = await _apiClient.discoverServer(
        port: port,
        onProgress: onProgress,
      );

      if (!result.found) {
        return const Either.left(ServerNotFoundFailure());
      }

      return Either.right(result);
    } catch (e) {
      return Either.left(ConnectionFailure(
        'فشل البحث عن السيرفر',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, bool>> checkServerAt(String ip, int port) async {
    try {
      final found = await _apiClient.checkServerAt(ip, port);
      return Either.right(found);
    } catch (e) {
      return Either.left(ConnectionFailure(
        'فشل التحقق من السيرفر',
        technicalMessage: e.toString(),
        url: 'http://$ip:$port',
      ));
    }
  }

  // ============ Remote Sync Operations ============

  @override
  Future<Either<SyncFailure, SyncResultEntity>> initialSync(
      String masterUrl) async {
    _updateStatus((s) => s.copyWith(
          state: SyncState.downloadingSnapshot,
          statusMessage: 'جاري تحميل البيانات...',
        ));

    try {
      final configResult = await getTerminalConfig();
      final terminalId = configResult.fold(
        (_) => 'unknown',
        (config) => config.terminalId,
      );

      final result = await _apiClient.initialSync(masterUrl, terminalId);

      if (result.success) {
        _updateStatus((s) => s.copyWith(
              state: SyncState.completed,
              isConnected: true,
              lastSuccessfulSync: result.completedAt,
              statusMessage: result.summary,
            ));
        return Either.right(result);
      } else {
        _updateStatus((s) => s.copyWith(
              state: SyncState.failed,
              errorMessage: result.errorMessage,
            ));
        return Either.left(
            ServerErrorFailure(result.errorMessage ?? 'فشلت المزامنة'));
      }
    } catch (e) {
      _updateStatus((s) => s.copyWith(
            state: SyncState.failed,
            errorMessage: e.toString(),
          ));
      return Either.left(ConnectionFailure(
        'فشل الاتصال بالسيرفر',
        technicalMessage: e.toString(),
        url: masterUrl,
      ));
    }
  }

  @override
  Future<Either<SyncFailure, SyncResultEntity>> incrementalSync(
      String masterUrl) async {
    _updateStatus((s) => s.copyWith(
          state: SyncState.pulling,
          statusMessage: 'جاري جلب التحديثات...',
        ));

    try {
      final configResult = await getTerminalConfig();
      final terminalId = configResult.fold(
        (_) => 'unknown',
        (config) => config.terminalId,
      );

      final result = await _apiClient.incrementalSync(
        masterUrl,
        terminalId,
        _currentStatus.lastSuccessfulSync,
      );

      if (result.success) {
        _updateStatus((s) => s.copyWith(
              state: SyncState.completed,
              lastSuccessfulSync: result.completedAt,
              statusMessage: result.summary,
            ));
        return Either.right(result);
      } else {
        return Either.left(
            ServerErrorFailure(result.errorMessage ?? 'فشلت المزامنة'));
      }
    } catch (e) {
      return Either.left(ConnectionFailure(
        'فشل جلب التحديثات',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, SyncResultEntity>> pushSales(
      String masterUrl) async {
    _updateStatus((s) => s.copyWith(
          state: SyncState.pushing,
          statusMessage: 'جاري رفع المبيعات...',
        ));

    try {
      final entries = await _syncDao.getPending();
      final pendingModels = entries.map(_mapEntryToModel).toList();
      if (pendingModels.isEmpty) {
        return const Either.left(NoDataToSyncFailure());
      }

      final configResult = await getTerminalConfig();
      final terminalId = configResult.fold(
        (_) => 'unknown',
        (config) => config.terminalId,
      );

      final result = await _apiClient.pushSales(
        masterUrl,
        terminalId,
        pendingModels,
      );

      if (result.success) {
        // Mark items as synced
        for (final item in pendingModels) {
          await markSynced(item.id);
        }

        final newCount = await _syncDao.getPendingCount();
        _updateStatus((s) => s.copyWith(
              state: SyncState.completed,
              pendingSalesCount: newCount,
              statusMessage: 'تم رفع ${result.salesPushed} مبيعة',
            ));

        return Either.right(result);
      } else {
        return Either.left(
            ServerErrorFailure(result.errorMessage ?? 'فشل رفع المبيعات'));
      }
    } catch (e) {
      return Either.left(ConnectionFailure(
        'فشل رفع المبيعات',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, SyncResultEntity>> fullSync(
      String masterUrl) async {
    _updateStatus((s) => s.copyWith(
          state: SyncState.syncing,
          statusMessage: 'جاري المزامنة الكاملة...',
        ));

    try {
      // 1. Push sales first
      final pushResult = await pushSales(masterUrl);

      // 2. Then pull products
      final pullResult = await incrementalSync(masterUrl);

      // Combine results
      final totalProducts = pullResult.fold(
        (_) => 0,
        (r) => r.productsUpdated,
      );
      final totalSales = pushResult.fold(
        (_) => 0,
        (r) => r.salesPushed,
      );

      _updateStatus((s) => s.copyWith(
            state: SyncState.completed,
            lastSuccessfulSync: DateTime.now(),
            statusMessage: 'تم مزامنة $totalProducts منتج و $totalSales مبيعة',
          ));

      return Either.right(SyncResultEntity.success(
        productsUpdated: totalProducts,
        salesPushed: totalSales,
      ));
    } catch (e) {
      _updateStatus((s) => s.copyWith(
            state: SyncState.failed,
            errorMessage: e.toString(),
          ));
      return Either.left(UnknownSyncFailure(
        'فشلت المزامنة الكاملة',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, double>> getRemoteStock(
      String masterUrl, String productId) async {
    try {
      final stock = await _apiClient.getRemoteStock(masterUrl, productId);
      if (stock != null) {
        return Either.right(stock);
      }
      return const Either.left(ServerErrorFailure('لم يتم العثور على المنتج'));
    } catch (e) {
      return Either.left(ConnectionFailure(
        'فشل جلب المخزون',
        technicalMessage: e.toString(),
      ));
    }
  }

  // ============ Server Operations ============

  @override
  Future<Either<SyncFailure, bool>> startServer({int port = 8080}) async {
    try {
      _server ??= SyncServer(
        productDao: _productDao,
        salesRepository: _salesRepository,
      );
      final server = _server;
      if (server == null) {
        return const Either.left(UnknownSyncFailure('فشل إنشاء السيرفر'));
      }

      final started = await server.start(port: port);

      if (started) {
        _updateStatus((s) => s.copyWith(
              isConnected: true,
              statusMessage: 'السيرفر يعمل على المنفذ $port',
            ));
      }

      return Either.right(started);
    } catch (e) {
      return Either.left(UnknownSyncFailure(
        'فشل تشغيل السيرفر',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<SyncFailure, Unit>> stopServer() async {
    try {
      await _server?.stop();
      _server = null;
      return const Either.right(Unit.unit);
    } catch (e) {
      return Either.left(UnknownSyncFailure(
        'فشل إيقاف السيرفر',
        technicalMessage: e.toString(),
      ));
    }
  }

  @override
  bool isServerRunning() => _server?.isRunning ?? false;

  // ============ Connection Monitoring ============

  @override
  void startConnectionMonitoring(String masterUrl) {
    _apiClient.startConnectionMonitoring(masterUrl);
  }

  @override
  void stopConnectionMonitoring() {
    _apiClient.stopConnectionMonitoring();
  }

  @override
  Stream<ConnectionStatus> watchConnectionStatus() {
    return _apiClient.watchConnectionStatus();
  }

  @override
  Stream<SyncStatusEntity> watchSyncStatus() {
    return _statusController.stream;
  }

  void _updateStatus(SyncStatusEntity Function(SyncStatusEntity) updater) {
    _currentStatus = updater(_currentStatus);
    _statusController.add(_currentStatus);
  }

  void dispose() {
    _pendingCountController.close();
    _statusController.close();
    stopConnectionMonitoring();
    stopServer();
  }

  // ============ Private Mappers ============

  /// Map DAO config map to model
  TerminalConfigModel _mapConfigFromDao(Map<String, String> config) {
    return TerminalConfigModel(
      terminalId: config['terminal_id'] ?? '',
      name: config['name'] ?? '',
      type: config['type'] ?? 'cashier',
      masterIp: config['master_ip'] ?? '',
      masterPort: int.tryParse(config['master_port'] ?? '8080') ?? 8080,
      createdAt: config['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: config['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  /// Map Drift entry to domain model
  SyncQueueModel _mapEntryToModel(SyncQueueEntry entry) {
    final status = switch (entry.status) {
      SyncStatus.pending => 'pending',
      SyncStatus.synced => 'synced',
      SyncStatus.failed => 'failed',
      _ => 'pending',
    };

    // Extract saleId from action (format: 'sale:saleId')
    final saleId =
        entry.action.startsWith('sale:') ? entry.action.substring(5) : entry.id;

    return SyncQueueModel(
      id: entry.id,
      action: entry.action.contains(':')
          ? entry.action.split(':')[0]
          : entry.action,
      saleId: saleId,
      payload: entry.payload,
      status: status,
      retryCount: entry.retryCount,
      errorMessage: entry.errorMessage,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entry.createdAt)
          .toIso8601String(),
      updatedAt: entry.lastAttemptAt != null
          ? DateTime.fromMillisecondsSinceEpoch(entry.lastAttemptAt!)
              .toIso8601String()
          : DateTime.fromMillisecondsSinceEpoch(entry.createdAt)
              .toIso8601String(),
    );
  }
}
