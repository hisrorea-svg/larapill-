import 'dart:developer' as developer;

/// 🔴 نظام استثناءات مخصص شامل
/// يوفر أنواع استثناءات محددة لكل حالة مع معالجة احترافية

// ==================== Base Exception ====================

/// الاستثناء الأساسي لجميع استثناءات التطبيق
abstract class AppException implements Exception {
  final String message;
  final String? userMessage; // رسالة للمستخدم (عربي)
  final String? code; // كود الخطأ
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppException(
    this.message, {
    this.userMessage,
    this.code,
    this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now() {
    // تسجيل الخطأ تلقائياً
    _logException();
  }

  void _logException() {
    developer.log(
      '❌ $runtimeType: $message',
      name: 'AppException',
      error: originalError,
      stackTrace: stackTrace,
      time: timestamp,
    );
  }

  /// الرسالة التي تُعرض للمستخدم
  String getUserMessage() => userMessage ?? message;

  @override
  String toString() => '$runtimeType: $message';
}

// ==================== قاعدة البيانات ====================

/// استثناء عند فشل عمليات قاعدة البيانات
class DatabaseException extends AppException {
  final String? tableName;
  final String? operation; // insert, update, delete, query

  DatabaseException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
    this.tableName,
    this.operation,
  });

  @override
  String getUserMessage() =>
      userMessage ?? 'حدث خطأ في قاعدة البيانات. يرجى المحاولة مرة أخرى.';
}

/// استثناء عند فشل الاتصال بقاعدة البيانات
class DatabaseConnectionException extends DatabaseException {
  DatabaseConnectionException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() =>
      userMessage ?? 'فشل الاتصال بقاعدة البيانات. تحقق من إعدادات التطبيق.';
}

// ==================== ذاكرة التخزين المؤقتة ====================

/// استثناء عند فشل عمليات ذاكرة التخزين المؤقتة (SharedPreferences)
class CacheException extends AppException {
  CacheException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() =>
      userMessage ??
      'فشل في الوصول إلى بيانات التطبيق. يرجى المحاولة مرة أخرى.';
}

/// استثناء عند انتهاء مهلة عملية قاعدة البيانات
class DatabaseTimeoutException extends DatabaseException {
  final Duration timeout;

  DatabaseTimeoutException(
    super.message, {
    required this.timeout,
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() =>
      userMessage ??
      'العملية استغرقت وقتاً طويلاً (${timeout.inSeconds} ثانية). يرجى المحاولة مرة أخرى.';
}

/// استثناء عند وجود قيد على قاعدة البيانات
class DatabaseConstraintException extends DatabaseException {
  final String? constraintType; // UNIQUE, FOREIGN_KEY, NOT_NULL, etc.

  DatabaseConstraintException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
    this.constraintType,
    super.tableName,
  });

  @override
  String getUserMessage() {
    if (userMessage != null) return userMessage!;

    switch (constraintType) {
      case 'UNIQUE':
        return 'القيمة المدخلة موجودة مسبقاً. يرجى استخدام قيمة أخرى.';
      case 'FOREIGN_KEY':
        return 'لا يمكن تنفيذ العملية لوجود بيانات مرتبطة.';
      case 'NOT_NULL':
        return 'جميع الحقول المطلوبة يجب أن تكون معبأة.';
      default:
        return 'فشلت العملية بسبب قيود قاعدة البيانات.';
    }
  }
}

// ==================== المصادقة والصلاحيات ====================

/// استثناء عند فشل المصادقة
class AuthenticationException extends AppException {
  final String? username;

  AuthenticationException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
    this.username,
  });

  @override
  String getUserMessage() =>
      userMessage ?? 'فشل تسجيل الدخول. تحقق من اسم المستخدم وكلمة المرور.';
}

/// استثناء عند عدم وجود صلاحية
class UnauthorizedException extends AppException {
  final String? requiredPermission;
  final String? userId;

