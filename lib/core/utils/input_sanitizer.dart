import 'package:flutter/services.dart';

/// 🧹 نظام تنظيف وتعقيم المدخلات
/// يمنع XSS، injection attacks، وأحرف خاصة ضارة
class InputSanitizer {
  // ==================== تنظيف للعرض ====================

  /// تنظيف النص للعرض في واجهة المستخدم
  /// يزيل الأحرف الخطرة ويحمي من XSS
  static String sanitizeForDisplay(String? input) {
    if (input == null || input.isEmpty) return '';

    return input
        .trim()
        // إزالة control characters (0x00-0x1F, 0x7F)
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        // إزالة HTML tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // تحويل أحرف HTML الخاصة
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        // إزالة مسافات زائدة
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// تنظيف النص مع الحفاظ على السطور الجديدة
  static String sanitizeMultilineText(String? input) {
    if (input == null || input.isEmpty) return '';

    return input
        .trim()
        // إزالة control characters ماعدا \n و \r
        .replaceAll(RegExp(r'[\x00-\x09\x0B-\x0C\x0E-\x1F\x7F]'), '')
        // إزالة HTML tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // تحويل أحرف HTML الخاصة
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .trim();
  }

  // ==================== تنظيف الأسماء ====================

  /// تنظيف اسم المستخدم (أحرف إنجليزية وأرقام و_ فقط)
  static String sanitizeUsername(String? input) {
    if (input == null || input.isEmpty) return '';

    final cleaned = input
        .trim()
        .toLowerCase()
        // إزالة كل شيء ما عدا أحرف إنجليزية وأرقام و_
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    return cleaned.length > 50 ? cleaned.substring(0, 50) : cleaned;
  }

  /// تنظيف الاسم الكامل (عربي/إنجليزي ومسافات)
  static String sanitizeFullName(String? input) {
    if (input == null || input.isEmpty) return '';

    final cleaned = input
        .trim()
        // السماح بالعربي والإنجليزي والمسافات فقط
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned.length > 100 ? cleaned.substring(0, 100) : cleaned;
  }

  /// تنظيف اسم المنتج
  static String sanitizeProductName(String? input) {
    if (input == null || input.isEmpty) return '';

    final cleaned = input
        .trim()
        // السماح بالعربي والإنجليزي والأرقام والمسافات وبعض الرموز
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z0-9\s\-\+\(\)\/%]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned.length > 200 ? cleaned.substring(0, 200) : cleaned;
  }

  // ==================== تنظيف الأرقام ====================

  /// تنظيف الأرقام (أرقام ونقطة عشرية فقط)
  static String sanitizeNumeric(String? input, {bool allowDecimal = true}) {
    if (input == null || input.isEmpty) return '';

    if (allowDecimal) {
      return input.replaceAll(RegExp(r'[^0-9.]'), '');
    } else {
      return input.replaceAll(RegExp(r'[^0-9]'), '');
    }
  }

  /// تنظيف رقم الهاتف
  static String sanitizePhoneNumber(String? input) {
    if (input == null || input.isEmpty) return '';

    return input
        .trim()
        // السماح بالأرقام و + و - و ( ) ومسافة
        .replaceAll(RegExp(r'[^0-9+\-\(\)\s]'), '')
        .substring(0, input.length > 20 ? 20 : input.length);
  }

  // ==================== تنظيف البريد الإلكتروني ====================

  /// تنظيف البريد الإلكتروني
  static String sanitizeEmail(String? input) {
    if (input == null || input.isEmpty) return '';

    return input
        .trim()
        .toLowerCase()
        // السماح بالأحرف الإنجليزية والأرقام و @ . - _
        .replaceAll(RegExp(r'[^a-z0-9@.\-_]'), '')
        .substring(0, input.length > 254 ? 254 : input.length);
  }

  // ==================== تنظيف للبحث ====================

  /// تنظيف نص البحث
  static String sanitizeSearchQuery(String? input) {
    if (input == null || input.isEmpty) return '';

    return input
        .trim()
        // إزالة أحرف SQL خطرة
        .replaceAll("'", '')
        .replaceAll('"', '')
        .replaceAll(';', '')
        .replaceAll('--', '')
        // إزالة control characters
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .substring(0, input.length > 100 ? 100 : input.length)
        .trim();
  }

