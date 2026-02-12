import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/data/repositories/user_service.dart';
import '../providers/purchases_drift_providers.dart';

/// بند في فاتورة الشراء
class InvoiceItemEntry {
  final String id;
  String? productId;
  String productName;
  double quantity;
  double bonus;
  double purchasePrice;
  String? expiryDate;
  double? oldCost; // للـ Price Watchdog

  InvoiceItemEntry({
    String? id,
    this.productId,
    this.productName = '',
    this.quantity = 0,
    this.bonus = 0,
    this.purchasePrice = 0,
    this.expiryDate,
    this.oldCost,
  }) : id = id ?? const Uuid().v4();

  /// التكلفة لكل وحدة (مع البونص)
  double get costPerUnit {
    final totalUnits = quantity + bonus;
    if (totalUnits <= 0) return 0;
    return purchasePrice / totalUnits;
  }

  /// هل السعر تغير عن السابق؟
  bool get hasPriceChange =>
      oldCost != null && oldCost != 0 && (costPerUnit - oldCost!).abs() > 0.1;

  /// نسبة التغير في السعر
  double get priceChangePercent {
    if (oldCost == null || oldCost == 0) return 0;
    return ((costPerUnit - oldCost!) / oldCost!) * 100;
  }
}

/// شاشة الإدخال السريع (Turbo Entry)
class TurboEntryScreen extends ConsumerStatefulWidget {
  final String? supplierId;
  final String? supplierName;
  final bool embedded;

  const TurboEntryScreen({
    super.key,
    this.supplierId,
    this.supplierName,
    this.embedded = false,
  });

  @override
  ConsumerState<TurboEntryScreen> createState() => _TurboEntryScreenState();
}

class _TurboEntryScreenState extends ConsumerState<TurboEntryScreen> {
  final List<InvoiceItemEntry> _items = [];
  final _invoiceNumberController = TextEditingController();
  String? _selectedSupplierId;
  ProductSearchDisplayItem? _selectedProduct;

  // Focus nodes للتنقل بالكيبورد
  final _productFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _bonusFocus = FocusNode();
  final _priceFocus = FocusNode();

  // Controllers للحقول الحالية
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _bonusController = TextEditingController();
  final _priceController = TextEditingController();

  // للـ Autocomplete
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _selectedSupplierId = widget.supplierId;

