import '../entities/add_product_params.dart';
import '../entities/product_entity.dart';
import '../failures/inventory_failure.dart';
import '../repositories/inventory_repository.dart';
import '../validators/product_validator.dart';

/// Use case for adding a new product
/// Contains business logic for validation and duplicate checking
class AddProductUseCase {
  final InventoryRepository _repository;
  final ProductValidator _validator;

  const AddProductUseCase(this._repository, this._validator);

  /// Execute the use case
  /// Returns Either<InventoryFailure, ProductEntity>
  Future<Either<InventoryFailure, ProductEntity>> call(
      AddProductParams params) async {
    // 1. Validate input data (simplified)
    final validation = _validator.validateSimple(
      name: params.name,
      quantity: params.quantity,
      price: params.price,
      cost: params.cost,
      expiryDate: params.expiryDate,
    );

    if (validation.isNotValid) {
      return Either.left(ValidationFailure(
        'بيانات غير صالحة',
        fieldErrors: validation.errors,
      ));
    }

    // 2. Validate box fields
    if (params.boxCount <= 0) {
      return const Either.left(
          ValidationFailure('عدد العلب يجب أن يكون أكبر من صفر'));
    }
    if (params.unitsPerBox <= 0) {
      return const Either.left(
          ValidationFailure('التعبئة يجب أن تكون أكبر من صفر'));
    }

    // 3. Check for duplicate barcode (if barcode provided)
    if (params.barcode.isNotEmpty) {
      final existingResult =
          await _repository.getProductByBarcode(params.barcode);

      final hasExisting = existingResult.fold(
        (failure) => false,
        (product) => product != null,
      );

      if (hasExisting) {
        final existingProduct = existingResult.right!;
        return Either.left(DuplicateBarcodeFailure(
          existingProductName: existingProduct.name,
          barcode: params.barcode,
        ));
      }
    }

    // 4. Save via repository
    return _repository.addProduct(params);
  }
}
