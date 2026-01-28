import '../entities/entities.dart';
import '../failures/failures.dart';
import '../repositories/sync_repository.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';

/// Use case for discovering master server on network
class DiscoverServerUseCase {
  final SyncRepository _repository;

  const DiscoverServerUseCase(this._repository);

  /// Execute the use case
  /// Scans local network for master server
  Future<Either<SyncFailure, DiscoveryResultEntity>> call({
    int port = 8080,
    void Function(int current, int total)? onProgress,
  }) async {
    return _repository.discoverServer(
      port: port,
      onProgress: onProgress,
    );
  }
}
