import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// 🔒 نظام حماية متقدم من Brute Force Attacks
/// يتميز بـ:
/// - حد أقصى للمحاولات مع زيادة وقت المنع تدريجياً
/// - تسجيل المحاولات المشبوهة
/// - إحصائيات مفصلة للمراجعة الأمنية
class AdvancedRateLimiter {
  static const String _storageKey = 'login_attempts';
  static const int maxAttempts = 5;
  static const Duration baseLockoutDuration = Duration(minutes: 1);
  static const Duration extendedLockoutDuration = Duration(minutes: 15);
  static const Duration maxLockoutDuration = Duration(hours: 6);

  /// فحص إمكانية محاولة تسجيل الدخول
  static Future<Map<String, dynamic>> checkAttempt(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsData = prefs.getString(_storageKey);

    if (attemptsData == null) {
      return {'canAttempt': true, 'remaining': null, 'level': 0};
    }

    final attempts = Map<String, dynamic>.from(jsonDecode(attemptsData));
    final userAttempts = attempts[identifier];

    if (userAttempts == null) {
      return {'canAttempt': true, 'remaining': null, 'level': 0};
    }

    final attemptsList = List<String>.from(userAttempts['attempts'] ?? []);
    final consecutiveFailures = userAttempts['consecutiveFailures'] ?? 0;
    final now = DateTime.now();

    // تنظيف المحاولات القديمة حسب مستوى المنع
    final cleanupDuration = _getLockoutDuration(consecutiveFailures);
    attemptsList.removeWhere((attemptStr) {
      final attemptTime = DateTime.parse(attemptStr);
      return now.difference(attemptTime) > cleanupDuration;
    });

    // حفظ البيانات المنظفة
    if (attemptsList.isEmpty) {
      attempts.remove(identifier);
    } else {
      attempts[identifier] = {
        'attempts': attemptsList,
        'consecutiveFailures': consecutiveFailures,
        'firstAttempt': userAttempts['firstAttempt'],
        'lastAttempt': userAttempts['lastAttempt'],
      };
    }

    await prefs.setString(_storageKey, jsonEncode(attempts));

    // فحص الحد الأقصى
    if (attemptsList.length >= maxAttempts) {
      final oldestAttempt = DateTime.parse(attemptsList.first);
      final lockoutDuration = _getLockoutDuration(consecutiveFailures);
      final lockoutEnd = oldestAttempt.add(lockoutDuration);
      final remaining = lockoutEnd.difference(now);

      if (remaining.isNegative) {
        // انتهت فترة المنع
        attempts.remove(identifier);
        await prefs.setString(_storageKey, jsonEncode(attempts));
        return {'canAttempt': true, 'remaining': null, 'level': 0};
      } else {
        return {
          'canAttempt': false,
          'remaining': remaining,
          'level': consecutiveFailures,
          'isExtended': consecutiveFailures > 0,
          'maxReached': consecutiveFailures >= 3,
        };
      }
    }

    return {
      'canAttempt': true,
      'remaining': null,
      'level': consecutiveFailures,
      'attemptsLeft': maxAttempts - attemptsList.length,
    };
  }

  /// تسجيل محاولة فاشلة
  static Future<Map<String, dynamic>> recordFailedAttempt(
      String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsData = prefs.getString(_storageKey);
    final attempts = attemptsData != null
        ? Map<String, dynamic>.from(jsonDecode(attemptsData))
        : <String, dynamic>{};

    final now = DateTime.now();
    final userAttempts = attempts[identifier] ??
        {
          'attempts': <String>[],
          'consecutiveFailures': 0,
          'firstAttempt': now.toIso8601String(),
        };

    final attemptsList = List<String>.from(userAttempts['attempts']);
    attemptsList.add(now.toIso8601String());

    // إذا وصل للحد الأقصى، زيادة عداد الفشل المتتالي
    if (attemptsList.length >= maxAttempts) {
      userAttempts['consecutiveFailures'] =
          (userAttempts['consecutiveFailures'] ?? 0) + 1;

      // تسجيل محاولة مشبوهة
      await _logSuspiciousActivity(identifier, {
        'type': 'BRUTE_FORCE_ATTEMPT',
        'attempts_count': attemptsList.length,
        'consecutive_failures': userAttempts['consecutiveFailures'],
        'lockout_duration':
            _getLockoutDuration(userAttempts['consecutiveFailures']).toString(),
      });
    }

    attempts[identifier] = {
      'attempts': attemptsList,
      'consecutiveFailures': userAttempts['consecutiveFailures'],
      'firstAttempt': userAttempts['firstAttempt'],
      'lastAttempt': now.toIso8601String(),
    };

    await prefs.setString(_storageKey, jsonEncode(attempts));

    return {
      'level': userAttempts['consecutiveFailures'],
      'attemptsCount': attemptsList.length,
      'lockoutDuration':
          _getLockoutDuration(userAttempts['consecutiveFailures']),
    };
  }

  /// مسح المحاولات بعد تسجيل دخول ناجح
  static Future<void> clearAttempts(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsData = prefs.getString(_storageKey);

    if (attemptsData != null) {
      final attempts = Map<String, dynamic>.from(jsonDecode(attemptsData));

      // تسجيل النجاح إذا كان هناك محاولات سابقة
      if (attempts.containsKey(identifier)) {
        await _logSuspiciousActivity(identifier, {
          'type': 'SUCCESSFUL_LOGIN_AFTER_FAILED_ATTEMPTS',
          'previous_attempts': attempts[identifier]['attempts'].length,
          'cleared_at': DateTime.now().toIso8601String(),
        });
      }

      attempts.remove(identifier);
      await prefs.setString(_storageKey, jsonEncode(attempts));
    }
  }