    // Focus على حقل المنتج عند الفتح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productFocus.requestFocus();
    });

    // الاستماع لتغييرات البحث
    _productController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _productController.text.trim();
    if (query.length >= 2) {
      ref.read(productSearchDriftProvider.notifier).search(query);
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _invoiceNumberController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _bonusController.dispose();
    _priceController.dispose();
    _productFocus.dispose();
    _quantityFocus.dispose();
    _bonusFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(activeSuppliersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(suppliers),

          // حقول الإدخال السريع
          _buildQuickEntryRow(),

          // جدول البنود
          Expanded(child: _buildItemsTable()),

          // Footer مع أزرار الحفظ
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<SupplierDisplayItem>> suppliers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 12),

          // العنوان
          const Text(
            'إدخال سريع',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(width: 24),

          // اختيار المورد
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: suppliers.when(
                data: (list) => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSupplierId,
                    hint: const Text(
                      'اختر المذخر...',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                    isExpanded: true,
                    items: list
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Row(
                                children: [
                                  Text(
                                    s.name,
                                    style:
                                        const TextStyle(fontFamily: 'Tajawal'),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPaymentColor(s.paymentType),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      s.paymentTypeLabel,
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSupplierId = value;
                      });
                    },
                  ),
                ),
                loading: () => const SizedBox(
                  height: 48,
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const Text('خطأ في تحميل الموردين'),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // رقم الفاتورة
          SizedBox(
            width: 150,
            child: TextField(
              controller: _invoiceNumberController,
              decoration: InputDecoration(
                labelText: 'رقم الفاتورة',
                labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),

          const SizedBox(width: 16),

          // زر إغلاق
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Color _getPaymentColor(String type) {
    switch (type) {
      case 'weekly':
        return Colors.orange;
      case 'monthly':
        return Colors.blue;
      case 'credit':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Widget _buildQuickEntryRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withValues(alpha: 0.05),
      child: Row(
        children: [
          // حقل اسم المنتج مع Autocomplete
          Expanded(
            flex: 3, // ✅ الأكبر
            child: CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _productController,
                focusNode: _productFocus,
                decoration: InputDecoration(
                  hintText: 'اسم المنتج أو الباركود...',
                  hintStyle: const TextStyle(fontFamily: 'Tajawal'),
                  filled: true,
                  fillColor: _selectedProduct != null
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: _selectedProduct != null
                        ? const BorderSide(color: Colors.green)
                        : BorderSide.none,
                  ),
                  suffixIcon: _selectedProduct != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearProductSelection,
                        )
                      : null,
                ),
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
                onSubmitted: (_) {
                  _hideOverlay();
                  _quantityFocus.requestFocus();
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // الكمية
          Expanded(
            flex: 2,
            child: TextField(
              controller: _quantityController,
              focusNode: _quantityFocus,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الكمية',
                labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontFamily: 'Tajawal'),
              onSubmitted: (_) => _bonusFocus.requestFocus(),
            ),
          ),

          const SizedBox(width: 12),

          // البونص
          Expanded(
            flex: 2,
            child: TextField(
              controller: _bonusController,
              focusNode: _bonusFocus,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'البونص',
                labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                filled: true,
                fillColor: Colors.green.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.green),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              onSubmitted: (_) => _priceFocus.requestFocus(),
            ),
          ),

          const SizedBox(width: 12),

          // سعر الشراء
          Expanded(
            flex: 2,
            child: TextField(
              controller: _priceController,
              focusNode: _priceFocus,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'سعر الشراء',
                labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontFamily: 'Tajawal'),
              onSubmitted: (_) => _addItem(),
            ),
          ),

          const SizedBox(width: 12),

          // زر إضافة
          ElevatedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text(
              'إضافة',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverlay() {
    _hideOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(productSearchDriftProvider);
                if (state.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state.results.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'لا توجد نتائج',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    final product = state.results[index];
                    return ListTile(
                      title: Text(
                        product.name,
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                      subtitle: Text(
                        'الباركود: ${product.barcode ?? '-'} | المخزون: ${product.currentStock}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        '${product.costPrice}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () => _selectProduct(product),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectProduct(ProductSearchDisplayItem product) {
    setState(() {
      _selectedProduct = product;
      _productController.text = product.name;
      _priceController.text = product.costPrice.toString();
    });
    _hideOverlay();
    _quantityFocus.requestFocus();
  }

  void _clearProductSelection() {
    setState(() {
      _selectedProduct = null;
      _productController.clear();
      _priceController.clear();
    });
    ref.read(productSearchDriftProvider.notifier).clearSelection();
    _productFocus.requestFocus();
  }

  Widget _buildItemsTable() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'ابدأ بإضافة المنتجات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط Enter للتنقل بين الحقول',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildItemRow(item, index);
      },
    );
  }

  Widget _buildItemRow(InvoiceItemEntry item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: item.hasPriceChange
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // الرقم
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // اسم المنتج
          Expanded(
            flex: 3,
            child: Text(
              item.productName,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // الكمية
          SizedBox(
            width: 60,
            child: Text(
              '${item.quantity.toInt()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),

          // البونص
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${item.bonus.toInt()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // سعر الشراء
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Text(
                  item.purchasePrice.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                // Price Watchdog inline
                if (item.hasPriceChange)
                  Text(
                    '⚠️ ${item.priceChangePercent > 0 ? '+' : ''}${item.priceChangePercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      color: item.priceChangePercent > 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
              ],
            ),
          ),

          // التكلفة لكل وحدة
          SizedBox(
            width: 80,
            child: Text(
              item.costPerUnit.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          // حذف
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final total =
        _items.fold<double>(0, (sum, item) => sum + item.purchasePrice);
    final itemCount = _items.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // إحصائيات
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'عدد البنود: $itemCount',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              Text(
                'الإجمالي: ${total.toStringAsFixed(0)} د.ع',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const Spacer(),

          // زر حفظ مسودة
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _saveDraft,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text(
              'حفظ مسودة',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // زر ترحيل
          ElevatedButton.icon(
            onPressed: (_items.isEmpty || _isSaving) ? null : _postInvoice,
            icon: const Icon(Icons.check_circle),
            label: const Text(
              'ترحيل نهائي',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    final productName = _productController.text.trim();
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final bonus = double.tryParse(_bonusController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (productName.isEmpty || quantity <= 0) {
      return;
    }

    setState(() {
      _items.add(InvoiceItemEntry(
        productId: _selectedProduct?.id,
        productName: productName,
        quantity: quantity,
        bonus: bonus,
        purchasePrice: price,
        oldCost: _selectedProduct?.costPrice,
      ));
    });

    // مسح الحقول
    _productController.clear();
    _quantityController.clear();
    _bonusController.clear();
    _priceController.clear();
    _selectedProduct = null;

    // العودة لحقل المنتج
    _productFocus.requestFocus();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  bool _isSaving = false;

  Future<void> _saveDraft() async {
    if (_selectedSupplierId == null) {
      AppToast.warning(context, 'الرجاء اختيار المذخر');
      return;
    }

    if (_items.isEmpty) {
      AppToast.warning(context, 'الرجاء إضافة بنود');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) throw Exception('لم يتم تسجيل الدخول');

      final purchaseService = ref.read(purchaseOrderServiceProvider);
      final items = _items
          .map((item) => PurchaseItemData(
                productId: item.productId ?? '',
                productName: item.productName,
                unit: 'قطعة',
                quantity: item.quantity,
                bonus: item.bonus,
                unitPrice: item.purchasePrice,
                expiryDate: item.expiryDate,
              ))
          .toList();

      await purchaseService.createDraftOrder(
        supplierId: _selectedSupplierId!,
        invoiceNumber: _invoiceNumberController.text.isNotEmpty
            ? _invoiceNumberController.text
            : 'INV-${DateTime.now().millisecondsSinceEpoch}',
        items: items,
        createdBy: currentUser.id,
      );

      if (mounted) {
        AppToast.success(context, 'تم حفظ المسودة');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'خطأ: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _postInvoice() async {
    if (_selectedSupplierId == null || _items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الترحيل',
            style: TextStyle(fontFamily: 'Tajawal')),
        content: const Text(
          'بعد الترحيل لا يمكن التعديل على هذه الفاتورة.\nهل أنت متأكد؟',
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
            child: const Text('ترحيل',
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) throw Exception('لم يتم تسجيل الدخول');

      final purchaseService = ref.read(purchaseOrderServiceProvider);

      // 1. إنشاء طلب الشراء
      final items = _items
          .map((item) => PurchaseItemData(
                productId: item.productId ?? '',
                productName: item.productName,
                unit: 'قطعة',
                quantity: item.quantity,
                bonus: item.bonus,
                unitPrice: item.purchasePrice,
                expiryDate: item.expiryDate,
              ))
          .toList();

      final invoiceNumber = _invoiceNumberController.text.isNotEmpty
          ? _invoiceNumberController.text
          : 'INV-${DateTime.now().millisecondsSinceEpoch}';

      final orderId = await purchaseService.createDraftOrder(
        supplierId: _selectedSupplierId!,
        invoiceNumber: invoiceNumber,
        items: items,
        createdBy: currentUser.id,
      );

      // 2. ترحيل الطلب (تحديث المخزون + تسجيل في دفتر أستاذ المورد)
      final totalAmount =
          _items.fold<double>(0, (sum, item) => sum + item.purchasePrice);

      await purchaseService.postOrder(
        orderId: orderId,
        supplierId: _selectedSupplierId!,
        totalAmount: totalAmount,
        invoiceNumber: invoiceNumber,
      );

      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'تم ترحيل الفاتورة بنجاح!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'خطأ: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
