import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'dart:developer' as developer;
import '../database/database_helper.dart';
import '../core/services/password_hasher.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/services/audit_logger.dart';
import '../core/utils/input_sanitizer.dart';

// ================================
// ✅ User Model
// ================================
class User {
  final String id;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final String passwordHash;
  final UserRole role;
  final List<String> permissions;
  final bool isActive;
  final bool forcePasswordChange;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    required this.passwordHash,
    required this.role,
    required this.permissions,
    required this.isActive,
    this.forcePasswordChange = false,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      fullName: map['full_name'],
      email: map['email'],
      phone: map['phone'],
      passwordHash: map['password_hash'],
      role: UserRole.fromString(map['role']),
      permissions: (map['permissions'] as String? ?? '')
          .split(',')
          .where((p) => p.isNotEmpty)
          .toList(),
      isActive: map['is_active'] == 1,
      forcePasswordChange: (map['force_password_change'] ?? 0) == 1,
      lastLogin:
          map['last_login'] != null ? DateTime.parse(map['last_login']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      createdBy: map['created_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'role': role.name,
      'permissions': permissions.join(','),
      'is_active': isActive ? 1 : 0,
      'force_password_change': forcePasswordChange ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? passwordHash,
    UserRole? role,
    List<String>? permissions,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  bool hasPermission(String permission) {
    if (role == UserRole.admin) return true;
    return permissions.contains(permission) || permissions.contains('all');
  }

  String getRoleDisplayName() {
    return role.displayName;
  }
}

// ================================
// ✅ UserRole Enum - كامل مع جميع الخصائص
// ================================
enum UserRole {
  admin('admin', 'مدير النظام', Color(0xFFFF6B6B), Icons.admin_panel_settings,
      'جميع الصلاحيات'),
  manager('manager', 'مدير', Color(0xFFFECA57), Icons.supervisor_account,
      'إدارة المخزون والمبيعات'),
  pharmacist('pharmacist', 'صيدلي', Color(0xFF1DD1A1), Icons.local_pharmacy,
      'المبيعات والاستعلامات'),
  cashier('cashier', 'كاشير', Color(0xFF54A0FF), Icons.point_of_sale,
      'المبيعات فقط'),
  inventory('inventory', 'مسؤول المخزون', Color(0xFFAB47BC), Icons.inventory_2,
      'إدارة المخزون فقط');

  const UserRole(
      this.name, this.displayName, this.color, this.icon, this.description);

  final String name;
  final String displayName;
  final Color color;
  final IconData icon;
  final String description;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.name == role,
      orElse: () => UserRole.cashier,
    );
  }
}

