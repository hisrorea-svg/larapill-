import '../../../auth/domain/entities/user.dart';
import '../repositories/users_repository.dart';
import '../repositories/settings_repository.dart'; // For Either
import '../failures/settings_failure.dart';

/// Use Case لجلب مستخدم بواسطة ID
class GetUserByIdUseCase {
  final UsersRepository _repository;

  const GetUserByIdUseCase(this._repository);

  /// تنفيذ Use Case
  Future<Either<SettingsFailure, User?>> call(String userId) async {
    if (userId.isEmpty) {
      return const Either.left(
          ValidationSettingsFailure('معرف المستخدم مطلوب'));
    }
    return await _repository.getUserById(userId);
  }
}
