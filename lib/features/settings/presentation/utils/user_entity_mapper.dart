import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';

/// Utility class لتحويل UserEntity إلى Map للعرض في UI
/// 
/// هذا الملف موجود في presentation layer لأنه يحتاج Flutter imports
class UserEntityMapper {
  /// تحويل UserEntity إلى Map للعرض
  /// 
  /// [user] UserEntity المراد تحويله
  /// [Returns] Map يحتوي على البيانات المطلوبة للعرض
  static Map<String, dynamic> toDisplayMap(UserEntity user) {
    final (icon, color) = _getRoleStyle(user.role);
    final roleDisplay = user.role.displayName;

    return {
      'id': user.id,
      'name': user.fullName,
      'username': user.username,
      'role': roleDisplay,
      'role_key': user.role.name,
      'status': user.isActive ? 'نشط' : 'معطل',
      'icon': icon,
      'color': color,
      'email': user.email,
      'phone': user.phone,
    };
  }

  /// الحصول على الأيقونة واللون حسب الدور
  static (IconData, Color) _getRoleStyle(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return (Icons.admin_panel_settings, Colors.purple);
      case UserRole.pharmacist:
        return (Icons.local_pharmacy, Colors.blue);
      case UserRole.cashier:
        return (Icons.point_of_sale, Colors.green);
      case UserRole.manager:
        return (Icons.business_center, Colors.orange);
    }
  }

  /// تحويل قائمة UserEntity إلى قائمة Maps
  static List<Map<String, dynamic>> toDisplayMapList(
    List<UserEntity> users,
  ) {
    return users.map((user) => toDisplayMap(user)).toList();
  }
}
