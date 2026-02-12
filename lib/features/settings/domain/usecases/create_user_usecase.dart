import '../../../auth/domain/entities/user.dart';
import '../repositories/users_repository.dart';
import '../repositories/settings_repository.dart'; // For Either
import '../failures/settings_failure.dart';

/// Parameters لإنشاء مستخدم جديد
class CreateUserParams {
  final String username;
  final String fullName;
  final String passwordHash;
  final UserRole role;
  final String? email;
  final String? phone;
  final List<String> permissions;
  final String? createdBy;

  const CreateUserParams({
    required this.username,
    required this.fullName,
    required this.passwordHash,
    required this.role,
    this.email,
    this.phone,
    this.permissions = const [],
    this.createdBy,
  });
}

/// Use Case لإنشاء مستخدم جديد
///
/// يستخدم Either للتعامل مع الأخطاء
class CreateUserUseCase {
  final UsersRepository _repository;

  const CreateUserUseCase(this._repository);

  /// تنفيذ Use Case
  Future<Either<SettingsFailure, User>> call(CreateUserParams params) async {
    // التحقق من صحة البيانات
    if (params.username.isEmpty) {
      return const Either.left(ValidationSettingsFailure('اسم المستخدم مطلوب'));
    }
    if (params.fullName.isEmpty) {
      return const Either.left(ValidationSettingsFailure('الاسم الكامل مطلوب'));
    }
    if (params.passwordHash.isEmpty) {
      return const Either.left(ValidationSettingsFailure('كلمة المرور مطلوبة'));
    }

    // التحقق من وجود اسم المستخدم
    final usernameExistsResult =
        await _repository.usernameExists(params.username);
    return usernameExistsResult.fold(
      (failure) => Either.left(failure),
      (exists) async {
        if (exists) {
          return const Either.left(UsernameExistsFailure());
        }

        // إنشاء User
        final now = DateTime.now();
        final user = User(
          id: _generateUserId(),
          username: params.username,
          fullName: params.fullName,
          email: params.email,
          phone: params.phone,
          passwordHash: params.passwordHash,
          role: params.role,
          permissions: params.permissions,
          isActive: true,
          forcePasswordChange: false,
          createdAt: now,
          updatedAt: now,
          createdBy: params.createdBy,
        );

        return await _repository.createUser(user, createdBy: params.createdBy);
      },
    );
  }

  /// توليد معرف فريد للمستخدم
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${_randomString(6)}';
  }

  /// توليد سلسلة عشوائية
  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(
          chars[(DateTime.now().millisecondsSinceEpoch + i) % chars.length]);
    }
    return buffer.toString();
  }
}