  UnauthorizedException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
    this.requiredPermission,
    this.userId,
  });

  @override
  String getUserMessage() =>
      userMessage ?? 'ليس لديك صلاحية لتنفيذ هذه العملية. تواصل مع المسؤول.';
}

/// استثناء عند انتهاء الجلسة
class SessionExpiredException extends AppException {
  SessionExpiredException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() =>
      userMessage ?? 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';
}

/// استثناء عند تجاوز عدد المحاولات
class RateLimitException extends AppException {
  final Duration remainingTime;
  final int attemptCount;

  RateLimitException(
    super.message, {
    required this.remainingTime,
    this.attemptCount = 0,
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    if (userMessage != null) return userMessage!;

    final minutes = remainingTime.inMinutes;
    final hours = remainingTime.inHours;

    if (hours > 0) {
      return 'تم تجاوز عدد المحاولات. حاول مرة أخرى بعد $hours ساعة.';
    } else if (minutes > 0) {
      return 'تم تجاوز عدد المحاولات. حاول مرة أخرى بعد $minutes دقيقة.';
    } else {
      return 'تم تجاوز عدد المحاولات. حاول مرة أخرى لاحقاً.';
    }
  }
}

// ==================== التحقق من صحة البيانات ====================

/// استثناء عند فشل التحقق من البيانات
class ValidationException extends AppException {
  final String? fieldName;
  final dynamic invalidValue;
  final Map<String, String>? errors; // للأخطاء المتعددة

  ValidationException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
    this.fieldName,
    this.invalidValue,
    this.errors,
  });

  @override
  String getUserMessage() {
    if (userMessage != null) return userMessage!;
    if (errors != null && errors!.isNotEmpty) {
      return errors!.values.first;
    }
    if (fieldName != null) {
      return 'قيمة "$fieldName" غير صحيحة.';
    }
    return 'البيانات المدخلة غير صحيحة. يرجى التحقق من المدخلات.';
  }

  /// الحصول على جميع رسائل الأخطاء
  List<String> getAllErrors() {
    if (errors != null) return errors!.values.toList();
    return [getUserMessage()];
  }
}

// ==================== الأعمال التجارية ====================

/// استثناء عند فشل قواعد الأعمال
/// DomainException is an alias for BusinessRuleException
class BusinessRuleException extends AppException {
  BusinessRuleException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
    this.ruleName,
  });

  final String? ruleName;

  @override
  String getUserMessage() => userMessage ?? message;
}

/// DomainException - alias for BusinessRuleException for cleaner domain layer code
typedef DomainException = BusinessRuleException;

/// استثناء عند عدم كفاية المخزون
class InsufficientStockException extends BusinessRuleException {
  final String productId;
  final String productName;
  final double available;
  final double requested;

  InsufficientStockException({
    required this.productId,
    required this.productName,
    required this.available,
    required this.requested,
    super.userMessage,
    super.code,
  }) : super(
          'مخزون غير كافٍ للمنتج: $productName (المتوفر: $available، المطلوب: $requested)',
          ruleName: 'INSUFFICIENT_STOCK',
        );

  @override
  String getUserMessage() =>
      userMessage ??
      'مخزون "$productName" غير كافٍ. المتوفر: ${available.toStringAsFixed(1)}';
}

/// استثناء عند وجود دين متأخر
class DebtException extends BusinessRuleException {
  final String customerId;
  final String customerName;
  final double debtAmount;

  DebtException({
    required this.customerId,
    required this.customerName,
    required this.debtAmount,
    super.userMessage,
    super.code,
  }) : super(
          'العميل "$customerName" لديه دين متأخر: $debtAmount',
          ruleName: 'OUTSTANDING_DEBT',
        );

  @override
  String getUserMessage() =>
      userMessage ??
      'العميل "$customerName" لديه دين متأخر: ${debtAmount.toStringAsFixed(0)} د.ع';
}

/// استثناء عند انتهاء صلاحية منتج
class ProductExpiredException extends BusinessRuleException {
  final String productId;
  final String productName;
  final DateTime expiryDate;

