/// Current state of the sync process
enum SyncState {
  /// Not actively syncing
  idle,

  /// General sync in progress
  syncing,

  /// Pushing local sales to master
  pushing,

  /// Pulling products from master
  pulling,

  /// Downloading full product snapshot
  downloadingSnapshot,

  /// Sync completed successfully
  completed,

  /// Sync failed with error
  failed,
}

/// Connection status to master server
enum ConnectionStatus {
  /// Successfully connected
  connected,

  /// Attempting to connect
  connecting,

  /// Not connected
  disconnected,

  /// Connection error
  error,
}

/// Domain entity representing current sync status
class SyncStatusEntity {
  /// Current sync state
  final SyncState state;

  /// Whether connected to master
  final bool isConnected;

  /// Number of pending sales in queue
  final int pendingSalesCount;

  /// Human-readable status message
  final String statusMessage;

  /// Last successful sync time
  final DateTime? lastSuccessfulSync;

  /// Error message if failed
  final String? errorMessage;

  const SyncStatusEntity({
    this.state = SyncState.idle,
    this.isConnected = false,
    this.pendingSalesCount = 0,
    this.statusMessage = '',
    this.lastSuccessfulSync,
    this.errorMessage,
  });

  /// Initial status
  static const initial = SyncStatusEntity(
    statusMessage: 'جاري التهيئة...',
  );

  /// Whether currently syncing
  bool get isSyncing =>
      state == SyncState.syncing ||
      state == SyncState.pushing ||
      state == SyncState.pulling ||
      state == SyncState.downloadingSnapshot;

  /// Whether has pending sales
  bool get hasPendingSales => pendingSalesCount > 0;

  /// Current connection status
  ConnectionStatus get connectionStatus {
    if (isConnected) return ConnectionStatus.connected;
    if (errorMessage != null) return ConnectionStatus.error;
    return ConnectionStatus.disconnected;
  }

  /// Create a copy with updated fields
  SyncStatusEntity copyWith({
    SyncState? state,
    bool? isConnected,
    int? pendingSalesCount,
    String? statusMessage,
    DateTime? lastSuccessfulSync,
    String? errorMessage,
  }) {
    return SyncStatusEntity(
      state: state ?? this.state,
      isConnected: isConnected ?? this.isConnected,
      pendingSalesCount: pendingSalesCount ?? this.pendingSalesCount,
      statusMessage: statusMessage ?? this.statusMessage,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() =>
      'SyncStatusEntity(state: $state, connected: $isConnected, pending: $pendingSalesCount)';
}
