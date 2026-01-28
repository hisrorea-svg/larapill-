import '../entities/inventory_stats.dart';
import '../failures/inventory_failure.dart';
import '../repositories/inventory_repository.dart';

/// Use case for getting inventory statistics
class GetInventoryStatsUseCase {
  final InventoryRepository _repository;

  const GetInventoryStatsUseCase(this._repository);

  /// Execute the use case
  Future<Either<InventoryFailure, InventoryStatsEntity>> call() async {
    return _repository.getInventoryStats();
  }
}