  ProductExpiredException({
    required this.productId,
    required this.productName,
    required this.expiryDate,
    super.userMessage,
    super.code,
  }) : super(
          'المنتج "$productName" منتهي الصلاحية (${expiryDate.toString().split(' ')[0]})',
          ruleName: 'PRODUCT_EXPIRED',
        );

  @override
  String getUserMessage() =>
      userMessage ??
      'تحذير: المنتج "$productName" منتهي الصلاحية منذ ${expiryDate.toString().split(' ')[0]}';
}

// ==================== الشبكة والملفات ====================

/// استثناء عند فشل عملية على الشبكة
class NetworkException extends AppException {
  final String? url;
  final int? statusCode;

  NetworkException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
    this.url,
    this.statusCode,
  });

  @override
  String getUserMessage() =>
      userMessage ?? 'فشل الاتصال بالشبكة. تحقق من اتصال الإنترنت.';
}

/// استثناء عند فشل عملية على ملف
class FileException extends AppException {
  final String? filePath;
  final String? operation; // read, write, delete, etc.

  FileException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
    this.filePath,
    this.operation,
  });

  @override
  String getUserMessage() {
    if (userMessage != null) return userMessage!;

    switch (operation) {
      case 'read':
        return 'فشل قراءة الملف. تأكد من وجود الملف.';
      case 'write':
        return 'فشل الكتابة على الملف. تحقق من الصلاحيات.';
      case 'delete':
        return 'فشل حذف الملف. تحقق من الصلاحيات.';
      default:
        return 'حدث خطأ في التعامل مع الملف.';
    }
  }
}

// ==================== عامة ====================

/// استثناء عند فشل عملية غير متوقعة
class UnexpectedException extends AppException {
  UnexpectedException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() =>
      userMessage ??
      'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى أو التواصل مع الدعم الفني.';
}

/// استثناء عند انتهاء مهلة عملية
class TimeoutException extends AppException {
  final Duration timeout;

  TimeoutException(
    super.message, {
    required this.timeout,
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() =>
      userMessage ??
      'العملية استغرقت وقتاً طويلاً (${timeout.inSeconds} ثانية). يرجى المحاولة مرة أخرى.';
}

/// استثناء عند عدم العثور على عنصر
class NotFoundException extends AppException {
  final String? entityType;
  final String? entityId;

  NotFoundException(
    super.message, {
    super.userMessage,
    super.code,
    super.originalError,
    super.stackTrace,
    this.entityType,
    this.entityId,
  });

  @override
  String getUserMessage() {
    if (userMessage != null) return userMessage!;
    if (entityType != null) {
      return 'لم يتم العثور على $entityType المطلوب.';
    }
    return 'لم يتم العثور على العنصر المطلوب.';
  }
}

// ==================== Helper Functions ====================

/// دالة مساعدة لتحويل الأخطاء إلى استثناءات مخصصة
AppException convertToAppException(dynamic error, {StackTrace? stackTrace}) {
  if (error is AppException) {
    return error;
  }

  // Database errors
  if (error.toString().contains('database') ||
      error.toString().contains('SQLite')) {
    return DatabaseException(
      error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  // Timeout errors
  if (error.toString().contains('timeout') ||
      error.toString().contains('TimeoutException')) {
    return TimeoutException(
      error.toString(),
      timeout: const Duration(seconds: 30),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  // Network errors
  if (error.toString().contains('network') ||
      error.toString().contains('connection')) {
    return NetworkException(
      error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  // Default to unexpected exception
  return UnexpectedException(
    error.toString(),
    originalError: error,
    stackTrace: stackTrace,
  );
}

/// دالة مساعدة لمعالجة الاستثناءات وإرجاع Map
Map<String, dynamic> handleException(dynamic error, {StackTrace? stackTrace}) {
  final appException = convertToAppException(error, stackTrace: stackTrace);

  return {
    'success': false,
    'error': appException.getUserMessage(),
    'errorCode': appException.code,
    'errorType': appException.runtimeType.toString(),
    'timestamp': appException.timestamp.toIso8601String(),
  };
}
