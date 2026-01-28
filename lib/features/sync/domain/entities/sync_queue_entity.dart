/// Sync queue item status
enum SyncQueueStatus {
  /// Waiting to be synced
  pending,

  /// Successfully synced
  synced,

  /// Failed to sync (will retry)
  failed,
}

/// Type of sync action
enum SyncAction {
  /// New sale to push
  sale,

  /// Sale cancellation
  cancelSale,

  /// Sale return/refund
  returnSale,
}

/// Domain entity representing a queued sync item
class SyncQueueEntity {
  /// Unique item identifier
  final String id;

  /// Type of action
  final SyncAction action;

  /// Sale ID being synced
  final String saleId;

  /// Full sale data as JSON
  final Map<String, dynamic> payload;

  /// Current sync status
  final SyncQueueStatus status;

  /// Number of sync attempts
  final int retryCount;

  /// Error message if failed
  final String? errorMessage;

  /// When this item was queued
  final DateTime createdAt;

  /// When this item was last updated
  final DateTime updatedAt;

  const SyncQueueEntity({
    required this.id,
    required this.action,
    required this.saleId,
    required this.payload,
    this.status = SyncQueueStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this item is pending
  bool get isPending => status == SyncQueueStatus.pending;

  /// Whether this item has failed
  bool get isFailed => status == SyncQueueStatus.failed;

  /// Whether this item was synced
  bool get isSynced => status == SyncQueueStatus.synced;

  /// Whether max retries reached (5 attempts)
  bool get maxRetriesReached => retryCount >= 5;

  /// Create a copy with updated fields
  SyncQueueEntity copyWith({
    String? id,
    SyncAction? action,
    String? saleId,
    Map<String, dynamic>? payload,
    SyncQueueStatus? status,
    int? retryCount,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncQueueEntity(
      id: id ?? this.id,
      action: action ?? this.action,
      saleId: saleId ?? this.saleId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SyncQueueEntity(id: $id, action: $action, status: $status)';
}
