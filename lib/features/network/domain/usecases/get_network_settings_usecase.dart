// lib/features/network/domain/usecases/get_network_settings_usecase.dart
import '../entities/network_settings_entity.dart';
import '../repositories/network_settings_repository_interface.dart';

/// UseCase لجلب إعدادات الشبكة
class GetNetworkSettingsUseCase {
  final NetworkSettingsRepositoryInterface _repository;

  const GetNetworkSettingsUseCase(this._repository);

  /// تنفيذ UseCase (synchronous بفضل HiveStorage)
  NetworkSettingsEntity call() {
    return _repository.getSettings();
  }
}
