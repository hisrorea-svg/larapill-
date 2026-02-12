import 'package:flutter/foundation.dart';
import '../failures/inventory_failure.dart';
import '../repositories/inventory_repository.dart';

/// Use case for deleting a product
/// Checks existence before deletion
class DeleteProductUseCase {
  final InventoryRepository _repository;

  const DeleteProductUseCase(this._repository);

  /// Execute the use case
  /// Returns Unit on success, Failure on error
  Future<Either<InventoryFailure, Unit>> call(String id) async {
    debugPrint('🗑️ UseCase: Starting delete for ID: $id');

    // 1. Check if product exists
    final existingResult = await _repository.getProductById(id);

    final exists = existingResult.fold(
      (failure) {
        debugPrint('❌ UseCase: Error checking existence: ${failure.message}');
        return false;
      },
      (product) {
        debugPrint('📋 UseCase: Product found: ${product?.name}');
        return product != null;
      },
    );

    if (!exists) {
      debugPrint('⚠️ UseCase: Product not found with ID: $id');
      return Either.left(ProductNotFoundFailure(id));
    }

    // 2. Delete via repository
    debugPrint('🗑️ UseCase: Calling repository.deleteProduct');
    final deleteResult = await _repository.deleteProduct(id);

    deleteResult.fold(
      (failure) =>
          debugPrint('❌ UseCase: Repository delete failed: ${failure.message}'),
      (_) => debugPrint('✅ UseCase: Repository delete SUCCESS'),
    );

    return deleteResult;
  }
}
