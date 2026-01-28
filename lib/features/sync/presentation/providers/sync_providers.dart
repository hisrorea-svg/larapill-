import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../../data/data.dart';

// ============ Repository Providers ============

/// Provider for SyncRepository
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepositoryImpl();
});

// ============ Use Case Providers ============

/// Provider for InitializeSyncUseCase
final initializeSyncUseCaseProvider = Provider<InitializeSyncUseCase>((ref) {
  return InitializeSyncUseCase(ref.watch(syncRepositoryProvider));
});

/// Provider for SyncNowUseCase
final syncNowUseCaseProvider = Provider<SyncNowUseCase>((ref) {
  return SyncNowUseCase(ref.watch(syncRepositoryProvider));
});

/// Provider for EnqueueSaleUseCase
final enqueueSaleUseCaseProvider = Provider<EnqueueSaleUseCase>((ref) {
  return EnqueueSaleUseCase(ref.watch(syncRepositoryProvider));
});

/// Provider for DiscoverServerUseCase
final discoverServerUseCaseProvider = Provider<DiscoverServerUseCase>((ref) {
  return DiscoverServerUseCase(ref.watch(syncRepositoryProvider));
});

/// Provider for SetupTerminalUseCase
final setupTerminalUseCaseProvider = Provider<SetupTerminalUseCase>((ref) {
  return SetupTerminalUseCase(ref.watch(syncRepositoryProvider));
});

/// Provider for PushSalesUseCase
final pushSalesUseCaseProvider = Provider<PushSalesUseCase>((ref) {
  return PushSalesUseCase(ref.watch(syncRepositoryProvider));
});

// ============ State Providers ============

/// Provider for terminal configuration
final terminalConfigProvider =
    FutureProvider<TerminalConfigEntity?>((ref) async {
  final repository = ref.watch(syncRepositoryProvider);
  final result = await repository.getTerminalConfig();

  return result.fold(
    (failure) => null,
    (config) => config,
  );
});

/// Provider to check if this is the master terminal
final isMasterProvider = FutureProvider<bool>((ref) async {
  final config = await ref.watch(terminalConfigProvider.future);
  return config?.isMaster ?? false;
});

/// Provider to check if this is a cashier terminal
final isCashierProvider = FutureProvider<bool>((ref) async {
  final config = await ref.watch(terminalConfigProvider.future);
  return config?.isCashier ?? false;
});

/// Provider for pending sales count
final pendingSalesCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return repository.watchPendingSalesCount();
});

/// Provider for connection status
final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return repository.watchConnectionStatus();
});

/// Provider for sync status
final syncStatusProvider = StreamProvider<SyncStatusEntity>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return repository.watchSyncStatus();
});

// ============ Convenience Providers ============

/// Provider to check if sync is connected
final isSyncConnectedProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(connectionStatusProvider);
  return statusAsync.whenOrNull(
        data: (status) => status == ConnectionStatus.connected,
      ) ??
      false;
});

/// Provider for last sync time
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final statusAsync = ref.watch(syncStatusProvider);
  return statusAsync.whenOrNull(
    data: (status) => status.lastSuccessfulSync,
  );
});

/// Provider to check if sync is currently in progress
final isSyncingProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(syncStatusProvider);
  return statusAsync.whenOrNull(
        data: (status) => status.isSyncing,
      ) ??
      false;
});
