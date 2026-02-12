// lib/features/purchases/presentation/screens/supplier_returns_screen.dart
// Direct Drift implementation - No wrappers!

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/database_provider.dart';
import '../providers/purchases_drift_providers.dart';
import '../../data/models/supplier_return.dart';

/// Provider for supplier returns using Drift directly
final supplierReturnsProvider =
    FutureProvider<List<SupplierReturn>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final entries = await (db.select(db.supplierReturns)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  return entries.map(_toModel).toList();
});

/// Convert Drift entry to model
SupplierReturn _toModel(SupplierReturnEntry e) {
  return SupplierReturn(
    id: e.id,
    supplierId: e.supplierId,
    invoiceId: e.invoiceId,
    productId: e.productId,
    quantity: e.quantity,
    amount: e.amount,
    status: e.status,
    deliveredDate: e.deliveredDate,
    notes: e.notes,
    createdAt: e.createdAt,
  );
}

/// Supplier returns management screen
class SupplierReturnsScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const SupplierReturnsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<SupplierReturnsScreen> createState() =>
      _SupplierReturnsScreenState();
}

class _SupplierReturnsScreenState extends ConsumerState<SupplierReturnsScreen> {
  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(supplierReturnsProvider);
    final suppliers = ref.watch(activeSuppliersProvider);

