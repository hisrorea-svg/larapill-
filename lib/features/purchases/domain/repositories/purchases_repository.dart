import '../../domain/usecases/get_dashboard_stats_usecase.dart';
import '../../data/models/supplier_item.dart';
import '../../data/models/supplier_ledger_entry.dart';

/// 📦 Repository for managing all things related to Purchases and Suppliers
abstract class PurchasesRepository {
  /// 📊 Get dashboard statistics
  Future<DashboardStats> getDashboardStats();

  /// 👥 Suppliers
  Future<List<SupplierItem>> getActiveSuppliers();
  Future<SupplierItem?> getSupplierById(String id);

  /// 💰 Ledger & Payments
  Future<double> getSupplierBalance(String supplierId);
  Future<List<SupplierLedgerEntry>> getSupplierLedger(String supplierId);
  Future<void> createPayment({
    required String supplierId,
    required double amount,
    String paymentMethod = 'cash',
    String? notes,
  });

  Future<void> createOrder(
    String supplierId,
    List<dynamic> items, {
    String status = 'draft',
    String? notes,
  });

  Future<void> receiveOrder(String orderId, List<dynamic> items);
}
