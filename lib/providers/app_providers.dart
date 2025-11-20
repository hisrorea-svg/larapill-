import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/pharmacy_info.dart';
import '../features/notifications/models/notification.dart'; // ✅ تم الإضافة
import '../services/notification_service.dart'; // ✅ تم الإضافة
import '../services/user_service.dart'; // ✅ User model موجود هنا
import '../database/database_helper.dart';

// ======================================================================
// Pharmacy & User Providers
// ======================================================================

// ✅ معلومات الصيدلية - من قاعدة البيانات
final pharmacyInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final result = await db.query('pharmacy_settings', limit: 1);

    if (result.isNotEmpty) {
      final data = result.first;
      return {
        'name': data['name_ar'] ?? 'صيدلية فارماكليك',
        'english_name': data['name_en'] ?? 'LaRaPill Pharmacy',
        'phone': data['phone'] ?? '',
        'mobile': data['mobile'] ?? '',
        'address': data['address'] ?? '',
        'city': data['city'] ?? '',
        'email': data['email'] ?? '',
        'website': data['website'] ?? '',
        'license_number': data['license_number'] ?? '',
        'tax_number': data['tax_number'] ?? '',
        'commercial_registration': data['commercial_registration'] ?? '',
      };
    }
  } catch (e) {
    // في حالة الخطأ، نستخدم القيم الافتراضية
  }

  // القيم الافتراضية
  return {
    'name':
        PharmacyInfo.name.isNotEmpty ? PharmacyInfo.name : 'صيدلية فارماكليك',
    'english_name': PharmacyInfo.englishName.isNotEmpty
        ? PharmacyInfo.englishName
        : 'LaRaPill Pharmacy',
    'phone': PharmacyInfo.phone,
    'mobile': '',
    'address': PharmacyInfo.address,
    'city': '',
    'email': PharmacyInfo.email,
    'website': '',
    'license_number': '',
    'tax_number': '',
    'commercial_registration': '',
  };
});

// ✅ المستخدم الحالي
final currentUserProvider = FutureProvider<User?>((ref) async {
  try {
    return await UserService.getCurrentUser();
  } catch (e) {
    return null;
  }
});

// ✅ معلومات المستخدم للعرض
final userInfoProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(currentUserProvider).when(
        data: (user) {
          if (user != null) {
            return {
              'fullName': user.fullName,
              'role': user.role.displayName,
              'username': user.username,
              'email': user.email ?? 'غير محدد',
            };
          } else {
            return {
              'fullName': 'مدير النظام',
              'role': 'مدير النظام',
              'username': 'admin',
              'email': 'admin@pharmacy.com',
            };
          }
        },
        loading: () => {
          'fullName': 'جاري التحميل...',
          'role': '...',
          'username': '...',
          'email': '...',
        },
        error: (_, __) => {
          'fullName': 'مدير النظام',
          'role': 'مدير النظام',
          'username': 'admin',
          'email': 'admin@pharmacy.com',
        },
      );
});

// ✅ اسم الصيدلية للعرض
final pharmacyDisplayNameProvider = Provider<String>((ref) {
  return ref.watch(pharmacyInfoProvider).when(
        data: (info) => info['name'] as String,
        loading: () => 'جاري التحميل...',
        error: (_, __) => 'صيدلية LaRaPill',
      );
});

// ✅ اسم المستخدم للعرض
final userDisplayNameProvider = Provider<String>((ref) {
  final userInfo = ref.watch(userInfoProvider);
  return userInfo['fullName'] ?? 'مدير النظام';
});

// ✅ دور المستخدم للعرض
final userRoleProvider = Provider<String>((ref) {
  final userInfo = ref.watch(userInfoProvider);
  return userInfo['role'] ?? 'مدير النظام';
});

// ✅ فحص إذا كان المستخدم admin
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).when(
        data: (user) => user?.role == UserRole.admin,
        loading: () => false,
        error: (_, __) => false,
      );
});

// ✅ صلاحيات المستخدم
final userPermissionsProvider = Provider<List<String>>((ref) {
  return ref.watch(currentUserProvider).when(
        data: (user) => user?.permissions ?? ['sales'],
        loading: () => <String>[],
        error: (_, __) => ['sales'],
      );
});

// ✅ حالة تسجيل الدخول
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );
});

// ======================================================================
// Notification Providers
// ======================================================================

// ✅ خدمة الإشعارات
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

// ✅ جلب جميع الإشعارات
final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getAllNotifications();
});

// ✅ عدد الإشعارات غير المقروءة
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getUnreadCount();
});

// ✅ الإشعارات غير المقروءة فقط
final unreadNotificationsProvider =
    Provider<AsyncValue<List<AppNotification>>>((ref) {
  return ref.watch(notificationsProvider).when(
        data: (notifications) => AsyncValue.data(
          notifications.where((n) => !n.isRead).toList(),
        ),
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
});

// ✅ هل يوجد إشعارات غير مقروءة
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(unreadNotificationsCountProvider).when(
        data: (count) => count > 0,
        loading: () => false,
        error: (_, __) => false,
      );
});
