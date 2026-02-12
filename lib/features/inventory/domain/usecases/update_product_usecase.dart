import '../entities/product_entity.dart';
import '../failures/inventory_failure.dart';
import '../repositories/inventory_repository.dart';
import '../validators/product_validator.dart';

/// Parameters for updating a product
class UpdateProductParams {
  final String id; // ✅ Changed from int to String for UUID
  final String name;
  final String company;
  final String category;
  final String barcode;
  final int quantity;
  final double price;
  final double? costPrice;
  final DateTime? expiryDate;

  const UpdateProductParams({
    required this.id,
    required this.name,
    required this.company,
    required this.category,
    required this.barcode,
    required this.quantity,
    required this.price,
    this.costPrice,
    this.expiryDate,
  });
}

/// Use case for updating an existing product
/// Contains business logic for validation and existence checking
class UpdateProductUseCase {
  final InventoryRepository _repository;
  final ProductValidator _validator;

  const UpdateProductUseCase(this._repository, this._validator);

  /// Execute the use case
  Future<Either<InventoryFailure, ProductEntity>> call(
      UpdateProductParams params) async {
    // 1. Validate input data
    final validation = _validator.validate(
      name: params.name,
      company: params.company,
      category: params.category,
      barcode: params.barcode,
      quantity: params.quantity,
      price: params.price,
      costPrice: params.costPrice,
      expiryDate: params.expiryDate,
    );

    if (validation.isNotValid) {
      return Either.left(ValidationFailure(
        'بيانات غير صالحة',
        fieldErrors: validation.errors,
      ));
    }

    // 2. Check if product exists
    final existingResult = await _repository.getProductById(params.id);

    final existing = existingResult.fold(
      (failure) => null,
      (product) => product,
    );

    if (existing == null) {
      return Either.left(ProductNotFoundFailure(params.id));
    }

    // 3. Check for duplicate barcode (if changed)
    if (params.barcode.isNotEmpty && params.barcode != existing.barcode) {
      final barcodeResult =
          await _repository.getProductByBarcode(params.barcode);

      final hasDuplicate = barcodeResult.fold(
        (failure) => false,
        (product) => product != null && product.id != params.id,
      );

      if (hasDuplicate) {
        final duplicateProduct = barcodeResult.right!;
        return Either.left(DuplicateBarcodeFailure(
          existingProductName: duplicateProduct.name,
          barcode: params.barcode,
        ));
      }
    }

    // 4. Create updated entity preserving creation date
    final updatedProduct = existing.copyWith(
      name: params.name.trim(),
      company: params.company.trim(),
      category: params.category,
      barcode: params.barcode.trim(),
      quantity: params.quantity,
      price: params.price,
      costPrice: params.costPrice,
      expiryDate: params.expiryDate,
      updatedAt: DateTime.now(),
      isSynced: false, // Mark as needing sync
    );

    // 5. Update via repository
    return _repository.updateProduct(updatedProduct);
  }
}
