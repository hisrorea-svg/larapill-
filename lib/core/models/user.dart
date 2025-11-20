import 'package:flutter/material.dart';

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
      // ✅ إصلاح null safety
      permissions: (map['permissions'] as String? ?? '')
          .split(',')
          .where((p) => p.isNotEmpty)
          .toList(),
      isActive: map['is_active'] == 1,
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
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
}

// ✅ UserRole مُصحح بالكامل
enum UserRole {
  admin('admin', 'مدير النظام', Color(0xFFFF6B6B)), // أحمر
  manager('manager', 'مدير', Color(0xFFFECA57)), // أصفر
  pharmacist('pharmacist', 'صيدلي', Color(0xFF1DD1A1)), // أخضر
  cashier('cashier', 'كاشير', Color(0xFF54A0FF)); // أزرق

  const UserRole(this.name, this.displayName, this.color);

  final String name;
  final String displayName;
  final Color color;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.name == role,
      orElse: () => UserRole.cashier,
    );
  }

  // ✅ دالة مساعدة للأيقونة
  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.manager:
        return Icons.supervisor_account;
      case UserRole.pharmacist:
        return Icons.local_pharmacy;
      case UserRole.cashier:
        return Icons.point_of_sale;
    }
  }

  // ✅ وصف الصلاحيات
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
