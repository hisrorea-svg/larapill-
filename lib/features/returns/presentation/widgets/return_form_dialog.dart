import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/return_entity.dart';
import '../../data/repositories/returns_repository.dart';
import '../../../pos/data/repositories/sales_repository.dart';
import '../../../auth/data/repositories/user_service.dart';
import '../../../pos/domain/entities/sale.dart';

class ReturnFormDialog extends ConsumerStatefulWidget {
  final VoidCallback onReturnCreated;

  const ReturnFormDialog({
    super.key,
    required this.onReturnCreated,
  });

  @override
  ConsumerState<ReturnFormDialog> createState() => _ReturnFormDialogState();
}

class _ReturnFormDialogState extends ConsumerState<ReturnFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _saleIdController = TextEditingController();
  final _notesController = TextEditingController();

  Sale? _selectedSale;
  ReturnReason _selectedReason = ReturnReason.defective;
  RefundMethod _selectedRefundMethod = RefundMethod.cash;
  List<ReturnItem> _returnItems = [];
  bool _isLoading = false;
  List<Sale> _recentSales = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSales();
  }

  Future<void> _loadRecentSales() async {
    try {
      final salesRepo = ref.read(salesRepositoryProvider);
      final sales = await salesRepo.getAllSales();
      if (mounted) {
        setState(() {
          _recentSales = sales.take(10).toList();
        });
      }
    } catch (e) {
      // Silent fail
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
      _showSnackBar('الرجاء إدخال رقم الفاتورة', AppColors.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final salesRepo = ref.read(salesRepositoryProvider);
      final saleId = _saleIdController.text.trim().toUpperCase();

      Sale? sale = await salesRepo.getSaleById(saleId);

      if (sale == null && !saleId.contains('-')) {
        final formattedId = 'FK-${saleId.toUpperCase()}';
        sale = await salesRepo.getSaleById(formattedId);
      }

      if (!mounted) return;

      if (sale == null) {
        setState(() {
          _selectedSale = null;
          _returnItems = [];
          _isLoading = false;
        });
        _showSnackBar(
            'لم يتم العثور على الفاتورة رقم: $saleId', AppColors.error);
      } else {
        final baseNumber = DateTime.now().millisecondsSinceEpoch % 1679616;
        setState(() {
          _selectedSale = sale;
          _returnItems = sale!.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final itemId = (baseNumber + index).toRadixString(36).toUpperCase();
            return ReturnItem(
              id: 'RETI-$itemId',
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
        _showSnackBar(
            'تم العثور على الفاتورة ${sale.id} بنجاح', AppColors.success);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedSale = null;
        _returnItems = [];
        _isLoading = false;
      });
      _showSnackBar('خطأ في البحث عن الفاتورة: $e', AppColors.error);
    }
  }

  Future<void> _submitReturn() async {
    if (!_formKey.currentState!.validate() || _selectedSale == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = await _getCurrentUserId();
      final returnsRepo = ref.read(returnsRepositoryProvider);

      final timestamp = DateTime.now().millisecondsSinceEpoch % 1679616;
      final encodedReturn = timestamp.toRadixString(36).toUpperCase();
      final returnId = 'RET-$encodedReturn';

      final return_ = Return(
        id: returnId,
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

      await returnsRepo.createReturn(return_);

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar(
          '✅ تم إنشاء المرتجع بنجاح! رقم: ${return_.id}', AppColors.success);
      widget.onReturnCreated();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('خطأ في إنشاء المرتجع: $e', AppColors.error);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchField(),
                      if (_selectedSale == null && _recentSales.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildRecentSales(),
                      ],
                      if (_selectedSale != null) ...[
                        const SizedBox(height: 24),
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        _buildProductsList(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildReasonDropdown()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRefundMethodDropdown()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildNotesField(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedSale != null) _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                Text('إنشاء مرتجع جديد',
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('أدخل رقم الفاتورة لعرض المنتجات',
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _saleIdController,
            onFieldSubmitted: (_) => _searchSale(),
            decoration: InputDecoration(
              labelText: 'رقم الفاتورة',
              hintText: 'FK-A3F2B أو A3F2B',
              prefixIcon: const Icon(Icons.receipt_long),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _searchSale,
          icon: _isLoading
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator())
              : const Icon(Icons.search),
          label: const Text('بحث', style: TextStyle(fontFamily: 'Tajawal')),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
        ),
      ],
    );
  }

  Widget _buildRecentSales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('فواتير حديثة:',
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(sale.id,
                        style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today, 'التاريخ',
              _selectedSale!.date.toString().split(' ')[0]),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.attach_money, 'الإجمالي',
              '${_selectedSale!.total.toStringAsFixed(0)} د.ع'),
          if (_selectedSale!.customerName != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'العميل', _selectedSale!.customerName!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('المنتجات المرتجعة',
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _returnItems.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final item = _returnItems[index];
            return ListTile(
              title: Text(item.productName,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
              subtitle: Text('${item.quantity} ${item.unit.arabicName}'),
              trailing: Text('${item.total.toStringAsFixed(0)} د.ع',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReasonDropdown() {
    return DropdownButtonFormField<ReturnReason>(
      initialValue: _selectedReason,
      decoration: const InputDecoration(labelText: 'سبب الإرجاع'),
      items: ReturnReason.values.map((reason) {
        return DropdownMenuItem(
            value: reason,
            child: Text(reason.arabicName,
                style: const TextStyle(fontFamily: 'Tajawal')));
      }).toList(),
      onChanged: (val) => setState(() => _selectedReason = val!),
    );
  }

  Widget _buildRefundMethodDropdown() {
    return DropdownButtonFormField<RefundMethod>(
      initialValue: _selectedRefundMethod,
      decoration: const InputDecoration(labelText: 'طريقة الاسترداد'),
      items: RefundMethod.values.map((method) {
        return DropdownMenuItem(
            value: method,
            child: Text(method.arabicName,
                style: const TextStyle(fontFamily: 'Tajawal')));
      }).toList(),
      onChanged: (val) => setState(() => _selectedRefundMethod = val!),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(
          labelText: 'ملاحظات (اختياري)',
          hintText: 'أدخل أي ملاحظات إضافية...',
          border: OutlineInputBorder()),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.3)))),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'الإجمالي المسترد: ${_returnItems.fold<double>(0, (sum, item) => sum + item.total).toStringAsFixed(0)} د.ع',
              style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitReturn,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20)),
            child: const Text('حفظ المرتجع',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
