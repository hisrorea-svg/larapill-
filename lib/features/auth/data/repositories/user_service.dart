import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:io';

import '../../../../core/storage/hive_storage.dart';
import 'dart:developer' as developer;
import '../../../../core/database/drift/daos/users_drift_dao.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/services/password_hasher.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/utils/input_sanitizer.dart';
import '../../domain/entities/user.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

// ================================
// ✅ UserService - مع التشفير الآمن (Drift)
// ================================
class UserService {
  static const String _currentUserKey = 'current_user_id';
  static const String _sessionTokenKey = 'session_token';

  // Static DAO reference for static methods (set by DI during app initialization)
  static UsersDriftDao? _dao;

  /// Initialize with DAO from DI
  static void init(UsersDriftDao dao) {
    _dao = dao;
  }

  // إنشاء مستخدم جديد مع معالجة أخطاء محسنة
  static Future<Map<String, dynamic>> createUser({
    required String username,
    required String fullName,
    required String password,
    String? email,
    String? phone,
    required UserRole role,
    List<String>? permissions,
    required String createdBy,
  }) async {
    if (_dao == null) {
      throw Exception('UserService not initialized. Call init() first.');
    }

    try {
      // تنظيف المدخلات
      final cleanUsername = InputSanitizer.sanitizeUsername(username);
      final cleanFullName = InputSanitizer.sanitizeFullName(fullName);
      final cleanEmail =
          email != null ? InputSanitizer.sanitizeEmail(email) : null;
      final cleanPhone =
          phone != null ? InputSanitizer.sanitizePhoneNumber(phone) : null;

      // التحقق من صحة المدخلات
      if (cleanUsername.isEmpty || cleanUsername.length < 3) {
        throw ValidationException(
          'اسم المستخدم غير صحيح',
          fieldName: 'username',
          invalidValue: username,
          userMessage: 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل',
        );
      }

      if (cleanFullName.isEmpty || cleanFullName.length < 2) {
        throw ValidationException(
          'الاسم الكامل غير صحيح',
          fieldName: 'fullName',
          invalidValue: fullName,
          userMessage: 'الاسم الكامل يجب أن يكون حرفين على الأقل',
        );
      }

      // التحقق من وجود اسم المستخدم
      final existingUser = await _dao!.findByUsername(cleanUsername);

      if (existingUser != null) {
        throw DatabaseConstraintException(
          'اسم المستخدم موجود مسبقاً',
          constraintType: 'UNIQUE',
          tableName: 'users',
          userMessage:
              'اسم المستخدم "$cleanUsername" موجود مسبقاً. اختر اسم مستخدم آخر.',
        );
      }

      // إنشاء المستخدم
      final userId = _generateId();
      final now = DateTime.now();
      final userPermissions = permissions ?? getDefaultPermissions(role);

      await _dao!.createUser(UsersCompanion.insert(
        id: userId,
        username: cleanUsername,
        fullName: cleanFullName,
        email: Value(cleanEmail),
        phone: Value(cleanPhone),
        passwordHash: _hashPassword(password),
        role: Value(role.name),
        permissions: Value(userPermissions.join(',')),
        isActive: const Value(true),
        forcePasswordChange: const Value(false),
        createdAt: now,
        updatedAt: now,
        createdBy: Value(createdBy),
      ));

      final user = User(
        id: userId,
        username: cleanUsername,
        fullName: cleanFullName,
        email: cleanEmail,
        phone: cleanPhone,
        passwordHash: _hashPassword(password),
        role: role,
        permissions: userPermissions,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        createdBy: createdBy,
      );

      // تسجيل النشاط القديم
      await _logActivity(
        createdBy,
        'create_user',
        'إنشاء مستخدم جديد: $cleanUsername ($cleanFullName)',
      );

      // 📝 تسجيل في Audit Log
      final currentUser = await getUserById(createdBy);
      await AuditLogger().logUserCreate(
        createdBy,
        currentUser?.fullName ?? 'مستخدم غير معروف',
        userId,
        cleanUsername,
        role.displayName,
      );

      developer.log('✅ تم إنشاء المستخدم: $cleanUsername', name: 'UserService');

      return {
        'success': true,
        'user': user,
      };
    } on AppException catch (e) {
      developer.log('❌ خطأ في إنشاء المستخدم: ${e.message}',
          name: 'UserService', error: e, stackTrace: e.stackTrace);
      return {
        'success': false,
        'error': e.getUserMessage(),
        'errorCode': e.code,
      };
    } catch (e, stackTrace) {
      developer.log('❌ خطأ غير متوقع في إنشاء المستخدم: $e',
          name: 'UserService', error: e, stackTrace: stackTrace);
      throw UnexpectedException(
        'حدث خطأ غير متوقع أثناء إنشاء المستخدم',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // تسجيل الدخول مع دعم الترقية التلقائية
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    if (_dao == null) {
      return {'success': false, 'error': 'UserService not initialized'};
    }

    try {
      final userEntry = await _dao!.findByUsername(username);

      if (userEntry == null || !userEntry.isActive) {
        return {
          'success': false,
          'error': 'اسم المستخدم غير موجود أو غير مفعل',
        };
      }

      final user = _mapEntryToUser(userEntry);

      // فحص نوع الـ hash والتحقق
      bool passwordValid = false;

      if (PasswordHasher.isLegacyHash(user.passwordHash)) {
        // Hash قديم - التحقق بالطريقة القديمة والترقية
        final upgradedHash = PasswordHasher.upgradeLegacyHash(
          user.passwordHash,
          password,
        );

        if (upgradedHash != null) {
          passwordValid = true;

          // ترقية الـ hash فوراً
          await _dao!.updatePassword(user.id, upgradedHash);

          developer.log('✅ تم ترقية hash كلمة المرور للمستخدم: $username',
              name: 'UserService');
        }
      } else {
        // Hash جديد - التحقق العادي
        passwordValid = PasswordHasher.verify(password, user.passwordHash);
      }

      if (!passwordValid) {
        return {
          'success': false,
          'error': 'كلمة المرور خاطئة',
        };
      }

      // إنشاء جلسة جديدة
      final sessionToken = _generateSessionToken();
      final deviceInfo = await _getDeviceInfo();
      final ipAddress = await _getIpAddress();
      final now = DateTime.now();

      await _dao!.createSession(UserSessionsCompanion.insert(
        id: _generateId(),
        userId: user.id,
        sessionToken: sessionToken,
        deviceInfo: Value(deviceInfo),
        ipAddress: Value(ipAddress),
        loginTime: now,
        lastActivity: now,
        isActive: const Value(true),
      ));

      // تحديث آخر تسجيل دخول
      await _dao!.updateLastLogin(user.id);

      // حفظ الجلسة
      await HiveStorage.setSecure(_currentUserKey, user.id);
      await HiveStorage.setSecure(_sessionTokenKey, sessionToken);

      // تسجيل النشاط
      await _logActivity(user.id, 'login', 'تسجيل دخول ناجح');

      developer.log('✅ تسجيل دخول ناجح: $username', name: 'UserService');

      return {
        'success': true,
        'user': user,
        'sessionToken': sessionToken,
      };
    } catch (e) {
      developer.log('❌ خطأ في تسجيل الدخول: $e', name: 'UserService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // تسجيل الخروج
  static Future<Map<String, dynamic>> logout() async {
    try {
      final userId = HiveStorage.getSecure<String>(_currentUserKey);
      final sessionToken = HiveStorage.getSecure<String>(_sessionTokenKey);

      if (userId != null && _dao != null) {
        // إنهاء الجلسة
        if (sessionToken != null) {
          await _dao!.invalidateSession(sessionToken);
        }

        // تسجيل النشاط
        await _logActivity(userId, 'logout', 'تسجيل خروج');
      }

      // مسح البيانات المحلية
      await HiveStorage.removeSecure(_currentUserKey);
      await HiveStorage.removeSecure(_sessionTokenKey);

      developer.log('✅ تم تسجيل الخروج', name: 'UserService');

      return {'success': true};
    } catch (e) {
      developer.log('❌ خطأ في تسجيل الخروج: $e', name: 'UserService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // الحصول على المستخدم الحالي
  static Future<User?> getCurrentUser() async {
    if (_dao == null) return null;

    try {
      final userId = HiveStorage.getSecure<String>(_currentUserKey);
      final sessionToken = HiveStorage.getSecure<String>(_sessionTokenKey);

      if (userId == null || sessionToken == null) {
        return null;
      }

      // التحقق من صلاحية الجلسة
      final session = await _dao!.getSession(sessionToken);

      if (session == null || !session.isActive) {
        await HiveStorage.removeSecure(_currentUserKey);
        await HiveStorage.removeSecure(_sessionTokenKey);
        return null;
      }

      // تحديث آخر نشاط
      await _dao!.updateSessionActivity(sessionToken);

      // جلب بيانات المستخدم
      final userEntry = await _dao!.findById(userId);

      if (userEntry == null || !userEntry.isActive) {
        return null;
      }

      return _mapEntryToUser(userEntry);
    } catch (e) {
      developer.log('❌ خطأ في جلب المستخدم الحالي: $e', name: 'UserService');
      return null;
    }
  }

  // الحصول على مستخدم بواسطة الـ ID
  static Future<User?> getUserById(String userId) async {
    if (_dao == null) return null;

    try {
      final userEntry = await _dao!.findById(userId);
      if (userEntry == null) return null;
      return _mapEntryToUser(userEntry);
    } catch (e) {
      developer.log('❌ خطأ في جلب المستخدم: $e', name: 'UserService');
      return null;
    }
  }

  // جلب جميع المستخدمين
  static Future<List<User>> getAllUsers({bool activeOnly = false}) async {
    if (_dao == null) return [];

    try {
      final entries = await _dao!.getAllUsers(activeOnly: activeOnly);
      return entries.map((entry) => _mapEntryToUser(entry)).toList();
    } catch (e) {
      developer.log('❌ خطأ في جلب المستخدمين: $e', name: 'UserService');
      return [];
    }
  }

  // تحديث بيانات المستخدم
  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    List<String>? permissions,
    bool? isActive,
  }) async {
    if (_dao == null) {
      return {'success': false, 'error': 'UserService not initialized'};
    }

    try {
      await _dao!.updateUser(
        userId,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role?.name,
        permissions: permissions,
        isActive: isActive,
      );

      developer.log('✅ تم تحديث المستخدم: $userId', name: 'UserService');

      return {'success': true};
    } catch (e) {
      developer.log('❌ خطأ في تحديث المستخدم: $e', name: 'UserService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // تغيير كلمة المرور
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_dao == null) {
      return {'success': false, 'error': 'UserService not initialized'};
    }

    try {
      // جلب المستخدم
      final userEntry = await _dao!.findById(userId);

      if (userEntry == null) {
        return {
          'success': false,
          'error': 'المستخدم غير موجود',
        };
      }

      final user = _mapEntryToUser(userEntry);

      // التحقق من كلمة المرور القديمة
      bool oldPasswordValid = false;

      if (PasswordHasher.isLegacyHash(user.passwordHash)) {
        final upgradedHash = PasswordHasher.upgradeLegacyHash(
          user.passwordHash,
          oldPassword,
        );
        oldPasswordValid = upgradedHash != null;
      } else {
        oldPasswordValid =
            PasswordHasher.verify(oldPassword, user.passwordHash);
      }

      if (!oldPasswordValid) {
        return {
          'success': false,
          'error': 'كلمة المرور القديمة غير صحيحة',
        };
      }

      // تحديث كلمة المرور وإزالة علامة force_password_change
      final newHash = _hashPassword(newPassword);
      await _dao!.updatePassword(userId, newHash, forceChange: false);

      // تسجيل النشاط
      await _logActivity(userId, 'change_password', 'تغيير كلمة المرور');

      developer.log('✅ تم تغيير كلمة المرور للمستخدم: $userId',
          name: 'UserService');

      return {'success': true};
    } catch (e) {
      developer.log('❌ خطأ في تغيير كلمة المرور: $e', name: 'UserService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // إعادة تعيين كلمة المرور (من قبل المدير)
  static Future<Map<String, dynamic>> resetPassword({
    required String userId,
    required String newPassword,
    required String adminId,
  }) async {
    if (_dao == null) {
      return {'success': false, 'error': 'UserService not initialized'};
    }

    try {
      final newHash = _hashPassword(newPassword);
      await _dao!.updatePassword(userId, newHash);

      // تسجيل النشاط
      await _logActivity(
        adminId,
        'reset_password',
        'إعادة تعيين كلمة مرور المستخدم: $userId',
      );

      developer.log('✅ تم إعادة تعيين كلمة المرور للمستخدم: $userId',
          name: 'UserService');

      return {'success': true};
    } catch (e) {
      developer.log('❌ خطأ في إعادة تعيين كلمة المرور: $e',
          name: 'UserService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // حذف مستخدم (إيقاف تفعيل)
  static Future<Map<String, dynamic>> deleteUser({
    required String userId,
    required String deletedBy,
  }) async {
    if (_dao == null) {
      return {'success': false, 'error': 'UserService not initialized'};
    }

    try {
      // إيقاف التفعيل بدلاً من الحذف الفعلي
      await _dao!.updateUser(userId, isActive: false);

      // إنهاء جميع جلسات المستخدم
      await _dao!.invalidateAllUserSessions(userId);

      // تسجيل النشاط
      await _logActivity(
        deletedBy,
        'delete_user',
        'حذف/إيقاف تفعيل المستخدم: $userId',
      );

      developer.log('✅ تم إيقاف تفعيل المستخدم: $userId', name: 'UserService');

      return {'success': true};
    } catch (e) {
      developer.log('❌ خطأ في حذف المستخدم: $e', name: 'UserService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // جلب سجل نشاطات مستخدم
  static Future<List<Map<String, dynamic>>> getUserActivities({
    required String userId,
    int limit = 50,
  }) async {
    if (_dao == null) return [];

    try {
      final activities = await _dao!.getUserActivities(userId, limit: limit);
      return activities
          .map((entry) => {
                'id': entry.id,
                'user_id': entry.userId,
                'action': entry.action,
                'details': entry.details,
                'ip_address': entry.ipAddress,
                'created_at': entry.createdAt.toIso8601String(),
              })
          .toList();
    } catch (e) {
      developer.log('❌ خطأ في جلب نشاطات المستخدم: $e', name: 'UserService');
      return [];
    }
  }

  // جلب الجلسات النشطة
  static Future<List<Map<String, dynamic>>> getActiveSessions(
      String userId) async {
    if (_dao == null) return [];

    try {
      final sessions = await _dao!.getUserSessions(userId);
      return sessions
          .map((entry) => {
                'id': entry.id,
                'user_id': entry.userId,
                'session_token': entry.sessionToken,
                'device_info': entry.deviceInfo,
                'ip_address': entry.ipAddress,
                'login_time': entry.loginTime.toIso8601String(),
                'last_activity': entry.lastActivity.toIso8601String(),
                'is_active': entry.isActive ? 1 : 0,
              })
          .toList();
    } catch (e) {
      developer.log('❌ خطأ في جلب الجلسات النشطة: $e', name: 'UserService');
      return [];
    }
  }

  // إنهاء جلسة محددة
  static Future<bool> terminateSession(String sessionToken) async {
    if (_dao == null) return false;

    try {
      await _dao!.invalidateSession(sessionToken);
      return true;
    } catch (e) {
      developer.log('❌ خطأ في إنهاء الجلسة: $e', name: 'UserService');
      return false;
    }
  }

  // التحقق من صلاحية المستخدم
  static Future<bool> checkPermission(String userId, String permission) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      return user.hasPermission(permission);
    } catch (e) {
      developer.log('❌ خطأ في التحقق من الصلاحية: $e', name: 'UserService');
      return false;
    }
  }

  // الحصول على إحصائيات المستخدمين
  static Future<Map<String, int>> getUserStatistics() async {
    if (_dao == null) {
      return {
        'total_users': 0,
        'active_users': 0,
        'active_sessions': 0,
      };
    }

    try {
      return await _dao!.getUserStatistics();
    } catch (e) {
      developer.log('❌ خطأ في جلب إحصائيات المستخدمين: $e',
          name: 'UserService');
      return {
        'total_users': 0,
        'active_users': 0,
        'active_sessions': 0,
      };
    }
  }

  /// جلب إحصائيات مبسطة (للـ main.dart)
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final stats = await getUserStatistics();

      // حساب عدد المدراء
      final users = await getAllUsers(activeOnly: true);
      final admins = users.where((u) => u.role == UserRole.admin).length;

      return {
        'total': stats['total_users'] ?? 0,
        'active': stats['active_users'] ?? 0,
        'admins': admins,
        'sessions': stats['active_sessions'] ?? 0,
      };
    } catch (e) {
      developer.log('❌ خطأ في جلب إحصائيات المستخدمين: $e',
          name: 'UserService');
      return {
        'total': 0,
        'active': 0,
        'admins': 0,
        'sessions': 0,
      };
    }
  }

  // الحصول على الصلاحيات الافتراضية لكل دور
  static List<String> getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return ['all'];
      case UserRole.manager:
        return ['sales', 'inventory', 'reports', 'suppliers', 'users'];
      case UserRole.pharmacist:
        return ['sales', 'inventory', 'reports'];
      case UserRole.cashier:
        return ['sales'];
    }
  }

  /// حذف مستخدم نهائياً (للمدير فقط)
  static Future<bool> deleteUserPermanently(String userId) async {
    if (_dao == null) return false;

    try {
      final user = await getUserById(userId);
      if (user == null || user.username == 'admin') {
        return false;
      }

      await _dao!.deleteUser(userId);
      await _dao!.deleteUserSessions(userId);

      developer.log('✅ تم حذف المستخدم نهائياً: $userId', name: 'UserService');

      return true;
    } catch (e) {
      developer.log('❌ خطأ في حذف المستخدم: $e', name: 'UserService');
      return false;
    }
  }

  // تشفير كلمة المرور (استخدام النظام الجديد)
  static String _hashPassword(String password) {
    return PasswordHasher.hash(password);
  }

  // توليد ID فريد باستخدام UUID v4
  static String _generateId() {
    return const Uuid().v4();
  }

  // توليد session token آمن
  static String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  // تسجيل نشاط المستخدم
  static Future<void> _logActivity(
    String userId,
    String action,
    String details,
  ) async {
    if (_dao == null) return;

    try {
      await _dao!.logUserActivity(UserActivitiesCompanion.insert(
        id: _generateId(),
        userId: userId,
        action: action,
        details: Value(details),
        ipAddress: Value(await _getIpAddress()),
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      developer.log('❌ خطأ في تسجيل النشاط: $e', name: 'UserService');
    }
  }

  // الدوال المفقودة الإضافية

  // دالة للتحقق من صلاحيات مستخدم محدد (مباشرة بدون async)
  static bool hasPermission(User user, String permission) {
    return user.hasPermission(permission);
  }

  // إعادة تعيين كلمة المرور (alias لـ resetPassword)
  static Future<bool> resetUserPassword(
      String userId, String newPassword) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return false;

    final result = await resetPassword(
      userId: userId,
      newPassword: newPassword,
      adminId: currentUser.id,
    );

    return result['success'] ?? false;
  }

  // إيقاف تفعيل مستخدم
  static Future<bool> deactivateUser(String userId) async {
    final result = await updateUser(
      userId: userId,
      isActive: false,
    );

    return result['success'] ?? false;
  }

  // الحصول على معلومات الجهاز
  static Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return 'Windows: ${windowsInfo.computerName} (${windowsInfo.majorVersion}.${windowsInfo.minorVersion})';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return 'Linux: ${linuxInfo.name} (${linuxInfo.versionId})';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return 'macOS: ${macInfo.computerName} (${macInfo.osRelease})';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'Android: ${androidInfo.model} (${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'iOS: ${iosInfo.name} (${iosInfo.systemVersion})';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device (Error)';
    }
  }

  // الحصول على IP Address
  static Future<String> _getIpAddress() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      return ip ?? '127.0.0.1';
    } catch (e) {
      return '127.0.0.1';
    }
  }

  /// Map Drift UserEntry to domain User
  static User _mapEntryToUser(UserEntry entry) {
    return User(
      id: entry.id,
      username: entry.username,
      fullName: entry.fullName,
      email: entry.email,
      phone: entry.phone,
      passwordHash: entry.passwordHash,
      role: UserRole.fromString(entry.role),
      permissions: entry.permissions?.split(',') ?? [],
      isActive: entry.isActive,
      forcePasswordChange: entry.forcePasswordChange,
      lastLogin: entry.lastLogin,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      createdBy: entry.createdBy,
    );
  }

  /// Verify password for a user (for re-authentication)
  /// Returns true if password is correct, false otherwise
  static Future<bool> verifyPassword({
    required String username,
    required String password,
  }) async {
    if (_dao == null) {
      developer.log('❌ UserService not initialized', name: 'UserService');
      return false;
    }

    try {
      final userEntry = await _dao!.findByUsername(username);

      if (userEntry == null || !userEntry.isActive) {
        return false;
      }

      final user = _mapEntryToUser(userEntry);

      // Check legacy hash first
      if (PasswordHasher.isLegacyHash(user.passwordHash)) {
        final upgradedHash = PasswordHasher.upgradeLegacyHash(
          user.passwordHash,
          password,
        );
        return upgradedHash != null;
      }

      // New hash - verify normally
      return PasswordHasher.verify(password, user.passwordHash);
    } catch (e) {
      developer.log('❌ Password verification error: $e', name: 'UserService');
      return false;
    }
  }
}
