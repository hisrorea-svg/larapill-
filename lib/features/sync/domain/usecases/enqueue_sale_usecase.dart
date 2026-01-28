import '../failures/failures.dart';
import '../repositories/sync_repository.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';

/// Use case for enqueueing a sale for sync
class EnqueueSaleUseCase {
  final SyncRepository _repository;

  const EnqueueSaleUseCase(this._repository);

  /// Execute the use case
  /// Adds a sale to the sync queue for later push to master
  Future<Either<SyncFailure, Unit>> call({
    required String saleId,
    required Map<String, dynamic> saleData,
  }) async {
    // Validate input
    if (saleId.isEmpty) {
      return const Either.left(ConfigurationFailure('Sale ID cannot be empty'));
    }

    if (saleData.isEmpty) {
      return const Either.left(
          ConfigurationFailure('Sale data cannot be empty'));
    }

    // Enqueue the sale
    return _repository.enqueueSale(
      saleId: saleId,
      saleData: saleData,
    );
  }
}
