// lib/features/network/domain/usecases/get_network_settings_usecase.dart
import '../entities/network_settings_entity.dart';
import '../../data/repositories/network_settings_repository.dart';

/// UseCase لجلب إعدادات الشبكة
class GetNetworkSettingsUseCase {
  final NetworkSettingsRepository _repository;

  const GetNetworkSettingsUseCase(this._repository);

  /// تنفيذ UseCase
  Future<NetworkSettingsEntity> call() async {
    return await _repository.getSettings();
  }
}
