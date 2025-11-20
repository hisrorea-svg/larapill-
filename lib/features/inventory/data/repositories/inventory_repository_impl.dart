import 'dart:developer' as developer;
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../../database/daos/product_dao.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final ProductDAO dao;

  InventoryRepositoryImpl(this.dao);

  @override
  Future<List<ProductEntity>> getAllProducts() async {
    try {
      final products = await dao.findAll();

      return products.map((m) {
        return ProductEntity(
          id: int.tryParse(m.id.toString()) ?? 0,
          name: m.name,
          company: m.company,
          category: m.category.arabicName,
          barcode: m.barcode,
          quantity: m.currentStock.toInt(),
          price: m.getPriceByUnit(m.baseUnit),
          costPrice: m.getCostPriceByUnit(m.baseUnit), // ✅ أضف هذا
          expiryDate: m.expiryDate,
        );
      }).toList();
    } catch (e) {
      developer.log('❌ خطأ في getAllProducts: $e',
          name: 'InventoryRepositoryImpl');
      return [];
    }
  }

  @override
  Future<ProductEntity?> getProductById(int id) async {
    try {
      final m = await dao.findById(id.toString());
      if (m == null) return null;

      return ProductEntity(
        id: int.tryParse(m.id.toString()) ?? 0,
        name: m.name,
        company: m.company,
        category: m.category.arabicName,
        barcode: m.barcode,
        quantity: (m.currentStock as num?)?.toInt() ?? 0,
        price: m.getPriceByUnit(m.baseUnit),
        costPrice: m.getCostPriceByUnit(m.baseUnit), // ✅ أضف هذا
        expiryDate: m.expiryDate,
      );
    } catch (e) {
      developer.log('❌ خطأ في getProductById: $e',
          name: 'InventoryRepositoryImpl');
      return null;
    }
  }

  @override
  Future<void> addProduct(ProductEntity product) async {
    try {
      await dao.insertProduct(product);
    } catch (e) {
      developer.log('❌ خطأ في addProduct: $e', name: 'InventoryRepositoryImpl');
      rethrow;
    }
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    try {
      await dao.updateProduct(product);
    } catch (e) {
      developer.log('❌ خطأ في updateProduct: $e',
          name: 'InventoryRepositoryImpl');
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      await dao.deleteProduct(id);
    } catch (e) {
      developer.log('❌ خطأ في deleteProduct: $e',
          name: 'InventoryRepositoryImpl');
      rethrow;
    }
  }
}
