import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/customer_debt.dart';
import '../../data/datasources/local/customer_debt_dao.dart';
import '../../data/datasources/local/debt_payment_dao.dart';
import '../../../auth/data/repositories/user_service.dart';

class DebtPaymentDialog extends StatefulWidget {
  final CustomerDebt debt;
  final VoidCallback onPaymentComplete;

  const DebtPaymentDialog({
    super.key,
    required this.debt,
    required this.onPaymentComplete,
  });

  @override
  State<DebtPaymentDialog> createState() => _DebtPaymentDialogState();
}

class _DebtPaymentDialogState extends State<DebtPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'نقداً';
  bool _isProcessing = false;

  final List<String> _paymentMethods = [
    'نقداً',
    'بطاقة ائتمان',
    'تحويل بنكي',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get amount {
    return double.tryParse(_amountController.text) ?? 0.0;
  }

  double get remainingAfterPayment {
    return (widget.debt.remainingDebt - amount)
        .clamp(0.0, widget.debt.remainingDebt);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // Customer Info Card
                _buildCustomerInfo(),
                const SizedBox(height: 20),

                // Amount Input
                _buildAmountInput(),
                const SizedBox(height: 16),

                // Payment Method
                _buildPaymentMethod(),
                const SizedBox(height: 16),

                // Notes
                _buildNotesField(),
                const SizedBox(height: 20),

                // Summary
                _buildSummary(),
                const SizedBox(height: 24),

                // Actions
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.payment,
            color: AppColors.success,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تسجيل دفعة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'تسديد جزء من الدين',
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
          tooltip: 'إغلاق',
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  widget.debt.customerName[0].toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.debt.customerName,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.debt.customerPhone != null)
                      Text(
                        widget.debt.customerPhone!,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDebtStat(
                'الدين الكلي',
                widget.debt.totalDebt,
                AppColors.textSecondary,
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              _buildDebtStat(
                'المدفوع',
                widget.debt.totalPaid,
                AppColors.success,
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              _buildDebtStat(
                'المتبقي',
                widget.debt.remainingDebt,
                AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toInt()}',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'د.ع',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المبلغ المدفوع',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: 'أدخل المبلغ',
            hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
            prefixIcon:
                const Icon(Icons.attach_money, color: AppColors.success),
            suffixText: 'د.ع',
            suffixStyle: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(
              fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء إدخال المبلغ';
            }
            final amount = double.tryParse(value) ?? 0;
            if (amount <= 0) {
              return 'المبلغ يجب أن يكون أكبر من صفر';
            }
            if (amount > widget.debt.remainingDebt) {
              return 'المبلغ أكبر من الدين المتبقي';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _amountController.text =
                      (widget.debt.remainingDebt / 2).toInt().toString();
                  setState(() {});
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'نصف المبلغ',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _amountController.text =
                      widget.debt.remainingDebt.toInt().toString();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'كامل المبلغ',
                  style: TextStyle(
                      fontFamily: 'Tajawal', fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'طريقة الدفع',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod == method;
            return ChoiceChip(
              label: Text(
                method,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedPaymentMethod = method);
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'ملاحظات (اختياري)',
        labelStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
        hintText: 'أضف ملاحظات إذا لزم الأمر',
        hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
        prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
      maxLines: 2,
    );
  }

  Widget _buildSummary() {
    if (amount <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'المتبقي بعد الدفع',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${remainingAfterPayment.toInt()} د.ع',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: remainingAfterPayment == 0
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
          if (remainingAfterPayment == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'تسديد كامل',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handlePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'تسجيل الدفعة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('لم يتم العثور على معلومات المستخدم');
      }

      final debtPaymentDao = DebtPaymentDAO();
      final customerDebtDao = CustomerDebtDAO();

      // تسجيل الدفعة
      await debtPaymentDao.createPayment(
        customerDebtId: widget.debt.id,
        amount: amount,
        paymentMethod: _selectedPaymentMethod,
        cashierId: currentUser.id,
        cashierName: currentUser.fullName,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // تحديث الدين
      await customerDebtDao.recordPayment(
        customerDebtId: widget.debt.id,
        amount: amount,
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onPaymentComplete();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ: ${e.toString()}',
            style: const TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );

      setState(() => _isProcessing = false);
    }
  }
}
