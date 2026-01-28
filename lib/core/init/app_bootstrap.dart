import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../database/database_helper.dart';
import '../../core/config/pharmacy_info.dart';
import '../../services/user_service.dart';
import '../../services/meds_data_service.dart';
// Note: SmartNotificationService removed - using Clean Architecture notifications

/// كلاس مسؤول عن تهيئة التطبيق وكل ما يلزم قبل تشغيل الواجهة
class AppBootstrap {
  /// الدالة الرئيسية للتهيئة
  static Future<void> init() async {
    try {
      // 1. تهيئة Flutter Bindings
      WidgetsFlutterBinding.ensureInitialized();

      // 2. إعداد معالجة الأخطاء
      _setupErrorHandling();

      // 3. تهيئة FFI للويندوز/لينكس
      _setupDesktopSupport();

      // 4. إعدادات النظام (System UI)
      await _setupSystemUI();

      // 5. تهيئة قاعدة البيانات والخدمات
      await _initServices();
    } catch (e, stack) {
      developer.log('❌ خطأ كارثي أثناء تهيئة التطبيق',
          name: 'AppBootstrap', error: e, stackTrace: stack);
      // يمكن هنا إضافة منطق لإظهار شاشة خطأ للمستخدم في حال فشل التهيئة تماماً
      rethrow;
    }
  }

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

  static Future<void> _initServices() async {
    developer.log('🚀 بدء تهيئة الخدمات...', name: 'AppBootstrap');

    final dbHelper = DatabaseHelper();
    await dbHelper.initializeDatabase();

    developer.log('📋 تحميل معلومات الصيدلية...', name: 'AppBootstrap');
    await PharmacyInfo.loadFromDatabase();

    developer.log('👤 تهيئة نظام المستخدمين...', name: 'AppBootstrap');
    await _initializeDefaultUser();

    final stats = await dbHelper.getDatabaseStats();
    developer.log(
        '📊 المنتجات: ${stats['products']}, المبيعات: ${stats['sales']}, الموردين: ${stats['suppliers']}',
        name: 'AppBootstrap');

    developer.log('🎉 قاعدة البيانات وإعدادات الصيدلية جاهزة!',
        name: 'AppBootstrap');

    // تحميل بيانات الأدوية
    await MedsDataService.loadMeds();

    // TODO: Initialize notification monitoring via Clean Architecture when needed
    developer.log('🔔 نظام الإشعارات يستخدم Clean Architecture',
        name: 'AppBootstrap');
  }

  // 🔥 دالة إنشاء المستخدم الافتراضي
  static Future<void> _initializeDefaultUser() async {
    try {
      developer.log('👤 فحص المستخدمين الموجودين...', name: 'UserInit');

      final users = await UserService.getAllUsers();

      // إنشاء المدير الافتراضي دائماً إذا لم يوجد
      if (users.isEmpty || !users.any((u) => u.username == 'admin')) {
        developer.log('👤 إنشاء المدير الافتراضي...', name: 'UserInit');

        final result = await UserService.createUser(
          username: 'admin',
          fullName: 'مدير النظام',
          password: 'admin123',
          role: UserRole.admin,
          email: 'admin@larapill.com',
          phone: '0501234567',
          permissions: ['all'],
          createdBy: 'system',
        );

        if (result['success']) {
          developer.log('✅ تم إنشاء المدير الافتراضي بنجاح', name: 'UserInit');
          developer.log('📝 البيانات: admin / admin123', name: 'UserInit');

          // إنشاء بعض المستخدمين التجريبيين
          await _createDemoUsers();
        } else {
          developer.log('❌ فشل في إنشاء المدير الافتراضي: ${result['error']}',
              name: 'UserInit');
        }
      } else {
        developer.log('👥 يوجد ${users.length} مستخدم في النظام',
            name: 'UserInit');
      }

      // إحصائيات المستخدمين
      final userStats = await UserService.getUserStats();
      developer.log(
          '📊 إحصائيات - المجموع: ${userStats['total']}, النشط: ${userStats['active']}, المدراء: ${userStats['admins']}',
          name: 'UserInit');
    } catch (e) {
      developer.log('❌ خطأ في تهيئة المستخدمين: $e', name: 'UserInit');
    }
  }

  // إنشاء مستخدمين تجريبيين
  static Future<void> _createDemoUsers() async {
    try {
      // مدير
      await UserService.createUser(
        username: 'manager',
        fullName: 'أحمد محمد - مدير',
        password: '123456',
        role: UserRole.manager,
        email: 'manager@larapill.com',
        createdBy: 'system',
      );

      // صيدلي
      await UserService.createUser(
        username: 'pharmacist',
        fullName: 'فاطمة علي - صيدلي',
        password: '123456',
        role: UserRole.pharmacist,
        email: 'pharmacist@larapill.com',
        createdBy: 'system',
      );

      // كاشير
      await UserService.createUser(
        username: 'cashier',
        fullName: 'محمد خالد - كاشير',
        password: '123456',
        role: UserRole.cashier,
        createdBy: 'system',
      );

      developer.log('✅ تم إنشاء المستخدمين التجريبيين', name: 'UserInit');
    } catch (e) {
      developer.log('❌ خطأ في إنشاء المستخدمين التجريبيين: $e',
          name: 'UserInit');
    }
  }
}
