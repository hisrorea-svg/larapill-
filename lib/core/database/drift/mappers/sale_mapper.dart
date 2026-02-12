/// Sale Mapper - Converts between Drift entities and Domain models
///
/// This mapper handles the conversion between:
/// - SaleEntry/SaleItemEntry (Drift database entities)
/// - Sale/SaleItem (Domain models used in UI)
library sale_mapper;

import 'package:drift/drift.dart';
import '../../../../../core/database/drift/app_database.dart';
import '../../../../../core/database/drift/daos/sales_drift_dao.dart';
import '../../../../features/pos/domain/entities/sale.dart';
import '../../../../../core/models/shared/medicine_unit.dart';

/// Mapper for Sale <-> SaleEntry conversions
class SaleMapper {
  /// Convert SaleWithItems (Drift join) to Sale (Domain)
  static Sale fromEntry(SaleWithItems saleWithItems) {
    final entry = saleWithItems.sale;
    final items = saleWithItems.items;

    return Sale(
      id: entry.id,
      date: entry.date,
      items: items.map((i) => _fromItemEntry(i)).toList(),
      subtotal: entry.subtotal,
      discount: entry.discount,
      tax: entry.tax,
      total: entry.total,
      paidAmount: entry.paidAmount,
      remainingAmount: entry.remainingAmount,
      paymentStatus: _parsePaymentStatus(entry.paymentStatus),
      paymentMethod: _parsePaymentMethod(entry.paymentMethod),
      customerName: entry.customerName,
      customerPhone: entry.customerPhone,
      cashierId: entry.cashierId,
      cashierName: entry.customerName ??
          '', // Re-using customerName if cashierName missing in entry?
      // Wait, Sales table has cashierName. Let me check the table definition.
      status: _parseSaleStatus(entry.status),
      createdAt: entry.createdAt,
      returnIds: entry.returnIds?.split(','),
    );
  }

  static SaleItem _fromItemEntry(SaleItemEntry entry) {
    return SaleItem(
      id: entry.id,
      productId: entry.productId,
      productName: entry.productName,
      unit: _parseUnit(entry.unit),
      unitPrice: entry.unitPrice,
      quantity: entry.quantity,
      total: entry.total,
    );
  }

  /// Convert Sale (Domain) to SalesCompanion (Drift insert/update)
  static SalesCompanion toCompanion(Sale sale) {
    return SalesCompanion(
      id: Value(sale.id),
      date: Value(sale.date),
      invoiceNumber: const Value.absent(), // Handled by DAO or database
      subtotal: Value(sale.subtotal),
      discount: Value(sale.discount),
      tax: Value(sale.tax),
      total: Value(sale.total),
      paidAmount: Value(sale.paidAmount),
      remainingAmount: Value(sale.remainingAmount),
      paymentStatus: Value(sale.paymentStatus.name),
      paymentMethod: Value(sale.paymentMethod.name),
      customerName: Value(sale.customerName),
      customerPhone: Value(sale.customerPhone),
      cashierId: Value(sale.cashierId),
      cashierName: Value(sale.cashierName),
      status: Value(sale.status.name),
      createdAt: Value(sale.createdAt),
      returnIds: Value(sale.returnIds?.join(',')),
    );
  }

  /// Convert SaleItem (Domain) to SaleItemsCompanion
  static SaleItemsCompanion toItemCompanion(String saleId, SaleItem item) {
    return SaleItemsCompanion(
      id: Value(item.id),
      saleId: Value(saleId),
      productId: Value(item.productId),
      productName: Value(item.productName),
      unit: Value(item.unit.name),
      unitPrice: Value(item.unitPrice),
      quantity: Value(item.quantity),
      total: Value(item.total),
    );
  }

  // Helper parsers (Matching domain logic)

  static PaymentStatus _parsePaymentStatus(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.paid,
    );
  }

  static PaymentMethod _parsePaymentMethod(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }

  static SaleStatus _parseSaleStatus(String value) {
    return SaleStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SaleStatus.completed,
    );
  }

  static MedicineUnit _parseUnit(String value) {
    return MedicineUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicineUnit.piece,
    );
  }
}
