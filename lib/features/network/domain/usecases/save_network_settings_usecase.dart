// lib/features/network/domain/usecases/save_network_settings_usecase.dart
import '../entities/network_settings_entity.dart';
import '../repositories/network_settings_repository_interface.dart';

/// UseCase لحفظ إعدادات الشبكة
class SaveNetworkSettingsUseCase {
  final NetworkSettingsRepositoryInterface _repository;

  const SaveNetworkSettingsUseCase(this._repository);

  /// تنفيذ UseCase
  Future<void> call(NetworkSettingsEntity settings) async {
    await _repository.saveSettings(settings);
  }
}
