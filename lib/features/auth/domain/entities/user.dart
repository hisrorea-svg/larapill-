import 'package:flutter/material.dart';

/// User roles in the pharmacy system
enum UserRole {
  admin,
  manager,
  pharmacist,
  cashier;

  /// Parse role from string
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'pharmacist':
        return UserRole.pharmacist;
      case 'cashier':
        return UserRole.cashier;
      default:
        return UserRole.cashier;
    }
  }

  /// Get display name for user role (Arabic)
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'مدير النظام';
      case UserRole.manager:
        return 'مدير';
      case UserRole.pharmacist:
        return 'صيدلي';
      case UserRole.cashier:
        return 'كاشير';
    }
  }

  /// Get color for user role
  Color get color {
    switch (this) {
      case UserRole.admin:
        return const Color(0xFFE53935); // Red
      case UserRole.manager:
        return const Color(0xFF1E88E5); // Blue
      case UserRole.pharmacist:
        return const Color(0xFF43A047); // Green
      case UserRole.cashier:
        return const Color(0xFFFB8C00); // Orange
    }
  }

  /// Get icon for user role
  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.pharmacist:
        return Icons.medical_services;
      case UserRole.cashier:
        return Icons.point_of_sale;
    }
  }
}

/// User entity for the auth domain
/// Contains business logic and authentication data
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

  const User({
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

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    if (role == UserRole.admin) return true;
    if (permissions.contains('all')) return true;
    return permissions.contains(permission);
  }

  /// Check if user can access feature
  bool canAccess(String feature) {
    return hasPermission(feature);
  }

  /// Get display name for user role
  String get roleDisplayName => role.displayName;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is manager or higher
  bool get isManagerOrHigher =>
      role == UserRole.admin || role == UserRole.manager;

  /// Create copy with updated fields
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
    bool? forcePasswordChange,
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
      forcePasswordChange: forcePasswordChange ?? this.forcePasswordChange,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, username: $username, role: $role)';

  // =====================================================
  // DEPRECATED: These methods should be in UserModel
  // Kept here temporarily for backward compatibility
  // =====================================================

  /// Create User from database map
  /// @deprecated Use UserModel.fromMap instead
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      fullName: map['full_name'] as String? ?? map['username'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      passwordHash: map['password_hash'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      permissions: _parsePermissions(map['permissions']),
      isActive: (map['is_active'] as int?) == 1,
      forcePasswordChange: (map['force_password_change'] as int?) == 1,
      lastLogin: map['last_login'] != null
          ? DateTime.tryParse(map['last_login'] as String)
          : null,
      createdAt: DateTime.parse(
          map['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          map['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      createdBy: map['created_by'] as String?,
    );
  }

  /// Convert User to database map
  /// @deprecated Use UserModel.toMap instead
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

  static List<String> _parsePermissions(dynamic permissions) {
    if (permissions == null) return [];
    if (permissions is List) return permissions.cast<String>();
    if (permissions is String) {
      return permissions
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
    }
    return [];
  }
}
