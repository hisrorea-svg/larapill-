import '../entities/entities.dart';
import '../failures/failures.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';

/// Repository interface for multi-terminal sync operations
/// All methods return Either for typed error handling
abstract class SyncRepository {
  // ============ Terminal Configuration ============

  /// Get current terminal configuration
  Future<Either<SyncFailure, TerminalConfigEntity>> getTerminalConfig();

  /// Save terminal configuration
  Future<Either<SyncFailure, Unit>> saveTerminalConfig(
      TerminalConfigEntity config);

  /// Check if this terminal is configured as master
  Future<Either<SyncFailure, bool>> isMaster();

  /// Check if this terminal is configured as cashier
  Future<Either<SyncFailure, bool>> isCashier();

  // ============ Sync Queue Operations ============

  /// Add a sale to the sync queue
  Future<Either<SyncFailure, Unit>> enqueueSale({
    required String saleId,
    required Map<String, dynamic> saleData,
  });

  /// Get pending sales from queue (not yet synced)
  Future<Either<SyncFailure, List<SyncQueueEntity>>> getPendingSales({
    int limit = 50,
  });

  /// Get failed sales from queue
  Future<Either<SyncFailure, List<SyncQueueEntity>>> getFailedSales();

  /// Mark a queue item as synced
  Future<Either<SyncFailure, Unit>> markSynced(String id);

  /// Mark a queue item as failed with error message
  Future<Either<SyncFailure, Unit>> markFailed(String id, String errorMessage);

  /// Get count of pending sales
  Future<Either<SyncFailure, int>> getPendingSalesCount();

  /// Watch pending sales count for real-time updates
  Stream<int> watchPendingSalesCount();

  /// Clean up old synced items (older than 7 days)
  Future<Either<SyncFailure, int>> cleanupSyncedItems();

  // ============ Network Discovery ============

  /// Discover master server on local network
  Future<Either<SyncFailure, DiscoveryResultEntity>> discoverServer({
    int port = 8080,
    void Function(int current, int total)? onProgress,
  });

  /// Check if a server is running at the given address
  Future<Either<SyncFailure, bool>> checkServerAt(String ip, int port);

  // ============ Remote Sync Operations ============

  /// Perform initial full sync (download all products)
  Future<Either<SyncFailure, SyncResultEntity>> initialSync(String masterUrl);

  /// Perform incremental sync (only changes since last sync)
  Future<Either<SyncFailure, SyncResultEntity>> incrementalSync(
      String masterUrl);

  /// Push pending sales to master
  Future<Either<SyncFailure, SyncResultEntity>> pushSales(String masterUrl);

  /// Perform full sync (pull products + push sales)
  Future<Either<SyncFailure, SyncResultEntity>> fullSync(String masterUrl);

  /// Get remote stock for a product
  Future<Either<SyncFailure, double>> getRemoteStock(
      String masterUrl, String productId);

  // ============ Server Operations (Master only) ============

  /// Start the sync server (master only)
  Future<Either<SyncFailure, bool>> startServer({int port = 8080});

  /// Stop the sync server
  Future<Either<SyncFailure, Unit>> stopServer();

  /// Check if server is running
  bool isServerRunning();

  // ============ Connection Monitoring ============

  /// Start monitoring connection to master
  void startConnectionMonitoring(String masterUrl);

  /// Stop connection monitoring
  void stopConnectionMonitoring();

  /// Watch connection status
  Stream<ConnectionStatus> watchConnectionStatus();

  /// Watch sync status
  Stream<SyncStatusEntity> watchSyncStatus();
}
