import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
// Note: Path imports moved to database helper classes

import '../../core/config/pharmacy_info.dart';
import '../../features/auth/data/repositories/user_service.dart';
import '../../features/auth/data/services/authentication_service.dart';
import '../services/meds_data_service.dart';
import '../services/audit_logger.dart';
import '../services/pharmacy_settings_service.dart';
import '../storage/hive_storage.dart';
import '../../features/auth/domain/entities/user.dart';
import '../database/drift/app_database.dart';
import '../database/drift/daos/daos.dart';
import '../../features/auth/data/services/session_service.dart';
import '../database/drift/database_provider.dart';
import 'package:drift/drift.dart';

// ============================================================================
// 🚀 AppBootstrap - Lazy Initialization Pattern
// ============================================================================

/// حالة التهيئة للمتابعة
enum BootstrapStatus {
  idle,
  initializing,
  criticalDone,      // ✅ الخدمات الحرجة جاهزة (يمكن عرض UI)
  backgroundRunning, // 🔄 الخدمات الثقيلة تعمل في الخلفية
  completed,         // ✅ جميع الخدمات جاهزة
  error,
}

/// نتيجة التهيئة
class BootstrapResult {
  final BootstrapStatus status;
  final String? error;
  final Duration elapsedTime;

  const BootstrapResult({
    required this.status,
    this.error,
    required this.elapsedTime,
  });
}

/// كلاس مسؤول عن تهيئة التطبيق بشكل Lazy وغير متزامن
/// 
/// الميزات:
/// - ✅ تهيئة الخدمات الحرجة فوراً (UI Thread)
/// - ✅ تهيئة الخدمات الثقيلة (UI Thread - plugins لا تعمل في isolates)
/// - ✅ عدم حظر UI أثناء التهيئة
/// - ✅ إمكانية عرض الواجهة قبل اكتمال جميع الخدمات
class AppBootstrap {
  static final _initCompleter = Completer<BootstrapResult>();
  static bool _isInitializing = false;
  static final _criticalCompleter = Completer<void>();
  static DateTime? _initStartTime;

  // ==========================================================================
  // Public API
  // ==========================================================================

