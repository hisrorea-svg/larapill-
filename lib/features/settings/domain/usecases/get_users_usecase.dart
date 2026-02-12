import '../../../auth/domain/entities/user.dart';
import '../repositories/users_repository.dart';
import '../repositories/settings_repository.dart'; // For Either
import '../failures/settings_failure.dart';

/// Use Case لجلب جميع المستخدمين النشطين
class GetUsersUseCase {
  final UsersRepository _repository;

  const GetUsersUseCase(this._repository);

  /// تنفيذ Use Case
  Future<Either<SettingsFailure, List<User>>> call() async {
    return await _repository.getActiveUsers();
  }
}