  /// الحصول على مدة المنع حسب مستوى الفشل
  static Duration _getLockoutDuration(int consecutiveFailures) {
    switch (consecutiveFailures) {
      case 0:
        return baseLockoutDuration; // 1 دقيقة
      case 1:
        return const Duration(minutes: 5); // 5 دقائق
      case 2:
        return extendedLockoutDuration; // 15 ساعة
      case 3:
        return const Duration(minutes: 30); // 30 دقيقة
      default:
        return maxLockoutDuration; // 6 ساعات
    }
  }

  /// تنسيق وقت المنع للعرض
  static String formatRemainingTime(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} يوم و ${duration.inHours.remainder(24)} ساعة';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ساعة و ${duration.inMinutes.remainder(60)} دقيقة';
    } else {
      return '${duration.inMinutes} دقيقة';
    }
  }

  /// الحصول على رسالة تحذيرية حسب المستوى
  static String getWarningMessage(int level, Duration remaining) {
    switch (level) {
      case 0:
        return '⚠️ تم تجاوز عدد المحاولات. حاول بعد ${formatRemainingTime(remaining)}';
      case 1:
        return '🚫 محاولات متكررة مشبوهة. المنع لمدة ${formatRemainingTime(remaining)}';
      case 2:
        return '🔒 نشاط مشبوه مكثف. المنع المؤقت لمدة ${formatRemainingTime(remaining)}';
      default:
        return '🛡️ تم منعك نهائياً بسبب المحاولات المتكررة. المنع لمدة ${formatRemainingTime(remaining)}';
    }
  }

  /// الحصول على إحصائيات مفصلة للمراجعة الأمنية
  static Future<Map<String, dynamic>> getSecurityStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsData = prefs.getString(_storageKey);
    final securityLogs = prefs.getString('security_logs');

    if (attemptsData == null) {
      return {'totalBlocked': 0, 'details': {}, 'logs': []};
    }

    final attempts = Map<String, dynamic>.from(jsonDecode(attemptsData));
    final logs = securityLogs != null ? jsonDecode(securityLogs) : [];

    // إحصائيات مفصلة
    final statistics = {
      'totalBlocked': attempts.length,
      'details': {},
      'logs': logs,
      'summary': {
        'level_0': 0, // منع أساسي
        'level_1': 0, // منع متوسط
        'level_2': 0, // منع مكثف
        'level_3_plus': 0, // منع نهائي
      },
    };

    attempts.forEach((identifier, data) {
      final level = data['consecutiveFailures'] ?? 0;
      statistics['details'][identifier] = {
        'attempts_count': data['attempts'].length,
        'consecutive_failures': level,
        'first_attempt': data['firstAttempt'],
        'last_attempt': data['lastAttempt'],
        'current_lockout': _getLockoutDuration(level).toString(),
        'risk_level': _getRiskLevel(level),
      };

      // تحديث الملخص
      if (level == 0) {
        statistics['summary']['level_0']++;
      } else if (level == 1) {
        statistics['summary']['level_1']++;
      } else if (level == 2) {
        statistics['summary']['level_2']++;
      } else {
        statistics['summary']['level_3_plus']++;
      }
    });

    return statistics;
  }

  /// تقييم مستوى الخطر
  static String _getRiskLevel(int consecutiveFailures) {
    switch (consecutiveFailures) {
      case 0:
        return 'منخفض';
      case 1:
        return 'متوسط';
      case 2:
        return 'عالي';
      default:
        return 'خطر شديد';
    }
  }

  /// تسجيل النشاط المشبوه
  static Future<void> _logSuspiciousActivity(
      String identifier, Map<String, dynamic> details) async {
    final prefs = await SharedPreferences.getInstance();
    final securityLogs = prefs.getString('security_logs');
    final logs =
        securityLogs != null ? List.from(jsonDecode(securityLogs)) : [];

    // إضافة سجل جديد
    logs.add({
      'timestamp': DateTime.now().toIso8601String(),
      'identifier': identifier,
      'ip_address': 'LOCAL', // يمكن إضافة IP الحقيقي لاحقاً
      'details': details,
    });

    // الاحتفاظ بآخر 100 سجل فقط
    if (logs.length > 100) {
      logs.removeRange(0, logs.length - 100);
    }

    await prefs.setString('security_logs', jsonEncode(logs));

    // طباعة في وضع التطوير للمراقبة
    developer.log('🔒 SECURITY LOG: ${details['type']} for $identifier',
        name: 'Security');
    developer.log('📊 Details: $details', name: 'Security');
  }

  /// مسح جميع السجلات (للصيانة)
  static Future<void> clearAllLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove('security_logs');
  }

  /// تصدير السجلات الأمنية
  static Future<String> exportSecurityLogs() async {
    final statistics = await getSecurityStatistics();
    return '''
🔒 تقرير الأمان - LaRaPill
تاريخ التقرير: ${DateTime.now()}

📊 الملخص:
- إجمالي المستخدمين المحظورين: ${statistics['totalBlocked']}
- منع أساسي (المستوى 0): ${statistics['summary']['level_0']}
- منع متوسط (المستوى 1): ${statistics['summary']['level_1']}
- منع مكثف (المستوى 2): ${statistics['summary']['level_2']}
- منع نهائي (المستوى 3+): ${statistics['summary']['level_3_plus']}

📋 التفاصيل:
${jsonEncode(statistics['details'])}

📝 سجل الأحداث:
${jsonEncode(statistics['logs'])}
''';
  }
}
