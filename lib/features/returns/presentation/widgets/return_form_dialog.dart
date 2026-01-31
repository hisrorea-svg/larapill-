import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/return_entity.dart';
import '../../data/repositories/return_service.dart';
import '../../../pos/data/repositories/sales_service.dart';
import '../../../auth/data/repositories/user_service.dart';
import '../../../pos/domain/entities/sale.dart';

class ReturnFormDialog extends StatefulWidget {
  final VoidCallback onReturnCreated;

  const ReturnFormDialog({
    super.key,
    required this.onReturnCreated,
  });

  @override
  State<ReturnFormDialog> createState() => _ReturnFormDialogState();
}

class _ReturnFormDialogState extends State<ReturnFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _saleIdController = TextEditingController();
  final _notesController = TextEditingController();
  final _salesService = SalesService();
  final _returnService = ReturnService();

  Sale? _selectedSale;
  ReturnReason _selectedReason = ReturnReason.defective;
  RefundMethod _selectedRefundMethod = RefundMethod.cash;
  List<ReturnItem> _returnItems = [];
  bool _isLoading = false;
  List<Sale> _recentSales = []; // 🆕 للاقتراحات الذكية

  @override
  void initState() {
    super.initState();
    _loadRecentSales(); // 🆕 تحميل الفواتير الأخيرة
  }

  // 🆕 تحميل آخر 10 فواتير للاقتراحات
  Future<void> _loadRecentSales() async {
    try {
      final sales = await _salesService.getAllSales();
      if (mounted) {
        setState(() {
          _recentSales = sales.take(10).toList();
        });
      }
    } catch (e) {
      // Silent fail - الاقتراحات ليست ضرورية
    }
  }

  SaleItem? _getOriginalSaleItem(ReturnItem returnItem) {
    if (_selectedSale == null) return null;
    final parts = returnItem.id.split('-');
    final originalId = parts.isNotEmpty ? parts.last : returnItem.id;
    try {
      return _selectedSale!.items
          .firstWhere((saleItem) => saleItem.id == originalId);
    } catch (_) {
      return null;
    }
  }

  Future<String> _getCurrentUserId() async {
    final user = await UserService.getCurrentUser();
    return user?.id ?? 'admin';
  }

  @override
  void dispose() {
    _saleIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _searchSale() async {
    if (_saleIdController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء إدخال رقم الفاتورة',
            style: TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final saleId = _saleIdController.text.trim().toUpperCase();

      // 🆕 البحث الذكي - يدعم النظامين القديم والجديد
      Sale? sale = await _salesService.getSaleById(saleId);

      // إذا لم يجد، حاول البحث بتنسيقات بديلة
      if (sale == null && !saleId.contains('-')) {
        // إذا أدخل المستخدم الرمز فقط (مثل A3F2B)، أضف البادئة FK-
        final formattedId = 'FK-${saleId.toUpperCase()}';
        sale = await _salesService.getSaleById(formattedId);
      }

      if (!mounted) return;

      if (sale == null) {
        // الفاتورة غير موجودة
        setState(() {
          _selectedSale = null;
          _returnItems = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لم يتم العثور على الفاتورة رقم: $saleId\n'
              'تأكد من صحة رقم الفاتورة (مثال: FK-A3F2B)',
              style: const TextStyle(
                fontFamily: 'Tajawal',
              ),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // ✅ تم العثور على الفاتورة - توليد أرقام إرجاع احترافية
        final baseNumber = DateTime.now().millisecondsSinceEpoch % 1679616;

        setState(() {
          _selectedSale = sale;
          // تحويل عناصر المبيعة إلى عناصر مرتجعة مع أرقام ذكية
          _returnItems = sale!.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final itemId = (baseNumber + index).toRadixString(36).toUpperCase();
            return ReturnItem(
              id: 'RETI-$itemId', // مثال: RETI-A3F2B, RETI-A3F2C
              productId: item.productId,
              productName: item.productName,
              unit: item.unit,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              total: item.total,
            );
          }).toList();
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تم العثور على الفاتورة ${sale.id} بنجاح ✓\n${sale.items.length} منتج',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _selectedSale = null;
        _returnItems = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في البحث عن الفاتورة: $e',
            style: const TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _submitReturn() async {
    if (!_formKey.currentState!.validate() || _selectedSale == null) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = await _getCurrentUserId();

      if (!mounted) return;

      // 🆕 توليد رقم إرجاع احترافي ومبهم (RET-XXXXX)
      final today = DateTime.now();
      final timestamp = today.millisecondsSinceEpoch % 1679616; // رقم عشوائي
      final encodedReturn = timestamp.toRadixString(36).toUpperCase();
      final returnId = 'RET-$encodedReturn';

      final return_ = Return(
        id: returnId, // مثال: RET-XK9Z2
        saleId: _selectedSale!.id,
        returnDate: DateTime.now(),
        items: _returnItems,
        reason: _selectedReason,
        status: ReturnStatus.pending,
        totalRefund: _returnItems.fold(0, (sum, item) => sum + item.total),
        refundMethod: _selectedRefundMethod,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        processedBy: userId,
        createdAt: DateTime.now(),
      );

      await _returnService.createReturn(return_);

      if (!mounted) return;

      // حفظ الـ context قبل إغلاق الـ dialog
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // إغلاق الـ dialog
      navigator.pop();

      // إظهار رسالة نجاح
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '✅ تم إنشاء المرتجع بنجاح!',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'رقم المرتجع: ${return_.id}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // تحديث القائمة
      widget.onReturnCreated();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في إنشاء المرتجع: $e',
            style: const TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      child: Container(
        width: 900,
        height: screenHeight * 0.9,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header ثابت
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_return,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إنشاء مرتجع جديد',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'أدخل رقم الفاتورة لعرض المنتجات',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            // المحتوى القابل للتمرير
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // البحث عن الفاتورة
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _saleIdController,
                              onFieldSubmitted: (_) => _searchSale(),
                              decoration: InputDecoration(
                                labelText: 'رقم الفاتورة',
                                hintText: 'FK-A3F2B أو A3F2B',
                                prefixIcon: const Icon(Icons.receipt_long),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelStyle: const TextStyle(
                                  fontFamily: 'Tajawal',
                                ),
                                hintStyle: const TextStyle(
                                    fontFamily: 'Tajawal', fontSize: 12),
                                filled: true,
                                fillColor: AppColors.background,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال رقم الفاتورة';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _searchSale,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: const Text('بحث',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                )),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 🆕 اقتراحات الفواتير الأخيرة
                      if (_selectedSale == null && _recentSales.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'فواتير حديثة:',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _recentSales.take(5).map((sale) {
                            return InkWell(
                              onTap: () {
                                _saleIdController.text = sale.id;
                                _searchSale();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.receipt,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      sale.id,
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${sale.total.toInt()} د.ع)',
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      if (_selectedSale != null) ...[
                        const SizedBox(height: 24),

                        // معلومات الفاتورة
                        _buildInfoCard(),
                        const SizedBox(height: 24),

                        // قائمة المنتجات
                        _buildProductsList(),
                        const SizedBox(height: 24),

                        // التفاصيل الإضافية
                        Row(
                          children: [
                            Expanded(child: _buildReasonDropdown()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRefundMethodDropdown()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ملاحظات
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'ملاحظات (اختياري)',
                            hintText: 'أدخل أي ملاحظات إضافية...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelStyle: const TextStyle(
                              fontFamily: 'Tajawal',
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer ثابت
            if (_selectedSale != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.3)),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // الإجمالي
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payments,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'إجمالي الاسترداد',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${_returnItems.fold<double>(0, (sum, item) => sum + item.total).toStringAsFixed(0)} د.ع',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // أزرار الإجراء
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                          )),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitReturn,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: const Text('حفظ المرتجع',
                          style:
                              TextStyle(fontFamily: 'Tajawal', fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widgets مساعدة
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              SizedBox(width: 8),
              Text(
                'معلومات الفاتورة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.calendar_today,
                  'التاريخ',
                  _selectedSale!.date.toString().split(' ')[0],
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.attach_money,
                  'الإجمالي',
                  '${_selectedSale!.total.toStringAsFixed(0)} د.ع',
                ),
              ),
            ],
          ),
          if (_selectedSale!.customerName != null) ...[
            const SizedBox(height: 8),
            _buildInfoItem(
              Icons.person,
              'العميل',
              _selectedSale!.customerName!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shopping_cart, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'المنتجات المرتجعة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_returnItems.length} منتج',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _returnItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _returnItems[index];
            final originalItem = _getOriginalSaleItem(item);
            return _buildProductCard(originalItem, item, index);
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(SaleItem? originalItem, ReturnItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medication,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.unit.arabicName,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'السعر: ${item.unitPrice.toStringAsFixed(0)} د.ع',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${item.total.toStringAsFixed(0)} د.ع',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الكمية المباعة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      (originalItem?.quantity ?? item.quantity)
                          .toStringAsFixed(0),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الكمية المرتجعة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: item.quantity.toString(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$')),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      onChanged: (value) {
                        final quantity = double.tryParse(value) ?? 0;
                        final maxQuantity =
                            originalItem?.quantity ?? item.quantity;
                        if (quantity > maxQuantity) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'الكمية المرتجعة لا يمكن أن تتجاوز الكمية المباعة',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _returnItems[index] = ReturnItem(
                            id: item.id,
                            productId: item.productId,
                            productName: item.productName,
                            unit: item.unit,
                            quantity: quantity,
                            unitPrice: item.unitPrice,
                            total: quantity * item.unitPrice,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonDropdown() {
    return DropdownButtonFormField<ReturnReason>(
      initialValue: _selectedReason,
      decoration: InputDecoration(
        labelText: 'سبب الإرجاع',
        prefixIcon: const Icon(Icons.info_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      items: ReturnReason.values
          .map((reason) => DropdownMenuItem(
                value: reason,
                child: Text(reason.arabicName,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                    )),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedReason = value);
      },
    );
  }

  Widget _buildRefundMethodDropdown() {
    return DropdownButtonFormField<RefundMethod>(
      initialValue: _selectedRefundMethod,
      decoration: InputDecoration(
        labelText: 'طريقة الاسترداد',
        prefixIcon: const Icon(Icons.payment),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      items: RefundMethod.values
          .map((method) => DropdownMenuItem(
                value: method,
                child: Text(method.arabicName,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                    )),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedRefundMethod = value);
      },
    );
  }
}
