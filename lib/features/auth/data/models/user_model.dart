import 'dart:convert';
import '../../domain/entities/user.dart';

/// Data Transfer Object for User
/// Handles all database/JSON serialization
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.fullName,
    super.email,
    super.phone,
    required super.passwordHash,
    required super.role,
    required super.permissions,
    required super.isActive,
    super.forcePasswordChange,
    super.lastLogin,
    required super.createdAt,
    required super.updatedAt,
    super.createdBy,
  });

  /// From SQLite/Database Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      passwordHash: map['password_hash'] as String,
      role: UserRole.fromString(map['role'] as String),
      permissions: (map['permissions'] as String? ?? '')
          .split(',')
          .where((p) => p.isNotEmpty)
          .toList(),
      isActive: (map['is_active'] as int) == 1,
      forcePasswordChange: ((map['force_password_change'] as int?) ?? 0) == 1,
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      createdBy: map['created_by'] as String?,
    );
  }

  /// To SQLite/Database Map
  @override
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

  factory UserModel.fromRawJson(String str) =>
      UserModel.fromMap(json.decode(str) as Map<String, dynamic>);

  String toRawJson() => json.encode(toMap());

  /// Convert to clean domain entity
  User toEntity() {
    return User(
      id: id,
      username: username,
      fullName: fullName,
      email: email,
      phone: phone,
      passwordHash: passwordHash,
      role: role,
      permissions: permissions,
      isActive: isActive,
      forcePasswordChange: forcePasswordChange,
      lastLogin: lastLogin,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
    );
  }

  /// Create from entity + password hash
  factory UserModel.fromEntity(User user, String passwordHash) {
    return UserModel(
      id: user.id,
      username: user.username,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      passwordHash: passwordHash,
      role: user.role,
      permissions: user.permissions,
      isActive: user.isActive,
      forcePasswordChange: user.forcePasswordChange,
      lastLogin: user.lastLogin,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      createdBy: user.createdBy,
    );
  }
}
