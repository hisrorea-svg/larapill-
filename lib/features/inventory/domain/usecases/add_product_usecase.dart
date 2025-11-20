import '../entities/product_entity.dart';
import '../repositories/inventory_repository.dart';

class AddProductUseCase {
  final InventoryRepository repository;
  AddProductUseCase(this.repository);

  Future<void> call(ProductEntity product) async {
    await repository.addProduct(product);
  }
}
