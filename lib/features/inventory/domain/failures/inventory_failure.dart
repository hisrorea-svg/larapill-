/// Sealed class hierarchy for inventory-related failures
/// Provides typed error handling without exceptions
sealed class InventoryFailure {
  final String message;
  final String? code;

  const InventoryFailure(this.message, [this.code]);

  @override
  String toString() => 'InventoryFailure($code): $message';
}

/// Database operation failure
class DatabaseFailure extends InventoryFailure {
  const DatabaseFailure(super.message, [super.code]);
}

/// Validation failure with field-specific errors
class ValidationFailure extends InventoryFailure {
  final Map<String, String> fieldErrors;

  const ValidationFailure(
    super.message, {
    this.fieldErrors = const {},
  });

  /// Check if a specific field has an error
  bool hasErrorFor(String field) => fieldErrors.containsKey(field);

  /// Get error message for a specific field
  String? errorFor(String field) => fieldErrors[field];
}

/// Duplicate barcode failure
class DuplicateBarcodeFailure extends InventoryFailure {
  final String existingProductName;
  final String barcode;

  DuplicateBarcodeFailure({
    required this.existingProductName,
    required this.barcode,
  }) : super('الباركود "$barcode" مسجل مسبقاً للمنتج: $existingProductName');
}

/// Product not found failure
class ProductNotFoundFailure extends InventoryFailure {
  final int productId;

  const ProductNotFoundFailure(this.productId) : super('المنتج غير موجود');
}

/// Network/connectivity failure
class NetworkFailure extends InventoryFailure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت']);
}

/// Sync failure for offline-first operations
class SyncFailure extends InventoryFailure {
  final int? pendingChanges;

  const SyncFailure(super.message, {this.pendingChanges});
}

/// Permission failure
class PermissionFailure extends InventoryFailure {
  const PermissionFailure([super.message = 'ليس لديك صلاحية لهذا الإجراء']);
}

/// Stock operation failure (e.g., insufficient stock)
class StockOperationFailure extends InventoryFailure {
  final int availableStock;
  final int requestedAmount;

  StockOperationFailure({
    required this.availableStock,
    required this.requestedAmount,
  }) : super(
          'الكمية المطلوبة ($requestedAmount) أكبر من المتوفر ($availableStock)',
        );
}
