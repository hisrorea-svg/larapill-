import '../entities/entities.dart';
import '../failures/failures.dart';
import '../repositories/sync_repository.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';

/// Use case for pushing sales to master
class PushSalesUseCase {
  final SyncRepository _repository;

  const PushSalesUseCase(this._repository);

  /// Execute the use case
  /// Pushes all pending sales to master server
  Future<Either<SyncFailure, SyncResultEntity>> call() async {
    // 1. Get terminal configuration
    final configResult = await _repository.getTerminalConfig();

    return configResult.fold(
      (failure) => Either.left(failure),
      (config) async {
        if (config.isMaster) {
          // Master doesn't push sales
          return Either.right(SyncResultEntity.success());
        }

        if (config.masterIp.isEmpty) {
          return const Either.left(NotConfiguredFailure());
        }

        // 2. Check if there are pending sales
        final pendingResult = await _repository.getPendingSalesCount();
        final hasPending = pendingResult.fold(
          (_) => false,
          (count) => count > 0,
        );

        if (!hasPending) {
          return const Either.left(NoDataToSyncFailure());
        }

        // 3. Push sales
        return _repository.pushSales(config.masterUrl);
      },
    );
  }
}
