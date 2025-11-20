/// 🔍 مكتبة شاملة للتحقق من صحة المدخلات
/// تغطي جميع أنواع البيانات المستخدمة في النظام
class Validators {
  // ==================== التحقق من الحقول المطلوبة ====================

  /// التحقق من أن الحقل غير فارغ
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  // ==================== بيانات المستخدمين ====================

  /// التحقق من اسم المستخدم
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المستخدم مطلوب';
    }

    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }

    if (trimmed.length > 50) {
      return 'اسم المستخدم لا يجب أن يزيد عن 50 حرف';
    }

    // فقط أحرف إنجليزية وأرقام و_
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return 'اسم المستخدم يجب أن يحتوي على أحرف إنجليزية وأرقام فقط';
    }

    // لا يبدأ برقم
    if (RegExp(r'^\d').hasMatch(trimmed)) {
      return 'اسم المستخدم لا يمكن أن يبدأ برقم';
    }

    return null;
  }

  /// التحقق من الاسم الكامل
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم الكامل مطلوب';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'الاسم الكامل يجب أن يكون حرفين على الأقل';
    }

    if (trimmed.length > 100) {
      return 'الاسم الكامل لا يجب أن يزيد عن 100 حرف';
    }

    // يحتوي على أحرف عربية أو إنجليزية ومسافات فقط
    if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(trimmed)) {
      return 'الاسم يجب أن يحتوي على أحرف عربية أو إنجليزية فقط';
    }

    return null;
  }

  /// التحقق من كلمة المرور (للإنشاء الجديد)
  static String? password(String? value, {bool isStrict = true}) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }

    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }

    if (isStrict) {
      if (value.length < 8) {
        return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
      }

      if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
        return 'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل';
      }

      if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
        return 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل';
      }

      if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
        return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
      }

      if (!RegExp(r'(?=.*[!@#$%^&*(),.?\":{}|<>])').hasMatch(value)) {
        return 'كلمة المرور يجب أن تحتوي على رمز خاص واحد على الأقل';
      }
    }

    return null;
  }

  /// التحقق من تطابق كلمات المرور
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }

    if (value != originalPassword) {
      return 'كلمات المرور غير متطابقة';
    }

    return null;
  }

  // ==================== معلومات الاتصال ====================

  /// التحقق من رقم الهاتف
  static String? phoneNumber(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'رقم الهاتف مطلوب' : null;
    }

    final trimmed = value.trim();

    // إزالة الأحرف غير الرقمية للتحقق
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
    }

    if (digitsOnly.length > 15) {
      return 'رقم الهاتف لا يجب أن يزيد عن 15 رقم';
    }

    // تنسيق أرقام الهواتف (يسمح بـ +، أرقام، مسافات، -, (, ))
    if (!RegExp(r'^[+]?[\d\s\-\(\)]{10,20}$').hasMatch(trimmed)) {
      return 'تنسيق رقم الهاتف غير صحيح';
    }

    return null;
  }

  /// التحقق من البريد الإلكتروني
  static String? email(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'البريد الإلكتروني مطلوب' : null;
    }

    final trimmed = value.trim();

    // تحقق من التنسيق الأساسي
    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
      return 'تنسيق البريد الإلكتروني غير صحيح';
    }

    if (trimmed.length > 254) {
      return 'البريد الإلكتروني طويل جداً';
    }

    return null;
  }

  // ==================== الأرقام والمبالغ ====================

  /// التحقق من الأرقام الصحيحة
  static String? integer(
    String? value,
    String fieldName, {
    int? min,
    int? max,
    bool isRequired = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? '$fieldName مطلوب' : null;
    }

    final intValue = int.tryParse(value.trim());
    if (intValue == null) {
      return '$fieldName يجب أن يكون رقم صحيح';
    }

    if (min != null && intValue < min) {
      return '$fieldName يجب أن يكون $min أو أكثر';
    }

    if (max != null && intValue > max) {
      return '$fieldName يجب أن يكون $max أو أقل';
    }

    return null;
  }

  /// التحقق من الأرقام العشرية (للأسعار والكميات)
  static String? decimal(
    String? value,
    String fieldName, {
    double? min,
    double? max,
    int? decimalPlaces,
    bool isRequired = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? '$fieldName مطلوب' : null;
    }

    final doubleValue = double.tryParse(value.trim());
    if (doubleValue == null) {
      return '$fieldName يجب أن يكون رقم صحيح';
    }

    if (min != null && doubleValue < min) {
      return '$fieldName يجب أن يكون $min أو أكثر';
    }

    if (max != null && doubleValue > max) {
      return '$fieldName يجب أن يكون $max أو أقل';
    }

    // فحص عدد الخانات العشرية
    if (decimalPlaces != null) {
      final parts = value.trim().split('.');
      if (parts.length > 1 && parts[1].length > decimalPlaces) {
        return '$fieldName لا يجب أن يحتوي على أكثر من $decimalPlaces خانة عشرية';
      }
    }

    return null;
  }

  /// التحقق من السعر
  static String? price(String? value, {bool isRequired = true}) {
    return decimal(
      value,
      'السعر',
      min: 0.01,
      max: 999999.99,
      decimalPlaces: 2,
      isRequired: isRequired,
    );
  }

  /// التحقق من الكمية
  static String? quantity(String? value,
      {bool allowDecimal = true, bool isRequired = true}) {
    if (allowDecimal) {
      return decimal(
        value,
        'الكمية',
        min: 0.01,
        max: 999999.99,
        decimalPlaces: 2,
        isRequired: isRequired,
      );
    } else {
      return integer(
        value,
        'الكمية',
        min: 1,
        max: 999999,
        isRequired: isRequired,
      );
    }
  }

  // ==================== التواريخ والأوقات ====================

  /// التحقق من صيغة التاريخ
  static String? date(String? value, String fieldName,
      {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? '$fieldName مطلوب' : null;
    }

    try {
      DateTime.parse(value.trim());
      return null;
    } catch (e) {
      return '$fieldName غير صحيح (استخدم الصيغة: YYYY-MM-DD)';
    }
  }

  /// التحقق من تاريخ الإنتاج
  static String? productionDate(String? value, {bool isRequired = true}) {
    final dateError = date(value, 'تاريخ الإنتاج', isRequired: isRequired);
    if (dateError != null) return dateError;

    if (value != null && value.trim().isNotEmpty) {
      final productionDate = DateTime.parse(value.trim());
      final today = DateTime.now();

      // لا يمكن أن يكون في المستقبل
      if (productionDate.isAfter(today)) {
        return 'تاريخ الإنتاج لا يمكن أن يكون في المستقبل';
      }

      // لا يمكن أن يكون أقدم من 10 سنوات
      final tenYearsAgo = today.subtract(const Duration(days: 365 * 10));
      if (productionDate.isBefore(tenYearsAgo)) {
        return 'تاريخ الإنتاج قديم جداً';
      }
    }

    return null;
  }

  /// التحقق من تاريخ انتهاء الصلاحية
  static String? expiryDate(String? value,
      {String? productionDateValue, bool isRequired = true}) {
    final dateError =
        date(value, 'تاريخ انتهاء الصلاحية', isRequired: isRequired);
    if (dateError != null) return dateError;

    if (value != null && value.trim().isNotEmpty) {
      final expiryDate = DateTime.parse(value.trim());
      final today = DateTime.now();

      // تحذير إذا كان منتهي الصلاحية (لكن نسمح به)
      if (expiryDate.isBefore(today)) {
        // يمكن إرجاع تحذير بدلاً من خطأ
        // return 'تاريخ انتهاء الصلاحية في الماضي';
      }

      // فحص أن تاريخ الانتهاء بعد تاريخ الإنتاج
      if (productionDateValue != null &&
          productionDateValue.trim().isNotEmpty) {
        try {
          final productionDate = DateTime.parse(productionDateValue.trim());
          if (expiryDate.isBefore(productionDate)) {
            return 'تاريخ انتهاء الصلاحية لا يمكن أن يكون قبل تاريخ الإنتاج';
          }
        } catch (e) {
          // تجاهل إذا كان تاريخ الإنتاج غير صحيح
        }
      }
    }

    return null;
  }

  // ==================== معلومات المنتجات ====================

  /// التحقق من اسم المنتج
  static String? productName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المنتج مطلوب';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'اسم المنتج يجب أن يكون حرفين على الأقل';
    }

    if (trimmed.length > 200) {
      return 'اسم المنتج لا يجب أن يزيد عن 200 حرف';
    }

    return null;
  }

  /// التحقق من رقم الدفعة
  static String? batchNumber(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'رقم الدفعة مطلوب' : null;
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'رقم الدفعة يجب أن يكون حرفين على الأقل';
    }

    if (trimmed.length > 50) {
      return 'رقم الدفعة لا يجب أن يزيد عن 50 حرف';
    }

    // يمكن أن يحتوي على أحرف، أرقام، وبعض الرموز
    if (!RegExp(r'^[a-zA-Z0-9\-_/]+$').hasMatch(trimmed)) {
      return 'رقم الدفعة يجب أن يحتوي على أحرف وأرقام فقط';
    }

    return null;
  }

  /// التحقق من رقم باركود
  static String? barcode(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'الباركود مطلوب' : null;
    }

    final trimmed = value.trim();

    // الباركود يجب أن يكون أرقام فقط
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'الباركود يجب أن يحتوي على أرقام فقط';
    }

    // طول الباركود (EAN-8, UPC-A, EAN-13, إلخ)
    if (trimmed.length < 8 || trimmed.length > 18) {
      return 'الباركود يجب أن يكون بين 8 و 18 رقم';
    }

    return null;
  }

  // ==================== العناوين والنصوص ====================

  /// التحقق من العنوان
  static String? address(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'العنوان مطلوب' : null;
    }

    final trimmed = value.trim();

    if (trimmed.length > 500) {
      return 'العنوان لا يجب أن يزيد عن 500 حرف';
    }

    return null;
  }

  /// التحقق من الملاحظات
  static String? notes(String? value, {int maxLength = 1000}) {
    if (value == null || value.trim().isEmpty) {
      return null; // الملاحظات اختيارية دائماً
    }

    if (value.trim().length > maxLength) {
      return 'الملاحظات لا يجب أن تزيد عن $maxLength حرف';
    }

    return null;
  }

  // ==================== دوال مساعدة ====================

  /// فحص إذا كانت كلمة المرور قوية
  static Map<String, dynamic> checkPasswordStrength(String password) {
    final checks = {
      'length': password.length >= 8,
      'hasUpper': RegExp(r'[A-Z]').hasMatch(password),
      'hasLower': RegExp(r'[a-z]').hasMatch(password),
      'hasDigit': RegExp(r'[0-9]').hasMatch(password),
      'hasSpecial': RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(password),
    };

    final score = checks.values.where((check) => check).length;
    String strength;

    if (score < 2) {
      strength = 'ضعيفة جداً';
    } else if (score < 3) {
      strength = 'ضعيفة';
    } else if (score < 4) {
      strength = 'متوسطة';
    } else if (score < 5) {
      strength = 'قوية';
    } else {
      strength = 'قوية جداً';
    }

    return {
      'strength': strength,
      'score': score,
      'checks': checks,
    };
  }

  /// تنظيف النص من المسافات الزائدة
  static String cleanText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// فحص إذا كان النص يحتوي على كلمات ممنوعة
  static String? checkForbiddenWords(
      String? value, List<String> forbiddenWords) {
    if (value == null || value.trim().isEmpty) return null;

    final lowerValue = value.toLowerCase();

    for (final word in forbiddenWords) {
      if (lowerValue.contains(word.toLowerCase())) {
        return 'النص يحتوي على كلمات غير مسموحة';
      }
    }

    return null;
  }
}