  /// تنظيف باركود
  static String sanitizeBarcode(String? input) {
    if (input == null || input.isEmpty) return '';

    return input
        .trim()
        // السماح بالأرقام والأحرف الإنجليزية والرموز الشائعة في الباركود
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '')
        .substring(0, input.length > 50 ? 50 : input.length)
        .toUpperCase();
  }

  // ==================== تنظيف الملاحظات ====================

  /// تنظيف الملاحظات والنصوص الطويلة
  static String sanitizeNotes(String? input, {int maxLength = 500}) {
    if (input == null || input.isEmpty) return '';

    return sanitizeMultilineText(input).substring(
      0,
      input.length > maxLength ? maxLength : input.length,
    );
  }

  // ==================== تنظيف المسارات ====================

  /// تنظيف مسار الملف
  static String sanitizeFilePath(String? input) {
    if (input == null || input.isEmpty) return '';

    return input
        .trim()
        // إزالة أحرف خطرة من المسارات
        .replaceAll(RegExp(r'[<>"|?*]'), '')
        // إزالة .. للحماية من path traversal
        .replaceAll('..', '')
        .trim();
  }

  /// تنظيف اسم الملف
  static String sanitizeFileName(String? input) {
    if (input == null || input.isEmpty) return '';

    return input
        .trim()
        // السماح بالأحرف الإنجليزية والعربية والأرقام و _ و - و .
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z0-9_\-.]'), '_')
        .substring(0, input.length > 255 ? 255 : input.length);
  }

  // ==================== فحص الأمان ====================

  /// فحص إذا كان النص يحتوي على محاولة SQL Injection
  static bool containsSqlInjection(String input) {
    final upperInput = input.toUpperCase();

    // تحقق من الرموز الخطرة أولاً (-- و /* و */)
    if (upperInput.contains('--') ||
        upperInput.contains('/*') ||
        upperInput.contains('*/') ||
        upperInput.contains('xp_') ||
        upperInput.contains('sp_')) {
      return true;
    }

    // كلمات SQL الخطرة - يجب أن تكون في سياق SQL (مع كلمات أخرى)
    final sqlPatterns = [
      RegExp(r'\bSELECT\s+.*\s+FROM\b', caseSensitive: false),
      RegExp(r'\bINSERT\s+INTO\b', caseSensitive: false),
      RegExp(r'\bUPDATE\s+.*\s+SET\b', caseSensitive: false),
      RegExp(r'\bDELETE\s+FROM\b', caseSensitive: false),
      RegExp(r'\bDROP\s+(TABLE|DATABASE)\b', caseSensitive: false),
      RegExp(r'\bCREATE\s+(TABLE|DATABASE)\b', caseSensitive: false),
      RegExp(r'\bALTER\s+TABLE\b', caseSensitive: false),
      RegExp(r'\bEXEC(UTE)?\s+', caseSensitive: false),
      RegExp(r'\bUNION\s+(ALL\s+)?SELECT\b', caseSensitive: false),
      RegExp(r';.*DROP\b', caseSensitive: false),
      RegExp(r';.*DELETE\b', caseSensitive: false),
    ];

    // تحقق من أنماط SQL الخطرة (في سياق كامل)
    return sqlPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// فحص إذا كان النص يحتوي على محاولة XSS
  static bool containsXss(String input) {
    final xssPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // onclick, onload, etc.
      RegExp(r'<iframe', caseSensitive: false),
      RegExp(r'<embed', caseSensitive: false),
      RegExp(r'<object', caseSensitive: false),
    ];

    return xssPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// فحص شامل للأمان
  static Map<String, dynamic> validateSecurity(String input) {
    final issues = <String>[];

    if (containsSqlInjection(input)) {
      issues.add('محاولة SQL Injection محتملة');
    }

    if (containsXss(input)) {
      issues.add('محاولة XSS محتملة');
    }

    if (input.contains('..')) {
      issues.add('محاولة Path Traversal محتملة');
    }

    return {
      'isSafe': issues.isEmpty,
      'issues': issues,
    };
  }

  // ==================== Input Formatters للـ TextFields ====================

  /// Formatter لأسماء المستخدمين
  static List<TextInputFormatter> get usernameFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
        LengthLimitingTextInputFormatter(50),
      ];

  /// Formatter للأرقام الصحيحة
  static List<TextInputFormatter> get integerFormatters => [
        FilteringTextInputFormatter.digitsOnly,
      ];

  /// Formatter للأرقام العشرية
  static List<TextInputFormatter> get decimalFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ];

  /// Formatter لأرقام الهواتف
  static List<TextInputFormatter> get phoneFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\(\)\s]')),
        LengthLimitingTextInputFormatter(20),
      ];

  /// Formatter للباركود
  static List<TextInputFormatter> get barcodeFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
        LengthLimitingTextInputFormatter(50),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return newValue.copyWith(text: newValue.text.toUpperCase());
        }),
      ];

  /// Formatter للبريد الإلكتروني
  static List<TextInputFormatter> get emailFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@.\-_]')),
        LengthLimitingTextInputFormatter(254),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return newValue.copyWith(text: newValue.text.toLowerCase());
        }),
      ];

  // ==================== دوال مساعدة ====================

  /// قص النص مع إضافة نقاط في النهاية
  static String truncate(String input, int maxLength, {String suffix = '...'}) {
    if (input.length <= maxLength) return input;

    return input.substring(0, maxLength - suffix.length) + suffix;
  }

  /// إزالة المسافات الزائدة من البداية والنهاية ومن الوسط
  static String normalizeWhitespace(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// تحويل النص إلى slug (للاستخدام في URLs أو معرفات)
  static String toSlug(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// استخراج الأرقام فقط من النص
  static String extractNumbers(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// استخراج الأحرف فقط من النص
  static String extractLetters(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z\u0600-\u06FF]'), '');
  }

  /// تنظيف شامل مع إزالة جميع الأحرف غير المطبوعة
  static String deepClean(String input) {
    return input
        .trim()
        // إزالة Unicode non-printable
        .replaceAll(RegExp(r'\p{C}', unicode: true), '')
        // إزالة zero-width characters
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        // تطبيع المسافات
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
