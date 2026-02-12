import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/pharmacy_info.dart';
import '../../features/auth/data/repositories/user_service.dart';
import '../../features/auth/domain/entities/user.dart';
import '../database/drift/daos/daos.dart';

// ======================================================================
// Pharmacy & User Providers
// ======================================================================

// ✅ معلومات الصيدلية - من قاعدة البيانات عبر Drift
final pharmacyInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final settingsDao = ref.watch(settingsDriftDaoProvider);
    final entry = await settingsDao.getPharmacySettings();

    if (entry != null) {
      return {
        'name': entry.nameAr,
        'english_name': entry.nameEn,
        'phone': entry.phone,
        'mobile': entry.mobile,
        'address': entry.address,
        'city': entry.city,
        'email': entry.email,
        'website': entry.website,
        'license_number': entry.licenseNumber,
        'tax_number': entry.taxNumber,
        'commercial_registration': entry.commercialRegistration,
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