// ================================
// ✅ UserService - مع التشفير الآمن
// ================================
class UserService {
  static const String _currentUserKey = 'current_user_id';
  static const String _sessionTokenKey = 'session_token';

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

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // التحقق من وجود اسم المستخدم
      final existingUsers = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [cleanUsername],
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw DatabaseTimeoutException(
          'انتهت مهلة البحث عن اسم المستخدم',
          timeout: const Duration(seconds: 10),
        ),
      );

      if (existingUsers.isNotEmpty) {
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

      final user = User(
        id: userId,
        username: cleanUsername,
        fullName: cleanFullName,
        email: cleanEmail,
        phone: cleanPhone,
        passwordHash: _hashPassword(password),
        role: role,
        permissions: permissions ?? getDefaultPermissions(role),
        isActive: true,
        createdAt: now,
        updatedAt: now,
        createdBy: createdBy,
      );

      await db.insert('users', user.toMap()).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw DatabaseTimeoutException(
              'انتهت مهلة إنشاء المستخدم',
              timeout: const Duration(seconds: 10),
            ),
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
    } on sqflite.DatabaseException catch (e) {
      developer.log('❌ خطأ قاعدة بيانات في إنشاء المستخدم: $e',
          name: 'UserService', error: e);
      throw DatabaseException(
        'فشل إنشاء المستخدم في قاعدة البيانات',
        originalError: e,
        tableName: 'users',
        operation: 'insert',
      );
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
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final users = await db.query(
        'users',
        where: 'username = ? AND is_active = 1',
        whereArgs: [username],
      );

      if (users.isEmpty) {
        return {
          'success': false,
          'error': 'اسم المستخدم غير موجود أو غير مفعل',
        };
      }

      final user = User.fromMap(users.first);

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
          await db.update(
            'users',
            {
              'password_hash': upgradedHash,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [user.id],
          );

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

      await db.insert('user_sessions', {
        'id': _generateId(),
        'user_id': user.id,
        'session_token': sessionToken,
        'device_info': 'Windows Desktop',
        'ip_address': '127.0.0.1',
        'login_time': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'is_active': 1,
      });

      // تحديث آخر تسجيل دخول
      await db.update(
        'users',
        {
          'last_login': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );

      // حفظ الجلسة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, user.id);
      await prefs.setString(_sessionTokenKey, sessionToken);

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
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);
      final sessionToken = prefs.getString(_sessionTokenKey);

      if (userId != null) {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;

        // إنهاء الجلسة
        if (sessionToken != null) {
          await db.update(
            'user_sessions',
            {
              'is_active': 0,
              'last_activity': DateTime.now().toIso8601String(),
            },
            where: 'session_token = ?',
            whereArgs: [sessionToken],
          );
        }

        // تسجيل النشاط
        await _logActivity(userId, 'logout', 'تسجيل خروج');
      }

      // مسح البيانات المحلية
      await prefs.remove(_currentUserKey);
      await prefs.remove(_sessionTokenKey);

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);
      final sessionToken = prefs.getString(_sessionTokenKey);

      if (userId == null || sessionToken == null) {
        return null;
      }

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // التحقق من صلاحية الجلسة
      final sessions = await db.query(
        'user_sessions',
        where: 'user_id = ? AND session_token = ? AND is_active = 1',
        whereArgs: [userId, sessionToken],
      );

      if (sessions.isEmpty) {
        await prefs.remove(_currentUserKey);
        await prefs.remove(_sessionTokenKey);
        return null;
      }

      // تحديث آخر نشاط
      await db.update(
        'user_sessions',
        {'last_activity': DateTime.now().toIso8601String()},
        where: 'session_token = ?',
        whereArgs: [sessionToken],
      );

      // جلب بيانات المستخدم
      final users = await db.query(
        'users',
        where: 'id = ? AND is_active = 1',
        whereArgs: [userId],
      );

      if (users.isEmpty) {
        return null;
      }

      return User.fromMap(users.first);
    } catch (e) {
      developer.log('❌ خطأ في جلب المستخدم الحالي: $e', name: 'UserService');
      return null;
    }
  }

  // الحصول على مستخدم بواسطة الـ ID
  static Future<User?> getUserById(String userId) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final users = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) return null;

      return User.fromMap(users.first);
    } catch (e) {
      developer.log('❌ خطأ في جلب المستخدم: $e', name: 'UserService');
      return null;
    }
  }

  // جلب جميع المستخدمين
  static Future<List<User>> getAllUsers({bool activeOnly = false}) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final List<Map<String, dynamic>> users = activeOnly
          ? await db.query(
              'users',
              where: 'is_active = 1',
              orderBy: 'created_at DESC',
            )
          : await db.query(
              'users',
              orderBy: 'created_at DESC',
            );

      return users.map((map) => User.fromMap(map)).toList();
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
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (role != null) updateData['role'] = role.name;
      if (permissions != null) {
        updateData['permissions'] = permissions.join(',');
      }
      if (isActive != null) updateData['is_active'] = isActive ? 1 : 0;

      await db.update(
        'users',
        updateData,
        where: 'id = ?',
        whereArgs: [userId],
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
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // جلب المستخدم
      final users = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) {
        return {
          'success': false,
          'error': 'المستخدم غير موجود',
        };
      }

      final user = User.fromMap(users.first);

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

      await db.update(
        'users',
        {
          'password_hash': newHash,
          'force_password_change': 0, // إزالة الإجبار على تغيير كلمة المرور
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

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
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final newHash = _hashPassword(newPassword);

      await db.update(
        'users',
        {
          'password_hash': newHash,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

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
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // إيقاف التفعيل بدلاً من الحذف الفعلي
      await db.update(
        'users',
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      // إنهاء جميع جلسات المستخدم
      await db.update(
        'user_sessions',
        {'is_active': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

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
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final activities = await db.query(
        'user_activities',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return activities;
    } catch (e) {
      developer.log('❌ خطأ في جلب نشاطات المستخدم: $e', name: 'UserService');
      return [];
    }
  }

  // جلب الجلسات النشطة
  static Future<List<Map<String, dynamic>>> getActiveSessions(
      String userId) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final sessions = await db.query(
        'user_sessions',
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
        orderBy: 'login_time DESC',
      );

      return sessions;
    } catch (e) {
      developer.log('❌ خطأ في جلب الجلسات النشطة: $e', name: 'UserService');
      return [];
    }
  }

  // إنهاء جلسة محددة
  static Future<bool> terminateSession(String sessionToken) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.update(
        'user_sessions',
        {'is_active': 0},
        where: 'session_token = ?',
        whereArgs: [sessionToken],
      );

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
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final totalUsers = sqflite.Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM users'),
      );

      final activeUsers = sqflite.Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM users WHERE is_active = 1'),
      );

      final activeSessions = sqflite.Sqflite.firstIntValue(
        await db
            .rawQuery('SELECT COUNT(*) FROM user_sessions WHERE is_active = 1'),
      );

      return {
        'total_users': totalUsers ?? 0,
        'active_users': activeUsers ?? 0,
        'active_sessions': activeSessions ?? 0,
      };
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
      case UserRole.inventory:
        return ['inventory', 'reports'];
    }
  }

  /// حذف مستخدم نهائياً (للمدير فقط)
  static Future<bool> deleteUserPermanently(String userId) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final user = await getUserById(userId);
      if (user == null || user.username == 'admin') {
        return false;
      }

      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      await db.delete(
        'user_sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

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

  // توليد ID فريد
  static String _generateId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
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
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.insert('user_activities', {
        'id': _generateId(),
        'user_id': userId,
        'action': action,
        'details': details,
        'ip_address': '127.0.0.1',
        'created_at': DateTime.now().toIso8601String(),
      });
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

  // تحديث مستخدم (نسخة مبسطة تقبل Map)
}
