import '../entities/pharmacy_settings_entity.dart';
import '../repositories/settings_repository.dart';
import '../failures/settings_failure.dart';

/// Use Case لجلب إعدادات الصيدلية
class GetPharmacySettingsUseCase {
  final SettingsRepository _repository;

  const GetPharmacySettingsUseCase(this._repository);

  /// تنفيذ Use Case
  Future<Either<SettingsFailure, PharmacySettingsEntity?>> call() async {
    return await _repository.getPharmacySettings();
  }
}
