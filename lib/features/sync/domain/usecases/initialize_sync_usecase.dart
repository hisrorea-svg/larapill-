import '../entities/entities.dart';
import '../failures/failures.dart';
import '../repositories/sync_repository.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';

/// Use case for initializing sync based on terminal type
class InitializeSyncUseCase {
  final SyncRepository _repository;

  const InitializeSyncUseCase(this._repository);

  /// Execute the use case
  /// - For Master: starts the sync server
  /// - For Cashier: starts connection monitoring and performs initial sync
  Future<Either<SyncFailure, SyncStatusEntity>> call() async {
    // 1. Get terminal configuration
    final configResult = await _repository.getTerminalConfig();

    return configResult.fold(
      (failure) => Either.left(failure),
      (config) async {
        if (config.isMaster) {
          // Start server for master
          final serverResult = await _repository.startServer();
          return serverResult.fold(
            (failure) => Either.left(failure),
            (started) => Either.right(
              SyncStatusEntity(
                state: started ? SyncState.idle : SyncState.failed,
                isConnected: true, // Master is always "connected"
                statusMessage: started ? 'السيرفر يعمل' : 'فشل تشغيل السيرفر',
              ),
            ),
          );
        } else {
          // Cashier: start monitoring and sync
          if (config.masterIp.isEmpty) {
            return const Either.left(NotConfiguredFailure());
          }

          _repository.startConnectionMonitoring(config.masterUrl);

          // Perform initial sync
          final syncResult = await _repository.initialSync(config.masterUrl);

          return syncResult.fold(
            (failure) => Either.right(
              SyncStatusEntity(
                state: SyncState.failed,
                isConnected: false,
                statusMessage: failure.message,
                errorMessage: failure.message,
              ),
            ),
            (result) => Either.right(
              SyncStatusEntity(
                state: SyncState.completed,
                isConnected: true,
                statusMessage: result.summary,
                lastSuccessfulSync: result.completedAt,
              ),
            ),
          );
        }
      },
    );
  }
}
