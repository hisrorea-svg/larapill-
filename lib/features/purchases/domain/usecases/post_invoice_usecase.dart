import '../../data/datasources/local/purchase_orders_dao.dart';
import '../../data/datasources/local/stock_movements_dao.dart';
import '../../data/datasources/local/supplier_ledger_dao.dart';
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
///
/// المسؤوليات:
/// 1. إنشاء طلب الشراء
/// 2. ترحيل الطلب
/// 3. تحديث المخزون (stock_movements)
/// 4. تسجيل في دفتر الأستاذ (supplier_ledger)
class PostInvoiceUseCase {
  final PurchaseOrdersDao _purchaseOrdersDao;
  final StockMovementsDao _stockMovementsDao;
  final SupplierLedgerDao _supplierLedgerDao;

  PostInvoiceUseCase({
    PurchaseOrdersDao? purchaseOrdersDao,
    StockMovementsDao? stockMovementsDao,
    SupplierLedgerDao? supplierLedgerDao,
  })  : _purchaseOrdersDao = purchaseOrdersDao ?? PurchaseOrdersDao(),
        _stockMovementsDao = stockMovementsDao ?? StockMovementsDao(),
        _supplierLedgerDao = supplierLedgerDao ?? SupplierLedgerDao();

  /// تنفيذ الترحيل
  Future<PostInvoiceResult> execute({
    required String supplierId,
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required String createdBy,
    String? notes,
  }) async {
    try {
      // التحقق من البيانات
      if (items.isEmpty) {
        return PostInvoiceResult.failure(error: 'الفاتورة فارغة');
      }

      // جمع التحذيرات
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

      // تحويل البنود
      final purchaseItems = items
          .map((item) => PurchaseItemData(
                productId: item.productId ?? '',
                productName: item.productName,
                unit: 'قطعة',
                quantity: item.quantity,
                bonus: item.bonus,
                unitPrice: item.purchasePrice / item.quantity,
                expiryDate: item.expiryDate,
              ))
          .toList();

      // 1. إنشاء طلب الشراء
      final orderId = await _purchaseOrdersDao.createDraftOrder(
        supplierId: supplierId,
        invoiceNumber: invoiceNumber,
        items: purchaseItems,
        createdBy: createdBy,
        notes: notes,
      );

      // 2. ترحيل الطلب
      await _purchaseOrdersDao.postOrder(orderId);

      // 3. تحديث المخزون
      for (final item in items) {
        if (item.productId != null) {
          await _stockMovementsDao.addPurchaseMovement(
            productId: item.productId!,
            purchaseOrderId: orderId,
            quantity: item.totalQuantity,
            costPerUnit: item.costPerUnit,
            notes: 'فاتورة $invoiceNumber',
          );
        }
      }

      // 4. تسجيل في دفتر الأستاذ
      final totalAmount = items.fold<double>(
        0,
        (sum, item) => sum + item.purchasePrice,
      );

      await _supplierLedgerDao.addInvoiceEntry(
        supplierId: supplierId,
        invoiceId: orderId,
        amount: totalAmount,
        description: 'فاتورة شراء رقم $invoiceNumber',
      );

      return PostInvoiceResult.success(
        orderId: orderId,
        totalAmount: totalAmount,
        itemsCount: items.length,
        warnings: warnings,
      );
    } catch (e) {
      return PostInvoiceResult.failure(error: e.toString());
    }
  }
}
