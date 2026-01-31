import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/datasources/local/suppliers_dao.dart';
import '../../data/datasources/local/supplier_returns_dao.dart';
import '../../data/datasources/local/product_search_dao.dart';
import '../../data/models/supplier_return.dart';

/// Provider للمرتجعات
final supplierReturnsProvider =
    FutureProvider<List<SupplierReturn>>((ref) async {
  final dao = SupplierReturnsDao();
  return dao.getAllReturns();
});

/// شاشة إدارة مرتجعات الموردين
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
    final suppliers = ref.watch(suppliersProvider);

    // إذا كان مضمّن، نعرض المحتوى فقط
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

  Widget _buildEmbeddedContent(
      List<SupplierReturn> returns, AsyncValue<List<SupplierItem>> suppliers) {
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
        // زر إضافة
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
        // القائمة
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

  Widget _buildContent(
      List<SupplierReturn> returns, AsyncValue<List<SupplierItem>> suppliers) {
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

    // تجميع حسب الحالة
    final prepared = returns.where((r) => r.isPrepared).toList();
    final delivered = returns.where((r) => r.isDelivered).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // التبويبات
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

          // المحتوى
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
          // أيقونة الحالة
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

          // التفاصيل
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

          // زر التسليم
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
      final dao = SupplierReturnsDao();
      await dao.deliverReturn(returnItem.id);

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

  void _showAddReturnDialog(AsyncValue<List<SupplierItem>> suppliersAsync) {
    String? selectedSupplierId;
    ProductSearchItem? selectedProduct;
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
                  // اختيار المورد
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

                  // بحث المنتج
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
                        ref.read(productSearchProvider.notifier).search(value);
                      }
                    },
                  ),

                  // نتائج البحث
                  Consumer(
                    builder: (context, ref, _) {
                      final searchState = ref.watch(productSearchProvider);
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
                                    .read(productSearchProvider.notifier)
                                    .clearSelection();
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // الكمية
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

                  // المبلغ
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

                  // ملاحظات
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

                // Capture navigator before async gap
                final navigator = Navigator.of(context);
                final dialogContext = context;

                try {
                  final dao = SupplierReturnsDao();
                  await dao.createReturn(
                    supplierId: selectedSupplierId!,
                    productId: selectedProduct!.id.toString(),
                    productName: selectedProduct!.name,
                    quantity: quantity,
                    amount: amount,
                    notes: notesController.text.isNotEmpty
                        ? notesController.text
                        : null,
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
