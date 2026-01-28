// lib/features/network/domain/usecases/save_network_settings_usecase.dart
import '../entities/network_settings_entity.dart';
import '../../data/repositories/network_settings_repository.dart';

/// UseCase لحفظ إعدادات الشبكة
class SaveNetworkSettingsUseCase {
  final NetworkSettingsRepository _repository;

  const SaveNetworkSettingsUseCase(this._repository);

  /// تنفيذ UseCase
  Future<void> call(NetworkSettingsEntity settings) async {
    await _repository.saveSettings(settings);
  }
}
