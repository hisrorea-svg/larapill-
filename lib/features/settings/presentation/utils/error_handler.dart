import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/theme/app_colors.dart';

/// Helper class لمعالجة الأخطاء في Settings Feature
///
/// يوفر دوال مساعدة لمعالجة الأخطاء وعرضها للمستخدم
class SettingsErrorHandler {
  /// معالجة خطأ وعرض رسالة للمستخدم
  ///
  /// [context] BuildContext للوصول إلى ScaffoldMessenger
  /// [error] الخطأ المراد معالجته
  /// [stackTrace] Stack trace للخطأ (اختياري)
  /// [onRetry] دالة إعادة المحاولة (اختياري)
  static void handleError(
    BuildContext context,
    dynamic error, {
    StackTrace? stackTrace,
    VoidCallback? onRetry,
  }) {
    final appException = convertToAppException(error, stackTrace: stackTrace);
    final message = appException.getUserMessage();
    final color = _getErrorColor(appException);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(appException),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.tajawal(color: Colors.white),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
                child: Text(
                  'إعادة المحاولة',
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// معالجة خطأ وإرجاع رسالة نصية
  ///
  /// [error] الخطأ المراد معالجته
  /// [stackTrace] Stack trace للخطأ (اختياري)
  /// [Returns] رسالة الخطأ المناسبة للمستخدم
  static String getErrorMessage(dynamic error, {StackTrace? stackTrace}) {
    final appException = convertToAppException(error, stackTrace: stackTrace);
    return appException.getUserMessage();
  }

  /// الحصول على لون الخطأ حسب نوعه
  static Color _getErrorColor(AppException exception) {
    if (exception is ValidationException) {
      return AppColors.warning;
    } else if (exception is DatabaseException) {
      return AppColors.error;
    } else if (exception is NotFoundException) {
      return AppColors.info;
    } else if (exception is BusinessRuleException) {
      return AppColors.warning;
    } else if (exception is UnauthorizedException) {
      return Colors.orange;
    } else {
      return AppColors.error;
    }
  }

  /// الحصول على أيقونة الخطأ حسب نوعه
  static IconData _getErrorIcon(AppException exception) {
    if (exception is ValidationException) {
      return Icons.warning_amber_rounded;
    } else if (exception is DatabaseException) {
      return Icons.storage;
    } else if (exception is NotFoundException) {
      return Icons.search_off;
    } else if (exception is BusinessRuleException) {
      return Icons.rule;
    } else if (exception is UnauthorizedException) {
      return Icons.lock;
    } else {
      return Icons.error_outline;
    }
  }

  /// معالجة خطأ في async operation مع loading state
  ///
  /// [context] BuildContext
  /// [operation] العملية المراد تنفيذها
  /// [onSuccess] دالة يتم استدعاؤها عند النجاح
  /// [onError] دالة يتم استدعاؤها عند الخطأ (اختياري)
  /// [showLoading] عرض loading indicator (افتراضي: true)
  static Future<T?> handleAsyncOperation<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    required VoidCallback onSuccess,
    void Function(AppException)? onError,
    bool showLoading = true,
  }) async {
    if (showLoading && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      final result = await operation();

      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        onSuccess();
      }

      return result;
    } on DatabaseException catch (e, stackTrace) {
      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        handleError(context, e, stackTrace: stackTrace);
      }
      onError?.call(e);
      return null;
    } on ValidationException catch (e, stackTrace) {
      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        handleError(context, e, stackTrace: stackTrace);
      }
      onError?.call(e);
      return null;
    } on BusinessRuleException catch (e, stackTrace) {
      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        handleError(context, e, stackTrace: stackTrace);
      }
      onError?.call(e);
      return null;
    } on NotFoundException catch (e, stackTrace) {
      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        handleError(context, e, stackTrace: stackTrace);
      }
      onError?.call(e);
      return null;
    } on AppException catch (e, stackTrace) {
      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        handleError(context, e, stackTrace: stackTrace);
      }
      onError?.call(e);
      return null;
    } catch (e, stackTrace) {
      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }
      final appException = convertToAppException(e, stackTrace: stackTrace);
      if (context.mounted) {
        handleError(context, appException, stackTrace: stackTrace);
      }
      onError?.call(appException);
      return null;
    }
  }
}
