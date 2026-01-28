import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import 'sync_providers.dart';

/// State for sync notifier (renamed to avoid conflict with domain SyncState)
class SyncNotifierState {
  final SyncStatusEntity status;
  final TerminalConfigEntity? config;
  final bool isInitialized;
  final String? error;

  const SyncNotifierState({
    this.status = const SyncStatusEntity(),
    this.config,
    this.isInitialized = false,
    this.error,
  });

  SyncNotifierState copyWith({
    SyncStatusEntity? status,
    TerminalConfigEntity? config,
    bool? isInitialized,
    String? error,
  }) {
    return SyncNotifierState(
      status: status ?? this.status,
      config: config ?? this.config,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

/// StateNotifier for sync operations
class SyncNotifier extends StateNotifier<SyncNotifierState> {
  final Ref _ref;

  SyncNotifier(this._ref) : super(const SyncNotifierState());

  /// Initialize sync based on terminal configuration
  Future<void> initialize() async {
    final useCase = _ref.read(initializeSyncUseCaseProvider);
    final result = await useCase();

    result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message,
          isInitialized: false,
        );
      },
      (status) {
        state = state.copyWith(
          status: status,
          isInitialized: true,
        );
      },
    );

    // Load config
    final configResult =
        await _ref.read(syncRepositoryProvider).getTerminalConfig();
    configResult.fold(
      (_) {},
      (config) {
        state = state.copyWith(config: config);
      },
    );
  }

  /// Setup terminal as master
  Future<bool> setupAsMaster({required String name}) async {
    final useCase = _ref.read(setupTerminalUseCaseProvider);

    final result = await useCase(SetupTerminalParams(
      type: TerminalType.master,
      name: name,
    ));

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (config) {
        state = state.copyWith(config: config, error: null);
        _ref.invalidate(terminalConfigProvider);
        return true;
      },
    );
  }

  /// Setup terminal as cashier
  Future<bool> setupAsCashier({
    required String name,
    required String masterIp,
    int masterPort = 8080,
  }) async {
    final useCase = _ref.read(setupTerminalUseCaseProvider);

    final result = await useCase(SetupTerminalParams(
      type: TerminalType.cashier,
      name: name,
      masterIp: masterIp,
      masterPort: masterPort,
    ));

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (config) {
        state = state.copyWith(config: config, error: null);
        _ref.invalidate(terminalConfigProvider);
        return true;
      },
    );
  }

  /// Perform manual sync
  Future<SyncResultEntity?> syncNow() async {
    if (state.status.isSyncing) return null;

    final useCase = _ref.read(syncNowUseCaseProvider);
    final result = await useCase();

    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message,
          status: state.status.copyWith(
            state: SyncState.failed,
            errorMessage: failure.message,
          ),
        );
        return null;
      },
      (syncResult) {
        state = state.copyWith(
          error: null,
          status: state.status.copyWith(
            state: SyncState.completed,
            lastSuccessfulSync: syncResult.completedAt,
          ),
        );
        return syncResult;
      },
    );
  }

  /// Discover master server on network
  Future<DiscoveryResultEntity?> discoverServer({
    void Function(int current, int total)? onProgress,
  }) async {
    final useCase = _ref.read(discoverServerUseCaseProvider);
    final result = await useCase(onProgress: onProgress);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return null;
      },
      (discovery) {
        state = state.copyWith(error: null);
        return discovery;
      },
    );
  }

  /// Enqueue a sale for sync
  Future<bool> enqueueSale({
    required String saleId,
    required Map<String, dynamic> saleData,
  }) async {
    final useCase = _ref.read(enqueueSaleUseCaseProvider);
    final result = await useCase(saleId: saleId, saleData: saleData);

    return result.isRight;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for SyncNotifier
final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, SyncNotifierState>((ref) {
  return SyncNotifier(ref);
});
