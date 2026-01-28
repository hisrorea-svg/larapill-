import 'package:equatable/equatable.dart';

/// كيان المستخدم في Domain Layer
///
/// هذا الكيان خالٍ تماماً من أي Flutter imports أو data layer dependencies
/// يستخدم Equatable للمقارنة بين الكيانات
class UserEntity extends Equatable {
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

  const UserEntity({
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

  @override
  List<Object?> get props => [
        id,
        username,
        fullName,
        email,
        phone,
        passwordHash,
        role,
        permissions,
        isActive,
        forcePasswordChange,
        lastLogin,
        createdAt,
        updatedAt,
        createdBy,
      ];

  /// إنشاء نسخة محدثة من الكيان
  UserEntity copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? passwordHash,
    UserRole? role,
    List<String>? permissions,
    bool? isActive,
    bool? forcePasswordChange,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      forcePasswordChange: forcePasswordChange ?? this.forcePasswordChange,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// التحقق من أن المستخدم نشط
  bool get isUserActive => isActive;

  /// التحقق من أن المستخدم هو مدير النظام
  bool get isAdmin => role == UserRole.admin;

  /// التحقق من أن المستخدم لديه صلاحية معينة
  bool hasPermission(String permission) {
    if (isAdmin) return true;
    return permissions.contains(permission);
  }

  @override
  String toString() {
    return 'UserEntity{id: $id, username: $username, fullName: $fullName, role: $role}';
  }
}

/// أدوار المستخدمين
///
/// خالٍ من Flutter - يستخدم String فقط للعرض
enum UserRole {
  admin('admin', 'مدير النظام'),
  manager('manager', 'مدير متجر'),
  pharmacist('pharmacist', 'صيدلي'),
  cashier('cashier', 'كاشير');

  const UserRole(this.name, this.displayName);

  final String name;
  final String displayName;

  /// تحويل String إلى UserRole
  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.name == role,
      orElse: () => UserRole.cashier,
    );
  }

  /// الحصول على وصف الصلاحيات
  String get description {
    switch (this) {
      case UserRole.admin:
        return 'جميع الصلاحيات';
      case UserRole.manager:
        return 'إدارة المخزون والمبيعات';
      case UserRole.pharmacist:
        return 'المبيعات والاستعلامات';
      case UserRole.cashier:
        return 'المبيعات فقط';
    }
  }
}
