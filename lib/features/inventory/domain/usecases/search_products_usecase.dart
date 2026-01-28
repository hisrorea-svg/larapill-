import '../entities/product_entity.dart';
import '../failures/inventory_failure.dart';
import '../repositories/inventory_repository.dart';

/// Use case for searching products
class SearchProductsUseCase {
  final InventoryRepository _repository;

  const SearchProductsUseCase(this._repository);

  /// Execute the use case
  /// Searches by name, company, barcode, or category
  Future<Either<InventoryFailure, List<ProductEntity>>> call(
      String query) async {
    // Trim and validate query
    final trimmedQuery = query.trim();

    // Return all products for empty query
    if (trimmedQuery.isEmpty) {
      return _repository.getAllProducts();
    }

    return _repository.searchProducts(trimmedQuery);
  }
}