    if (widget.embedded) {
      return returnsAsync.when(
        data: (returns) => _buildEmbeddedContent(returns, suppliers),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مرتجعات الموردين',
            style: TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(supplierReturnsProvider),
          ),
        ],
      ),
      body: returnsAsync.when(
        data: (returns) => _buildContent(returns, suppliers),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReturnDialog(suppliers),
        icon: const Icon(Icons.add),
        label:
            const Text('إضافة مرتجع', style: TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmbeddedContent(List<SupplierReturn> returns,
      AsyncValue<List<SupplierDisplayItem>> suppliers) {
    if (returns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_return_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مرتجعات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddReturnDialog(suppliers),
              icon: const Icon(Icons.add),
              label: const Text('إضافة مرتجع',
                  style: TextStyle(fontFamily: 'Tajawal')),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    final prepared = returns.where((r) => r.isPrepared).toList();
    final delivered = returns.where((r) => r.isDelivered).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddReturnDialog(suppliers),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة مرتجع',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'جاهزة: ${prepared.length}',
                  style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'مُسلّمة: ${delivered.length}',
                  style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: returns.length,
            itemBuilder: (context, index) {
              final returnItem = returns[index];
              return _buildReturnCard(returnItem, returnItem.isPrepared);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent(List<SupplierReturn> returns,
      AsyncValue<List<SupplierDisplayItem>> suppliers) {
    if (returns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_return_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مرتجعات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    final prepared = returns.where((r) => r.isPrepared).toList();
    final delivered = returns.where((r) => r.isDelivered).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(
                  fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'جاهزة للتسليم (${prepared.length})'),
                Tab(text: 'تم التسليم (${delivered.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildReturnsList(prepared, isPrepared: true),
                _buildReturnsList(delivered, isPrepared: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnsList(List<SupplierReturn> returns,
      {required bool isPrepared}) {
    if (returns.isEmpty) {
      return Center(
        child: Text(
          isPrepared ? 'لا توجد مرتجعات جاهزة' : 'لا توجد مرتجعات مُسلّمة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: returns.length,
      itemBuilder: (context, index) {
        final returnItem = returns[index];
        return _buildReturnCard(returnItem, isPrepared);
      },
    );
  }

  Widget _buildReturnCard(SupplierReturn returnItem, bool isPrepared) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          right: BorderSide(
            color: isPrepared ? Colors.orange : Colors.green,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPrepared ? Colors.orange : Colors.green)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPrepared ? Icons.hourglass_empty : Icons.check_circle,
              color: isPrepared ? Colors.orange : Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'منتج: ${returnItem.productId}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الكمية: ${returnItem.quantity.toInt()} | المبلغ: ${NumberFormat('#,###').format(returnItem.amount)} د.ع',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  DateFormat('yyyy/MM/dd').format(returnItem.createdAt),
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (isPrepared)
            ElevatedButton.icon(
              onPressed: () => _deliverReturn(returnItem),
              icon: const Icon(Icons.local_shipping, size: 16),
              label: const Text('تسليم',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _deliverReturn(SupplierReturn returnItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد التسليم',
            style: TextStyle(fontFamily: 'Tajawal')),
        content: const Text(
          'سيتم خصم الكمية من المخزون وتقليل دين المورد.\nهل أنت متأكد؟',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تأكيد',
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final db = ref.read(appDatabaseProvider);
      await _performDeliverReturn(db, returnItem);

      ref.invalidate(supplierReturnsProvider);

      if (mounted) {
        AppToast.success(context, 'تم تسليم المرتجع بنجاح');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'خطأ: $e');
      }
    }
  }

  /// Perform the deliver return operation using Drift directly
  Future<void> _performDeliverReturn(
      AppDatabase db, SupplierReturn returnItem) async {
    await db.transaction(() async {
      // 1. Update return status
      await (db.update(db.supplierReturns)
            ..where((t) => t.id.equals(returnItem.id)))
          .write(SupplierReturnsCompanion(
        status: const Value('delivered'),
        deliveredDate: Value(DateTime.now()),
      ));

      // 2. Decrease product stock
      final product = await (db.select(db.products)
            ..where((p) => p.id.equals(returnItem.productId)))
          .getSingleOrNull();

      if (product != null) {
        final newStock = product.currentStock - returnItem.quantity;
        await (db.update(db.products)
              ..where((p) => p.id.equals(returnItem.productId)))
            .write(ProductsCompanion(
          currentStock: Value(newStock > 0 ? newStock : 0),
          updatedAt: Value(DateTime.now()),
        ));
      }

      // 3. Add stock movement
      await db.into(db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: const Uuid().v4(),
              productId: returnItem.productId,
              referenceType: 'supplier_return',
              referenceId: returnItem.id,
              quantity: -returnItem.quantity,
              notes: const Value('مرتجع للمورد'),
              createdAt: DateTime.now(),
            ),
          );

      // 4. Update supplier balance (decrease debt)
      final lastLedger = await (db.select(db.supplierLedger)
            ..where((l) => l.supplierId.equals(returnItem.supplierId))
            ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
            ..limit(1))
          .getSingleOrNull();

      final currentBalance = lastLedger?.balanceAfter ?? 0.0;
      final newBalance = currentBalance - returnItem.amount;

      await db.into(db.supplierLedger).insert(
            SupplierLedgerCompanion.insert(
              id: const Uuid().v4(),
              supplierId: returnItem.supplierId,
              referenceId: returnItem.id,
              referenceType: 'return',
              amount: -returnItem.amount,
              balanceAfter: newBalance,
              description: 'مرتجع للمورد',
              createdAt: DateTime.now(),
            ),
          );
    });
  }

  void _showAddReturnDialog(
      AsyncValue<List<SupplierDisplayItem>> suppliersAsync) {
    String? selectedSupplierId;
    ProductSearchDisplayItem? selectedProduct;
    final quantityController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final productController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة مرتجع جديد',
              style: TextStyle(fontFamily: 'Tajawal')),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Supplier selection
                  suppliersAsync.when(
                    data: (suppliers) => DropdownButtonFormField<String>(
                      initialValue: selectedSupplierId,
                      decoration: InputDecoration(
                        labelText: 'المورد',
                        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: suppliers
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name,
                                    style:
                                        const TextStyle(fontFamily: 'Tajawal')),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedSupplierId = value),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('خطأ في تحميل الموردين'),
                  ),

                  const SizedBox(height: 16),

                  // Product search
                  TextField(
                    controller: productController,
                    decoration: InputDecoration(
                      labelText: 'اسم المنتج',
                      labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal'),
                    onChanged: (value) {
                      if (value.length >= 2) {
                        ref
                            .read(productSearchDriftProvider.notifier)
                            .search(value);
                      }
                    },
                  ),

                  // Search results
                  Consumer(
                    builder: (context, ref, _) {
                      final searchState = ref.watch(productSearchDriftProvider);
                      if (searchState.results.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchState.results.length,
                          itemBuilder: (context, index) {
                            final product = searchState.results[index];
                            return ListTile(
                              title: Text(product.name,
                                  style: const TextStyle(
                                      fontFamily: 'Tajawal', fontSize: 14)),
                              dense: true,
                              onTap: () {
                                setDialogState(() {
                                  selectedProduct = product;
                                  productController.text = product.name;
                                });
                                ref
                                    .read(productSearchDriftProvider.notifier)
                                    .clear();
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Quantity
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'الكمية',
                      labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),

                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedSupplierId == null || selectedProduct == null) {
                  AppToast.warning(context, 'الرجاء اختيار المورد والمنتج');
                  return;
                }

                final quantity = double.tryParse(quantityController.text) ?? 0;
                final amount = double.tryParse(amountController.text) ?? 0;

                if (quantity <= 0 || amount <= 0) {
                  AppToast.warning(context, 'الرجاء إدخال كمية ومبلغ صحيحين');
                  return;
                }

                final navigator = Navigator.of(context);
                final dialogContext = context;

                try {
                  final db = ref.read(appDatabaseProvider);
                  await db.into(db.supplierReturns).insert(
                        SupplierReturnsCompanion.insert(
                          id: const Uuid().v4(),
                          supplierId: selectedSupplierId!,
                          productId: selectedProduct!.id,
                          quantity: quantity,
                          amount: amount,
                          status: const Value('prepared'),
                          notes: Value(notesController.text.isNotEmpty
                              ? notesController.text
                              : null),
                          createdAt: DateTime.now(),
                        ),
                      );

                  ref.invalidate(supplierReturnsProvider);
                  if (dialogContext.mounted) {
                    navigator.pop();
                    AppToast.success(dialogContext, 'تم إضافة المرتجع بنجاح');
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    AppToast.error(dialogContext, 'خطأ: $e');
                  }
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('حفظ',
                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
