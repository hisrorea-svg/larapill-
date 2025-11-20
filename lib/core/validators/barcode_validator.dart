import '../models/barcode_type.dart';

/// فئة للتحقق من صحة الباركود
class BarcodeValidator {
  /// التحقق من صحة الباركود حسب النوع
  static ValidationResult validate(String barcode, BarcodeType type) {
    if (barcode.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'الباركود فارغ',
      );
    }

    switch (type) {
      case BarcodeType.ean13:
        return _validateEAN13(barcode);
      case BarcodeType.ean8:
        return _validateEAN8(barcode);
      case BarcodeType.upcA:
        return _validateUPCA(barcode);
      case BarcodeType.upcE:
        return _validateUPCE(barcode);
      case BarcodeType.code128:
        return _validateCode128(barcode);
      case BarcodeType.qrCode:
        return _validateQRCode(barcode);
    }
  }

  /// التحقق من EAN-13
  static ValidationResult _validateEAN13(String barcode) {
    // يجب أن يكون 13 رقماً بالضبط
    if (barcode.length != 13) {
      return ValidationResult(
        isValid: false,
        error:
            'EAN-13 يجب أن يتكون من 13 رقماً بالضبط (الطول الحالي: ${barcode.length})',
      );
    }

    // يجب أن يحتوي على أرقام فقط
    if (!RegExp(r'^\d{13}$').hasMatch(barcode)) {
      return ValidationResult(
        isValid: false,
        error: 'EAN-13 يجب أن يحتوي على أرقام فقط',
      );
    }

    // التحقق من checksum
    if (!_isValidEAN13Checksum(barcode)) {
      return ValidationResult(
        isValid: false,
        error: 'checksum غير صحيح لـ EAN-13',
        warning: 'قد يكون الباركود غير قابل للقراءة',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// التحقق من EAN-8
  static ValidationResult _validateEAN8(String barcode) {
    if (barcode.length != 8) {
      return ValidationResult(
        isValid: false,
        error:
            'EAN-8 يجب أن يتكون من 8 أرقام بالضبط (الطول الحالي: ${barcode.length})',
      );
    }

    if (!RegExp(r'^\d{8}$').hasMatch(barcode)) {
      return ValidationResult(
        isValid: false,
        error: 'EAN-8 يجب أن يحتوي على أرقام فقط',
      );
    }

    if (!_isValidEAN8Checksum(barcode)) {
      return ValidationResult(
        isValid: false,
        error: 'checksum غير صحيح لـ EAN-8',
        warning: 'قد يكون الباركود غير قابل للقراءة',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// التحقق من UPC-A
  static ValidationResult _validateUPCA(String barcode) {
    if (barcode.length != 12) {
      return ValidationResult(
        isValid: false,
        error:
            'UPC-A يجب أن يتكون من 12 رقماً بالضبط (الطول الحالي: ${barcode.length})',
      );
    }

    if (!RegExp(r'^\d{12}$').hasMatch(barcode)) {
      return ValidationResult(
        isValid: false,
        error: 'UPC-A يجب أن يحتوي على أرقام فقط',
      );
    }

    if (!_isValidUPCAChecksum(barcode)) {
      return ValidationResult(
        isValid: false,
        error: 'checksum غير صحيح لـ UPC-A',
        warning: 'قد يكون الباركود غير قابل للقراءة',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// التحقق من UPC-E
  static ValidationResult _validateUPCE(String barcode) {
    // UPC-E يمكن أن يكون 6 أو 8 أرقام (مع system digit و check digit)
    if (barcode.length != 6 && barcode.length != 8) {
      return ValidationResult(
        isValid: false,
        error:
            'UPC-E يجب أن يتكون من 6 أو 8 أرقام (الطول الحالي: ${barcode.length})',
      );
    }

    if (!RegExp(r'^\d+$').hasMatch(barcode)) {
      return ValidationResult(
        isValid: false,
        error: 'UPC-E يجب أن يحتوي على أرقام فقط',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// التحقق من Code 128
  static ValidationResult _validateCode128(String barcode) {
    if (barcode.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'الباركود فارغ',
      );
    }

    if (barcode.length > 80) {
      return ValidationResult(
        isValid: false,
        error:
            'Code 128 يجب ألا يتجاوز 80 حرفاً (الطول الحالي: ${barcode.length})',
      );
    }

    // Code 128 يدعم ASCII القابلة للطباعة
    if (!RegExp(r'^[\x20-\x7E]+$').hasMatch(barcode)) {
      return ValidationResult(
        isValid: false,
        error: 'Code 128 يحتوي على أحرف غير مدعومة',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// التحقق من QR Code
  static ValidationResult _validateQRCode(String barcode) {
    if (barcode.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'محتوى QR Code فارغ',
      );
    }

    if (barcode.length > 4296) {
      return ValidationResult(
        isValid: false,
        error:
            'QR Code يجب ألا يتجاوز 4296 حرفاً (الطول الحالي: ${barcode.length})',
      );
    }

    return ValidationResult(isValid: true);
  }

  // ==================== حساب Checksum ====================

  /// حساب checksum لـ EAN-13
  static bool _isValidEAN13Checksum(String barcode) {
    if (barcode.length != 13) return false;

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i.isEven ? digit : digit * 3);
    }

    int checksum = (10 - (sum % 10)) % 10;
    return checksum == int.parse(barcode[12]);
  }

  /// حساب checksum لـ EAN-8
  static bool _isValidEAN8Checksum(String barcode) {
    if (barcode.length != 8) return false;

    int sum = 0;
    for (int i = 0; i < 7; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i.isEven ? digit * 3 : digit);
    }

    int checksum = (10 - (sum % 10)) % 10;
    return checksum == int.parse(barcode[7]);
  }

  /// حساب checksum لـ UPC-A
  static bool _isValidUPCAChecksum(String barcode) {
    if (barcode.length != 12) return false;

    int sum = 0;
    for (int i = 0; i < 11; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i.isEven ? digit * 3 : digit);
    }

    int checksum = (10 - (sum % 10)) % 10;
    return checksum == int.parse(barcode[11]);
  }

  /// حساب الـ checksum digit الصحيح لـ EAN-13
  static String calculateEAN13Checksum(String barcode) {
    if (barcode.length < 12) {
      barcode = barcode.padLeft(12, '0');
    }

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.tryParse(barcode[i]) ?? 0;
      sum += (i.isEven ? digit : digit * 3);
    }

    int checksum = (10 - (sum % 10)) % 10;
    return barcode.substring(0, 12) + checksum.toString();
  }

  /// تنظيف وتنسيق الباركود حسب النوع
  static String sanitize(String barcode, BarcodeType type) {
    barcode = barcode.trim().toUpperCase();

    switch (type) {
      case BarcodeType.ean13:
      case BarcodeType.ean8:
      case BarcodeType.upcA:
      case BarcodeType.upcE:
        // إزالة كل شيء ماعدا الأرقام
        return barcode.replaceAll(RegExp(r'[^\d]'), '');
      case BarcodeType.code128:
        // إزالة control characters
        return barcode.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
      case BarcodeType.qrCode:
        // QR يدعم كل شيء تقريباً
        return barcode;
    }
  }

  /// اقتراح نوع الباركود المناسب حسب المحتوى
  static BarcodeType suggestType(String barcode) {
    barcode = barcode.trim();

    // تحقق من الطول والأرقام
    if (RegExp(r'^\d{13}$').hasMatch(barcode)) {
      return BarcodeType.ean13;
    }
    if (RegExp(r'^\d{12}$').hasMatch(barcode)) {
      return BarcodeType.upcA;
    }
    if (RegExp(r'^\d{8}$').hasMatch(barcode)) {
      // UPC-E يدعم 6 أرقام فقط، لكن 8 أرقام = EAN-8
      return BarcodeType.ean8;
    }
    if (RegExp(r'^\d{6}$').hasMatch(barcode)) {
      // UPC-E يناسب 6 أرقام
      return BarcodeType.upcE;
    }

    // إذا كان يحتوي على أحرف أو أرقام قليلة، استخدم Code128
    // Code128 مرن جداً ويدعم أي طول
    return BarcodeType.code128;
  }
}

/// نتيجة التحقق من الباركود
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? warning;

  ValidationResult({
    required this.isValid,
    this.error,
    this.warning,
  });

  /// رسالة كاملة للمستخدم
  String get message {
    if (isValid && warning != null) {
      return 'تحذير: $warning';
    }
    if (!isValid && error != null) {
      return 'خطأ: $error';
    }
    return 'الباركود صحيح';
  }
}
