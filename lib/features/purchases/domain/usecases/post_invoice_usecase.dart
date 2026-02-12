import '../repositories/purchases_repository.dart';
import '../helpers/cost_calculator.dart';

/// بند فاتورة للترحيل
class InvoiceItem {
  final String? productId;
  final String productName;
  final double quantity;
  final double bonus;
  final double purchasePrice;
  final String? expiryDate;
  final double? oldCost;

  const InvoiceItem({
    this.productId,
    required this.productName,
    required this.quantity,
    required this.bonus,
    required this.purchasePrice,
    this.expiryDate,
    this.oldCost,
  });

  /// التكلفة لكل وحدة
  double get costPerUnit => CostCalculator.calculateCostPerUnit(
        purchasePrice: purchasePrice,
        quantity: quantity,
        bonus: bonus,
      );

  /// إجمالي الكمية (مع البونص)
  double get totalQuantity => quantity + bonus;
}

/// نتيجة ترحيل الفاتورة
class PostInvoiceResult {
  final String orderId;
  final bool success;
  final String? error;
  final double totalAmount;
  final int itemsCount;
  final List<String> warnings;

  const PostInvoiceResult({
    required this.orderId,
    required this.success,
    this.error,
    required this.totalAmount,
    required this.itemsCount,
    this.warnings = const [],
  });

  factory PostInvoiceResult.success({
    required String orderId,
    required double totalAmount,
    required int itemsCount,
    List<String> warnings = const [],
  }) {
    return PostInvoiceResult(
      orderId: orderId,
      success: true,
      totalAmount: totalAmount,
      itemsCount: itemsCount,
      warnings: warnings,
    );
  }

  factory PostInvoiceResult.failure({
    required String error,
    String orderId = '',
  }) {
    return PostInvoiceResult(
      orderId: orderId,
      success: false,
      error: error,
      totalAmount: 0,
      itemsCount: 0,
    );
  }
}

/// Use Case: ترحيل فاتورة شراء
class PostInvoiceUseCase {
  final PurchasesRepository _repository;

  PostInvoiceUseCase({
    required PurchasesRepository repository,
  }) : _repository = repository;

  /// تنفيذ الترحيل
  Future<PostInvoiceResult> execute({
    required String supplierId,
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required String createdBy,
    String? notes,
  }) async {
    try {
      if (items.isEmpty) {
        return PostInvoiceResult.failure(error: 'الفاتورة فارغة');
      }

      final warnings = <String>[];
      for (final item in items) {
        if (item.productId == null) {
          warnings.add('${item.productName}: منتج غير مسجل');
        }
        if (item.oldCost != null && item.oldCost! > 0) {
          final changePercent = CostCalculator.calculatePriceChangePercent(
            oldPrice: item.oldCost!,
            newPrice: item.costPerUnit,
          );
          if (CostCalculator.hasSignificantPriceChange(
            oldPrice: item.oldCost!,
            newPrice: item.costPerUnit,
          )) {
            warnings.add(
              '${item.productName}: تغير سعر ${changePercent > 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
            );
          }
        }
      }

      final totalAmount = items.fold<double>(
        0,
        (sum, item) => sum + item.purchasePrice,
      );

      // We'll bridge this to repository
      // Assuming repository has a method for this, or we add one
      await _repository.createOrder(
        supplierId,
        items,
        notes: notes ?? 'فاتورة $invoiceNumber',
      );

      return PostInvoiceResult.success(
        orderId: 'NEW_ORDER', // Temporary
        totalAmount: totalAmount,
        itemsCount: items.length,
        warnings: warnings,
      );
    } catch (e) {
      return PostInvoiceResult.failure(error: e.toString());
    }
  }
}
