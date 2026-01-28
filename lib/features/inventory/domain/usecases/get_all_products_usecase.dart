import '../entities/product_entity.dart';
import '../failures/inventory_failure.dart';
import '../repositories/inventory_repository.dart';

/// Use case for getting all products
class GetAllProductsUseCase {
  final InventoryRepository _repository;

  const GetAllProductsUseCase(this._repository);

  /// Execute the use case
  Future<Either<InventoryFailure, List<ProductEntity>>> call() async {
    return _repository.getAllProducts();
  }
}
