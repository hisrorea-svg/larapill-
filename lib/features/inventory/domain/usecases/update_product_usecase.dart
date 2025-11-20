import '../entities/product_entity.dart';
import '../repositories/inventory_repository.dart';

class UpdateProductUseCase {
  final InventoryRepository repository;
  UpdateProductUseCase(this.repository);

  Future<void> call(ProductEntity product) async {
    await repository.updateProduct(product);
  }
}
