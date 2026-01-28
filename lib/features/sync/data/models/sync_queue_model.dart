import 'dart:convert';
import '../../domain/entities/entities.dart';

/// Data model for sync queue item (database/JSON)
class SyncQueueModel {
  final String id;
  final String action;
  final String saleId;
  final String payload;
  final String status;
  final int retryCount;
  final String? errorMessage;
  final String createdAt;
  final String updatedAt;

  const SyncQueueModel({
    required this.id,
    required this.action,
    required this.saleId,
    required this.payload,
    this.status = 'pending',
    this.retryCount = 0,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from database map
  factory SyncQueueModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueModel(
      id: map['id'] as String? ?? '',
      action: map['action'] as String? ?? 'sale',
      saleId: map['sale_id'] as String? ?? '',
      payload: map['payload'] as String? ?? '{}',
      status: map['status'] as String? ?? 'pending',
      retryCount: map['retry_count'] as int? ?? 0,
      errorMessage: map['error_message'] as String?,
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'sale_id': saleId,
      'payload': payload,
      'status': status,
      'retry_count': retryCount,
      'error_message': errorMessage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Convert to domain entity
  SyncQueueEntity toEntity() {
    return SyncQueueEntity(
      id: id,
      action: _parseAction(action),
      saleId: saleId,
      payload: jsonDecode(payload) as Map<String, dynamic>,
      status: _parseStatus(status),
      retryCount: retryCount,
      errorMessage: errorMessage,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  /// Create from domain entity
  factory SyncQueueModel.fromEntity(SyncQueueEntity entity) {
    return SyncQueueModel(
      id: entity.id,
      action: entity.action.name,
      saleId: entity.saleId,
      payload: jsonEncode(entity.payload),
      status: entity.status.name,
      retryCount: entity.retryCount,
      errorMessage: entity.errorMessage,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  SyncAction _parseAction(String action) {
    switch (action) {
      case 'sale':
        return SyncAction.sale;
      case 'cancelSale':
        return SyncAction.cancelSale;
      case 'returnSale':
        return SyncAction.returnSale;
      default:
        return SyncAction.sale;
    }
  }

  SyncQueueStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return SyncQueueStatus.pending;
      case 'synced':
        return SyncQueueStatus.synced;
      case 'failed':
        return SyncQueueStatus.failed;
      default:
        return SyncQueueStatus.pending;
    }
  }
}
