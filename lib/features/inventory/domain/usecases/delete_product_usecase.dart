import '../failures/inventory_failure.dart';
import '../repositories/inventory_repository.dart';

/// Use case for deleting a product
/// Checks existence before deletion
class DeleteProductUseCase {
  final InventoryRepository _repository;

  const DeleteProductUseCase(this._repository);

  /// Execute the use case
  /// Returns Unit on success, Failure on error
  Future<Either<InventoryFailure, Unit>> call(int id) async {
    // 1. Check if product exists
    final existingResult = await _repository.getProductById(id);

    final exists = existingResult.fold(
      (failure) => false,
      (product) => product != null,
    );

    if (!exists) {
      return Either.left(ProductNotFoundFailure(id));
    }

    // 2. Delete via repository
    return _repository.deleteProduct(id);
  }
}
