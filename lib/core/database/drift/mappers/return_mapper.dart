import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../../features/returns/domain/entities/return_entity.dart'
    as domain;
import '../../../../core/models/shared/medicine_unit.dart';

/// 🔄 Mapper for Return entities
class ReturnMapper {
  /// Convert domain Return to Drift Companion
  static ReturnsCompanion toCompanion(domain.Return return_) {
    return ReturnsCompanion.insert(
      id: return_.id,
      saleId: return_.saleId,
      returnDate: return_.returnDate,
      reason: return_.reason.name,
      status: Value(return_.status.name),
      totalRefund: return_.totalRefund,
      refundMethod: return_.refundMethod.name,
      notes: Value(return_.notes),
      processedBy: return_.processedBy,
      createdAt: return_.createdAt,
    );
  }

  /// Convert domain ReturnItem to Drift Companion
  static ReturnItemsCompanion toItemCompanion(
      String returnId, domain.ReturnItem item) {
    return ReturnItemsCompanion.insert(
      id: item.id,
      returnId: returnId,
      productId: item.productId,
      productName: item.productName,
      unit: item.unit.name,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      total: item.total,
      reasonDetails: Value(item.reasonDetails),
      batchNumber: Value(item.batchNumber),
      expiryDate: Value(item.expiryDate),
    );
  }

  /// Convert Drift Entry to domain Return
  static domain.Return fromEntry(
      ReturnEntry entry, List<ReturnItemEntry> itemEntries) {
    return domain.Return(
      id: entry.id,
      saleId: entry.saleId,
      returnDate: entry.returnDate,
      items: itemEntries.map(fromItemEntry).toList(),
      reason:
          domain.ReturnReason.values.firstWhere((e) => e.name == entry.reason),
      status:
          domain.ReturnStatus.values.firstWhere((e) => e.name == entry.status),
      totalRefund: entry.totalRefund,
      refundMethod: domain.RefundMethod.values
          .firstWhere((e) => e.name == entry.refundMethod),
      notes: entry.notes,
      processedBy: entry.processedBy,
      createdAt: entry.createdAt,
    );
  }

  /// Convert Drift Item Entry to domain ReturnItem
  static domain.ReturnItem fromItemEntry(ReturnItemEntry entry) {
    return domain.ReturnItem(
      id: entry.id,
      productId: entry.productId,
      productName: entry.productName,
      unit: MedicineUnit.values.firstWhere((e) => e.name == entry.unit),
      quantity: entry.quantity,
      unitPrice: entry.unitPrice,
      total: entry.total,
      reasonDetails: entry.reasonDetails,
      batchNumber: entry.batchNumber,
      expiryDate: entry.expiryDate,
    );
  }
}
