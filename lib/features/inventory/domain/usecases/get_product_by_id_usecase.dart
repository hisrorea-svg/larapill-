import '../repositories/inventory_repository.dart';
import '../entities/product_entity.dart';

class GetProductByIdUseCase {
  final InventoryRepository repository;
  GetProductByIdUseCase(this.repository);

  Future<ProductEntity?> call(int id) async {
    return await repository.getProductById(id);
  }
}
