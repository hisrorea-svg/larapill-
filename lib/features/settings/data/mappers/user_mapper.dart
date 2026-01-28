import '../../../../services/user_service.dart' as service;
import '../../domain/entities/user_entity.dart';

class UserMapper {
  static UserEntity toEntity(service.User user) {
    return UserEntity(
      id: user.id,
      username: user.username,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      passwordHash: user.passwordHash,
      role: _mapRoleToEntity(user.role),
      permissions: user.permissions,
      isActive: user.isActive,
      forcePasswordChange: user.forcePasswordChange,
      lastLogin: user.lastLogin,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      createdBy: user.createdBy,
    );
  }

  static service.User fromEntity(UserEntity entity) {
    return service.User(
      id: entity.id,
      username: entity.username,
      fullName: entity.fullName,
      email: entity.email,
      phone: entity.phone,
      passwordHash: entity.passwordHash,
      role: _mapRoleFromEntity(entity.role),
      permissions: entity.permissions,
      isActive: entity.isActive,
      forcePasswordChange: entity.forcePasswordChange,
      lastLogin: entity.lastLogin,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
    );
  }

  static UserRole _mapRoleToEntity(service.UserRole role) {
    switch (role) {
      case service.UserRole.admin:
        return UserRole.admin;
      case service.UserRole.manager:
        return UserRole.manager;
      case service.UserRole.pharmacist:
        return UserRole.pharmacist;
      case service.UserRole.cashier:
        return UserRole.cashier;
      // The inventory role does not exist in the domain entity, so we map it to pharmacist
      case service.UserRole.inventory:
        return UserRole.pharmacist;
    }
  }

  static service.UserRole _mapRoleFromEntity(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return service.UserRole.admin;
      case UserRole.manager:
        return service.UserRole.manager;
      case UserRole.pharmacist:
        return service.UserRole.pharmacist;
      case UserRole.cashier:
        return service.UserRole.cashier;
    }
  }
}
