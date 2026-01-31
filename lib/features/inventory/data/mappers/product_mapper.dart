import 'package:uuid/uuid.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/entities/add_product_params.dart';
import '../models/product_model.dart';

/// Mapper for converting between ProductEntity and ProductModel
///
/// NOTE: This mapper handles the conversion between:
/// - ProductEntity: Domain layer (simplified, uses int id for compatibility)
/// - ProductModel: Data layer (matches actual DB schema with TEXT id)
class ProductMapper {
  /// Convert ProductModel (data) to ProductEntity (domain)
  static ProductEntity toEntity(ProductModel model) {
    // Parse id to int (for ProductEntity compatibility)
    final intId = int.tryParse(model.id) ?? 0;

    return ProductEntity(
      id: intId,
      name: model.name,
      company: model.company,
      category: model.category,
      barcode: model.barcode,
      quantity: model.currentStock.toInt(), // current_stock -> quantity
      price: model.sellingPrice ?? 0.0,
      costPrice: model.costPrice,
      expiryDate: model.expiryDate != null
          ? DateTime.tryParse(model.expiryDate!)
          : null,
      createdAt:
          model.createdAt != null ? DateTime.tryParse(model.createdAt!) : null,
      updatedAt:
          model.updatedAt != null ? DateTime.tryParse(model.updatedAt!) : null,
      isSynced: true, // Local DB is always "synced"
    );
  }

  /// Convert ProductEntity (domain) to ProductModel (data)
  static ProductModel toModel(ProductEntity entity) {
    final now = DateTime.now().toIso8601String();

    return ProductModel(
      id: entity.id.toString(),
      name: entity.name,
      company: entity.company,
      category: entity.category,
      barcode: entity.barcode,
      baseUnit: 'piece', // Default unit
      currentStock: entity.quantity.toDouble(),
      minStockLevel: 10.0, // Default threshold
      expiryDate: entity.expiryDate?.toIso8601String(),
      createdAt: entity.createdAt?.toIso8601String() ?? now,
      updatedAt: entity.updatedAt?.toIso8601String() ?? now,
      isActive: 1,
      sellingPrice: entity.price,
      costPrice: entity.costPrice,
    );
  }

  /// تحويل AddProductParams إلى ProductModel للإضافة
  static ProductModel toModelFromParams(AddProductParams params) {
    final now = DateTime.now().toIso8601String();
    return ProductModel(
      id: const Uuid().v4(),
      name: params.name,
      company: params.company,
      category: 'medicalSupplies', // القيمة الافتراضية
      barcode: params.barcode,
      baseUnit: 'piece',
      currentStock: params.quantity.toDouble(),
      minStockLevel: 10.0,
      expiryDate: params.expiryDate.toIso8601String(),
      createdAt: now,
      updatedAt: now,
      isActive: 1,
      sellingPrice: params.price,
      costPrice: params.cost,
    );
  }

  /// Convert list of models to list of entities
  static List<ProductEntity> toEntityList(List<ProductModel> models) {
    return models.map(toEntity).toList();
  }

  /// Convert list of entities to list of models
  static List<ProductModel> toModelList(List<ProductEntity> entities) {
    return entities.map(toModel).toList();
  }
}