  /// ✅ الدالة الرئيسية للتهيئة - لا تحظر UI
  /// 
  /// تقوم بـ:
  /// 1. تهيئة الخدمات الحرجة فوراً (UI Thread)
  /// 2. بدء تهيئة الخدمات الثقيلة في Isolate
  static Future<BootstrapResult> init() async {
    if (_isInitializing) return _initCompleter.future;
    _isInitializing = true;
    _initStartTime = DateTime.now();

    developer.log('🚀 بدء التهيئة المتقدمة...', name: 'AppBootstrap');

    try {
      // ✅ الخطوة 1: تهيئة حرجة فورية (UI Thread)
      await _initCriticalServices();
      
      // ✅ الخطوة 2: إشارة بأن الخدمات الحرجة جاهزة
      _criticalCompleter.complete();
      developer.log('✅ الخدمات الحرجة جاهزة - يمكن عرض UI', 
          name: 'AppBootstrap');

      // ✅ الخطوة 3: تهيئة الخدمات الثقيلة في Isolate
      _initHeavyServicesInBackground();

      return await _initCompleter.future;
    } catch (e, stack) {
      developer.log('❌ خطأ كارثي أثناء التهيئة',
          name: 'AppBootstrap', error: e, stackTrace: stack);
      
      final result = BootstrapResult(
        status: BootstrapStatus.error,
        error: e.toString(),
        elapsedTime: DateTime.now().difference(_initStartTime!),
      );
      
      if (!_criticalCompleter.isCompleted) {
        _criticalCompleter.completeError(e);
      }
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(result);
      }
      
      return result;
    }
  }

  /// ✅ الانتظار حتى تكون الخدمات الحرجة جاهزة (للـ Splash Screen)
  static Future<void> get waitForCritical => _criticalCompleter.future;

  /// ✅ الانتظار حتى تكتمل جميع الخدمات
  static Future<BootstrapResult> get waitForComplete => _initCompleter.future;

  /// ✅ فحص هل التهيئة اكتملت
  static bool get isComplete => _initCompleter.isCompleted;

  /// ✅ فحص هل الخدمات الحرجة جاهزة
  static bool get isCriticalReady => _criticalCompleter.isCompleted;

  // ==========================================================================
  // Private Implementation - Critical Services (UI Thread)
  // ==========================================================================

  /// ✅ تهيئة الخدمات الحرجة فقط - تؤثر على UI
  static Future<void> _initCriticalServices() async {
    final stopwatch = Stopwatch()..start();

    // 1. تعطيل تحميل الخطوط من الإنترنت
    GoogleFonts.config.allowRuntimeFetching = false;

    // 2. إعداد معالجة الأخطاء
    _setupErrorHandling();

    // 3. تهيئة FFI للويندوز/لينكس (سريع)
    _setupDesktopSupport();

    // 4. إعدادات النظام (System UI)
    await _setupSystemUI();

    stopwatch.stop();
    developer.log(
      '✅ Critical services initialized in ${stopwatch.elapsedMilliseconds}ms',
      name: 'AppBootstrap',
    );
  }

  // ==========================================================================
  // Private Implementation - Heavy Services (Background on UI Thread)
  // ==========================================================================

  /// ✅ تهيئة الخدمات الثقيلة (على Main Isolate)
  /// 
  /// ملاحظة: لا يمكن استخدام Isolate لأن Flutter plugins لا تعمل في isolates
  static void _initHeavyServicesInBackground() {
    // تشغيل على Main Isolate مباشرة (الـ plugins تتطلب UI thread)
    _heavyInitialization().then((result) {
      _handleHeavyInitComplete(result);
    }).catchError((error) {
      _handleHeavyInitError(error);
    });
  }

  /// ✅ هذه الدالة تعمل على Main Isolate
  /// 
  /// تحذير: Flutter plugins لا تعمل في isolates
  static Future<Map<String, dynamic>> _heavyInitialization() async {
    final stopwatch = Stopwatch()..start();
    final results = <String, dynamic>{};

    try {
      developer.log('🔄 Heavy initialization started', 
          name: 'AppBootstrap.Background');

      // 1. تهيئة intl
      await initializeDateFormatting('ar', null);
      await initializeDateFormatting('en', null);
      results['intl'] = true;
      
      // ✅ السماح لـ UI بالتحديث
      await Future.delayed(Duration.zero);

      // 2. تهيئة Hive Storage
      await HiveStorage.init();
      results['hive'] = true;
      developer.log('✅ Hive initialized', 
          name: 'AppBootstrap.Background');
      
      // ✅ السماح لـ UI بالتحديث
      await Future.delayed(Duration.zero);

      // 3. تهيئة قاعدة البيانات
      final db = DatabaseProviderHelper.instance;
      await db.ensureInitialized();
      results['database'] = true;
      developer.log('✅ Database initialized', 
          name: 'AppBootstrap.Background');
      
      // ✅ السماح لـ UI بالتحديث
      await Future.delayed(Duration.zero);

      // 4. تهيئة DAOs
      _initDaoServicesInIsolate(db);
      results['daos'] = true;

      // 5. تحميل معلومات الصيدلية
      await PharmacyInfo.loadFromDatabase();
      results['pharmacy_info'] = true;

      // 6. تهيئة المستخدمين (إذا لزم الأمر)
      await _initializeDefaultUserInIsolate(db);
      results['users'] = true;

      // 7. تحميل بيانات الأدوية (Lazy - لا تُحمل في الذاكرة)
      await MedsDataService.init(); // فقط فتح الـ index
      results['meds'] = true;

      stopwatch.stop();
      results['elapsed_ms'] = stopwatch.elapsedMilliseconds;
      results['success'] = true;

      developer.log(
        '✅ Heavy initialization completed in ${stopwatch.elapsedMilliseconds}ms',
        name: 'AppBootstrap',
      );

      return results;
    } catch (e, stack) {
      developer.log('❌ Error in background init: $e',
          name: 'AppBootstrap', error: e, stackTrace: stack);
      return {
        'success': false,
        'error': e.toString(),
        'stack': stack.toString(),
        'elapsed_ms': stopwatch.elapsedMilliseconds,
      };
    }
  }

  /// ✅ معالجة اكتمال التهيئة الثقيلة
  static void _handleHeavyInitComplete(Map<String, dynamic> result) {
    final elapsed = DateTime.now().difference(_initStartTime!);

    if (result['success'] == true) {
      developer.log(
        '🎉 All services ready! Total time: ${elapsed.inMilliseconds}ms '
        '(Background: ${result['elapsed_ms']}ms)',
        name: 'AppBootstrap',
      );

      _initCompleter.complete(BootstrapResult(
        status: BootstrapStatus.completed,
        elapsedTime: elapsed,
      ));
    } else {
      _initCompleter.complete(BootstrapResult(
        status: BootstrapStatus.error,
        error: result['error'],
        elapsedTime: elapsed,
      ));
    }
  }

  /// ✅ معالجة خطأ التهيئة الثقيلة
  static void _handleHeavyInitError(dynamic error) {
    final elapsed = DateTime.now().difference(_initStartTime!);
    
    developer.log('❌ Heavy init error: $error', name: 'AppBootstrap');
    
    _initCompleter.complete(BootstrapResult(
      status: BootstrapStatus.error,
      error: error.toString(),
      elapsedTime: elapsed,
    ));
  }

  // ==========================================================================
  // Helper Methods
  // ==========================================================================

  static void _setupErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        developer.log(
          'Flutter Error: ${details.exception}',
          name: 'CrashReports',
          error: details.exception,
          stackTrace: details.stack,
        );
      }
    };
  }

  static void _setupDesktopSupport() {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      developer.log('🔧 تم تهيئة sqflite_common_ffi للويندوز/لينكس',
          name: 'AppBootstrap');
    }
  }

  static Future<void> _setupSystemUI() async {
    if (kReleaseMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  // ==========================================================================
  // DAO Services (يعمل في Isolate)
  // ==========================================================================

  static void _initDaoServicesInIsolate(AppDatabase database) {
    // Initialize AuditLogger with its DAO
    final auditLogDao = AuditLogDriftDao(database);
    AuditLogger.init(auditLogDao);

    // Initialize SessionService with its DAO
    final usersDao = UsersDriftDao(database);
    SessionService.init(usersDao);

    // Initialize UserService with its DAO
    UserService.init(usersDao);

    // Initialize AuthenticationService with its DAO
    AuthenticationService.init(usersDao);

    // Initialize PharmacySettingsService with its DAO
    final settingsDao = SettingsDriftDao(database);
    PharmacySettingsService.init(settingsDao);
  }

  // ==========================================================================
  // User Initialization (يعمل في Isolate)
  // ==========================================================================

  static Future<void> _initializeDefaultUserInIsolate(AppDatabase db) async {
    try {
      final usersDao = UsersDriftDao(db);
      final users = await usersDao.getAllUsers();

      if (users.isEmpty) {
        developer.log('👤 إنشاء المستخدمين الافتراضيين...', 
            name: 'AppBootstrap.Background');
        await _batchCreateDefaultUsers(usersDao);
      }
    } catch (e) {
      developer.log('⚠️ User init warning: $e', name: 'AppBootstrap.Background');
    }
  }

  static Future<void> _batchCreateDefaultUsers(UsersDriftDao dao) async {
    final now = DateTime.now();
    final users = [
      _createUserCompanion(
        username: 'admin',
        fullName: 'مدير النظام',
        passwordHash: _hashPassword('admin123'),
        role: UserRole.admin,
        email: 'admin@larapill.com',
        phone: '0501234567',
        permissions: ['all'],
        now: now,
      ),
      _createUserCompanion(
        username: 'manager',
        fullName: 'أحمد محمد - مدير',
        passwordHash: _hashPassword('123456'),
        role: UserRole.manager,
        email: 'manager@larapill.com',
        now: now,
      ),
      _createUserCompanion(
        username: 'pharmacist',
        fullName: 'فاطمة علي - صيدلي',
        passwordHash: _hashPassword('123456'),
        role: UserRole.pharmacist,
        email: 'pharmacist@larapill.com',
        now: now,
      ),
      _createUserCompanion(
        username: 'cashier',
        fullName: 'محمد خالد - كاشير',
        passwordHash: _hashPassword('123456'),
        role: UserRole.cashier,
        email: 'cashier@larapill.com',
        now: now,
      ),
    ];

    // ✅ Batch insert في عملية واحدة
    await dao.batchInsertUsers(users);
    
    developer.log('✅ تم إنشاء ${users.length} مستخدمين', 
        name: 'AppBootstrap.Isolate');
  }

  static UsersCompanion _createUserCompanion({
    required String username,
    required String fullName,
    required String passwordHash,
    required UserRole role,
    required DateTime now,
    String? email,
    String? phone,
    List<String>? permissions,
  }) {
    return UsersCompanion.insert(
      id: _generateId(),
      username: username,
      fullName: fullName,
      passwordHash: passwordHash,
      role: Value(role.name),
      email: Value(email),
      phone: Value(phone),
      permissions: Value(permissions?.join(',') ?? _getDefaultPermissions(role)),
      isActive: const Value(true),
      forcePasswordChange: const Value(false),
      createdAt: now,
      updatedAt: now,
      createdBy: const Value('system'),
    );
  }

  static String _hashPassword(String password) {
    // TODO: استخدم نفس منطق PasswordHasher
    return password; // مؤقتاً - يجب استبداله بالتشفير الحقيقي
  }

  static final _random = Random();

  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
  }

  static String _getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'all';
      case UserRole.manager:
        return 'sales,inventory,reports,suppliers,users';
      case UserRole.pharmacist:
        return 'sales,inventory,reports';
      case UserRole.cashier:
        return 'sales';
    }
  }
}
