import '../entities/product_entity.dart';
import '../repositories/inventory_repository.dart';

class GetAllProductsUseCase {
  final InventoryRepository repository;
  GetAllProductsUseCase(this.repository);

  Future<List<ProductEntity>> call() async {
    return await repository.getAllProducts();
  }
}
