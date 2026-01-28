/// Validation result for product data
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const ValidationResult({
    required this.isValid,
    this.errors = const {},
  });

  /// Create a valid result
  const ValidationResult.valid()
      : isValid = true,
        errors = const {};

  /// Create an invalid result with errors
  const ValidationResult.invalid(this.errors) : isValid = false;

  /// Check if result is not valid
  bool get isNotValid => !isValid;

  /// Check if a specific field has an error
  bool hasErrorFor(String field) => errors.containsKey(field);

  /// Get error message for a specific field
  String? errorFor(String field) => errors[field];
}

/// Product validator with business rules
/// Pure Dart - NO Flutter imports!
class ProductValidator {
  // Business rule constants - easily configurable
  static const int minNameLength = 2;
  static const int maxNameLength = 200;
  static const int maxBarcodeLength = 20;
  static const double maxPrice = 999999999;
  static const int maxQuantity = 99999999;

  /// Validate product data for creation/update
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
    final errors = <String, String>{};

    // Name validation
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      errors['name'] = 'اسم المنتج مطلوب';
    } else if (trimmedName.length < minNameLength) {
      errors['name'] = 'اسم المنتج قصير جداً (الحد الأدنى $minNameLength أحرف)';
    } else if (trimmedName.length > maxNameLength) {
      errors['name'] = 'اسم المنتج طويل جداً (الحد الأقصى $maxNameLength حرف)';
    } else if (_containsDangerousCharacters(trimmedName)) {
      errors['name'] = 'اسم المنتج يحتوي على أحرف غير مسموح بها';
    }

    // Company validation
    final trimmedCompany = company.trim();
    if (trimmedCompany.isEmpty) {
      errors['company'] = 'اسم الشركة مطلوب';
    } else if (_containsDangerousCharacters(trimmedCompany)) {
      errors['company'] = 'اسم الشركة يحتوي على أحرف غير مسموح بها';
    }

    // Category validation
    if (category.trim().isEmpty) {
      errors['category'] = 'الفئة مطلوبة';
    }

    // Barcode validation (optional but if provided, must be valid)
    if (barcode.isNotEmpty) {
      if (barcode.length > maxBarcodeLength) {
        errors['barcode'] =
            'الباركود طويل جداً (الحد الأقصى $maxBarcodeLength رقم)';
      } else if (!_isValidBarcodeFormat(barcode)) {
        errors['barcode'] = 'صيغة الباركود غير صحيحة';
      }
    }

    // Quantity validation
    if (quantity < 0) {
      errors['quantity'] = 'الكمية لا يمكن أن تكون سالبة';
    } else if (quantity > maxQuantity) {
      errors['quantity'] = 'الكمية كبيرة جداً';
    }

    // Price validation
    if (price < 0) {
      errors['price'] = 'السعر لا يمكن أن يكون سالباً';
    } else if (price > maxPrice) {
      errors['price'] = 'السعر كبير جداً';
    }

    // Cost price validation
    if (costPrice != null) {
      if (costPrice < 0) {
        errors['costPrice'] = 'سعر التكلفة لا يمكن أن يكون سالباً';
      } else if (costPrice > price) {
        // Warning, not error - cost can be higher in some cases
        // errors['costPrice'] = 'سعر التكلفة أعلى من سعر البيع';
      }
    }

    // Expiry date validation
    if (expiryDate != null) {
      final now = DateTime.now();
      if (expiryDate.isBefore(now)) {
        // Product is already expired - allow but could warn
        // errors['expiryDate'] = 'تاريخ الصلاحية منتهي';
      }
    }

    return errors.isEmpty
        ? const ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }

  /// Simplified validation for Midgram-style add product
  ValidationResult validateSimple({
    required String name,
    required int quantity,
    required double price,
    required double cost,
    required DateTime expiryDate,
  }) {
    final errors = <String, String>{};

    // Name validation
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      errors['name'] = 'اسم المنتج مطلوب';
    } else if (trimmedName.length < minNameLength) {
      errors['name'] = 'اسم المنتج قصير جداً';
    } else if (trimmedName.length > maxNameLength) {
      errors['name'] = 'اسم المنتج طويل جداً';
    } else if (_containsDangerousCharacters(trimmedName)) {
      errors['name'] = 'اسم المنتج يحتوي على أحرف غير مسموح بها';
    }

    // Quantity validation
    if (quantity <= 0) {
      errors['quantity'] = 'الكمية يجب أن تكون أكبر من صفر';
    } else if (quantity > maxQuantity) {
      errors['quantity'] = 'الكمية كبيرة جداً';
    }

    // Price validation
    if (price <= 0) {
      errors['price'] = 'السعر يجب أن يكون أكبر من صفر';
    } else if (price > maxPrice) {
      errors['price'] = 'السعر كبير جداً';
    }

    // Cost validation
    if (cost < 0) {
      errors['cost'] = 'التكلفة لا يمكن أن تكون سالبة';
    }

    return errors.isEmpty
        ? const ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }

  /// Check for XSS/SQL injection characters
  bool _containsDangerousCharacters(String input) {
    // Check for common XSS/injection patterns
    final dangerousPatterns = RegExp(
        r'[<>{}"\[\]\\]|script|SELECT|INSERT|DELETE|DROP|UPDATE',
        caseSensitive: false);
    return dangerousPatterns.hasMatch(input);
  }

  /// Validate barcode format
  bool _isValidBarcodeFormat(String barcode) {
    // Allow alphanumeric and common barcode characters
    final validPattern = RegExp(r'^[A-Za-z0-9\-]+$');
    return validPattern.hasMatch(barcode);
  }

  /// Validate barcode for specific format (EAN-13, EAN-8, etc.)
  bool isValidEAN13(String barcode) {
    if (barcode.length != 13) return false;
    if (!RegExp(r'^\d{13}$').hasMatch(barcode)) return false;

    // Check digit validation
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(barcode[12]);
  }

  /// Validate barcode for EAN-8 format
  bool isValidEAN8(String barcode) {
    if (barcode.length != 8) return false;
    if (!RegExp(r'^\d{8}$').hasMatch(barcode)) return false;

    int sum = 0;
    for (int i = 0; i < 7; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(barcode[7]);
  }
}
