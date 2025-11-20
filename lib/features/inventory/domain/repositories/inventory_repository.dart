import '../entities/product_entity.dart';

/// الواجهة (Interface) التي تحدد وظائف المستودع الخاصة بالمخزون
abstract class InventoryRepository {
  /// جلب جميع المنتجات بشكل مبسط للعرض
  Future<List<ProductEntity>> getAllProducts();

  /// جلب منتج واحد حسب الـ ID
  Future<ProductEntity?> getProductById(int id);

  /// إضافة منتج جديد
  Future<void> addProduct(ProductEntity product);

  /// تحديث منتج موجود
  Future<void> updateProduct(ProductEntity product);

  /// حذف منتج حسب الـ ID
  Future<void> deleteProduct(int id);
}
