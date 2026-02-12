import '../entities/product_entity.dart';
import '../failures/inventory_failure.dart';
import '../repositories/inventory_repository.dart';

/// Use case for getting a product by ID
class GetProductByIdUseCase {
  final InventoryRepository _repository;

  const GetProductByIdUseCase(this._repository);

  /// Execute the use case
  /// Returns the product or null if not found
  Future<Either<InventoryFailure, ProductEntity?>> call(String id) async {
    return _repository.getProductById(id);
  }
}
