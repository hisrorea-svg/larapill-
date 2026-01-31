import 'package:larapill/features/inventory/domain/validators/product_validator.dart';

/// Mock implementation of ProductValidator for testing
class MockProductValidator extends ProductValidator {
  ValidationResult _mockResult = const ValidationResult.valid();
  Map<String, String> _fieldErrors = {};

  void setValidationResult(bool isValid, {Map<String, String>? errors}) {
    _fieldErrors = errors ?? {};
    _mockResult = isValid
        ? const ValidationResult.valid()
        : ValidationResult.invalid(_fieldErrors);
  }

  void reset() {
    _fieldErrors = {};
    _mockResult = const ValidationResult.valid();
  }

  @override
  ValidationResult validate({
    required String name,
    required String company,
    required String category,
    required String barcode,
    required int quantity,
    required double price,
    double? costPrice,
    DateTime? expiryDate,
  }) {
    return _mockResult;
  }

  @override
  ValidationResult validateSimple({
    required String name,
    required int quantity,
    required double price,
    required double cost,
    required DateTime expiryDate,
  }) {
    return _mockResult;
  }
}
