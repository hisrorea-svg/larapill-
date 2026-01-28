import '../entities/entities.dart';
import '../failures/failures.dart';
import '../repositories/sync_repository.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';

/// Use case for performing manual sync
class SyncNowUseCase {
  final SyncRepository _repository;

  const SyncNowUseCase(this._repository);

  /// Execute the use case
  /// Performs full sync (pull products + push sales)
  Future<Either<SyncFailure, SyncResultEntity>> call() async {
    // 1. Get terminal configuration
    final configResult = await _repository.getTerminalConfig();

    return configResult.fold(
      (failure) => Either.left(failure),
      (config) async {
        if (config.isMaster) {
          // Master doesn't sync, it's the source
          return Either.right(SyncResultEntity.success());
        }

        if (config.masterIp.isEmpty) {
          return const Either.left(NotConfiguredFailure());
        }

        // 2. Perform full sync
        return _repository.fullSync(config.masterUrl);
      },
    );
  }
}
