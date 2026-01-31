import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/datasources/local/supplier_ledger_dao.dart';
import '../../data/datasources/local/supplier_payments_dao.dart';
import '../../data/models/supplier_ledger_entry.dart';

/// Provider لحسابات الموردين
final supplierAccountProvider =
    FutureProvider.family<SupplierAccountData, String>((ref, supplierId) async {
  final ledgerDao = SupplierLedgerDao();
  final paymentsDao = SupplierPaymentsDao();

  final entries = await ledgerDao.getSupplierEntries(supplierId);
  final balance = await ledgerDao.getSupplierBalance(supplierId);
  final totalPayments = await paymentsDao.getSupplierTotalPayments(supplierId);

  return SupplierAccountData(
    entries: entries,
    currentBalance: balance,
    totalPayments: totalPayments,
  );
});

class SupplierAccountData {
  final List<SupplierLedgerEntry> entries;
  final double currentBalance;
  final double totalPayments;

  SupplierAccountData({
    required this.entries,
    required this.currentBalance,
    required this.totalPayments,
  });
}

/// شاشة كشف حساب المذخر
class SupplierAccountScreen extends ConsumerStatefulWidget {
  final String supplierId;
  final String supplierName;

  const SupplierAccountScreen({
    super.key,
    required this.supplierId,
    required this.supplierName,
  });

  @override
  ConsumerState<SupplierAccountScreen> createState() =>
      _SupplierAccountScreenState();
}

class _SupplierAccountScreenState extends ConsumerState<SupplierAccountScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isAddingPayment = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(supplierAccountProvider(widget.supplierId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'كشف حساب: ${widget.supplierName}',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(supplierAccountProvider(widget.supplierId)),
          ),
        ],
      ),
      body: accountAsync.when(
        data: (data) => _buildContent(data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPaymentDialog,
        icon: const Icon(Icons.add),
        label:
            const Text('تسجيل دفعة', style: TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildContent(SupplierAccountData data) {
    return Column(
      children: [
        // بطاقة الملخص
        _buildSummaryCard(data),

        // قائمة الحركات
        Expanded(
          child: data.entries.isEmpty
              ? _buildEmptyState()
              : _buildEntriesList(data.entries),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(SupplierAccountData data) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.currentBalance > 0
              ? [Colors.red.shade400, Colors.red.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (data.currentBalance > 0 ? Colors.red : Colors.green)
                .withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الرصيد الحالي',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###').format(data.currentBalance.abs())} د.ع',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  data.currentBalance > 0 ? 'مستحق للمورد' : 'لا يوجد مستحقات',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.payments, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  NumberFormat('#,###').format(data.totalPayments),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'إجمالي المدفوع',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'لا توجد حركات',
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

  Widget _buildEntriesList(List<SupplierLedgerEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildEntryCard(entry);
      },
    );
  }

  Widget _buildEntryCard(SupplierLedgerEntry entry) {
    final isDebit = entry.amount > 0; // فاتورة = زيادة الدين
    final icon = _getEntryIcon(entry.referenceType);
    final color = isDebit ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          right: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        children: [
          // أيقونة النوع
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 12),

          // التفاصيل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description ?? _getEntryTypeLabel(entry.referenceType),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('yyyy/MM/dd - HH:mm').format(entry.createdAt),
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // المبلغ والرصيد
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDebit ? '+' : ''}${NumberFormat('#,###').format(entry.amount)}',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'الرصيد: ${NumberFormat('#,###').format(entry.balanceAfter)}',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getEntryIcon(String type) {
    switch (type) {
      case 'invoice':
        return Icons.receipt;
      case 'payment':
        return Icons.payments;
      case 'return':
        return Icons.assignment_return;
      default:
        return Icons.swap_horiz;
    }
  }

  String _getEntryTypeLabel(String type) {
    switch (type) {
      case 'invoice':
        return 'فاتورة شراء';
      case 'payment':
        return 'دفعة';
      case 'return':
        return 'مرتجع';
      default:
        return 'حركة';
    }
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل دفعة جديدة',
            style: TextStyle(fontFamily: 'Tajawal')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // المبلغ
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),

              const SizedBox(height: 16),

              // طريقة الدفع
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: InputDecoration(
                  labelText: 'طريقة الدفع',
                  labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                  prefixIcon: const Icon(Icons.payment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'cash',
                      child: Text('نقدي',
                          style: TextStyle(fontFamily: 'Tajawal'))),
                  DropdownMenuItem(
                      value: 'bank',
                      child: Text('تحويل بنكي',
                          style: TextStyle(fontFamily: 'Tajawal'))),
                  DropdownMenuItem(
                      value: 'check',
                      child:
                          Text('شيك', style: TextStyle(fontFamily: 'Tajawal'))),
                ],
                onChanged: (value) {
                  setState(() => _paymentMethod = value!);
                },
              ),

              const SizedBox(height: 16),

              // ملاحظات
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: _isAddingPayment ? null : _addPayment,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: _isAddingPayment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('حفظ',
                    style:
                        TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addPayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      AppToast.warning(context, 'الرجاء إدخال مبلغ صحيح');
      return;
    }

    setState(() => _isAddingPayment = true);

    try {
      final paymentsDao = SupplierPaymentsDao();
      await paymentsDao.createPayment(
        supplierId: widget.supplierId,
        amount: amount,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // تحديث البيانات
      ref.invalidate(supplierAccountProvider(widget.supplierId));

      // مسح الحقول
      _amountController.clear();
      _notesController.clear();
      _paymentMethod = 'cash';

      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'تم تسجيل الدفعة بنجاح');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'خطأ: $e');
      }
    } finally {
      if (mounted) setState(() => _isAddingPayment = false);
    }
  }
}
