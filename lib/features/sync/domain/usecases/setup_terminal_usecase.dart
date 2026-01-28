import 'package:uuid/uuid.dart';

import '../entities/entities.dart';
import '../failures/failures.dart';
import '../repositories/sync_repository.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';

/// Parameters for setting up terminal
class SetupTerminalParams {
  final TerminalType type;
  final String name;
  final String? masterIp;
  final int masterPort;

  const SetupTerminalParams({
    required this.type,
    required this.name,
    this.masterIp,
    this.masterPort = 8080,
  });
}

/// Use case for setting up terminal as master or cashier
class SetupTerminalUseCase {
  final SyncRepository _repository;

  const SetupTerminalUseCase(this._repository);

  /// Execute the use case
  /// Configures terminal as master or cashier
  Future<Either<SyncFailure, TerminalConfigEntity>> call(
      SetupTerminalParams params) async {
    // Validate input
    if (params.name.isEmpty) {
      return const Either.left(
          ConfigurationFailure('اسم الجهاز لا يمكن أن يكون فارغاً'));
    }

    final masterIp = params.masterIp;
    if (params.type == TerminalType.cashier &&
        (masterIp == null || masterIp.isEmpty)) {
      return const Either.left(
          ConfigurationFailure('عنوان IP للـ Master مطلوب للكاشير'));
    }

    // Validate IP format for cashier
    if (params.type == TerminalType.cashier && masterIp != null) {
      final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      if (!ipRegex.hasMatch(masterIp)) {
        return const Either.left(ConfigurationFailure('صيغة IP غير صحيحة'));
      }
    }

    // Create configuration
    final config = TerminalConfigEntity(
      terminalId: const Uuid().v4(),
      name: params.name,
      type: params.type,
      masterIp: params.masterIp ?? '',
      masterPort: params.masterPort,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save configuration
    final saveResult = await _repository.saveTerminalConfig(config);

    return saveResult.fold(
      (failure) => Either.left(failure),
      (_) => Either.right(config),
    );
  }
}
