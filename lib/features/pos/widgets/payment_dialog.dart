import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../features/pos/models/sale.dart';
import '../providers/pos_providers.dart';
import '../../../services/user_service.dart';
import '../../../services/printer_service.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final List<SaleItem> items;
  final Function(Sale) onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.items,
    required this.onPaymentComplete,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _paidAmountController =
      TextEditingController(); // 💰 حقل المبلغ المدفوع

  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;
  bool _isPartialPayment = false; // 💰 هل هو دفع جزئي؟

  double get subtotal =>
      widget.items.fold(0.0, (sum, item) => sum + item.total);

  double get discount {
    final value = double.tryParse(_discountController.text) ?? 0.0;
    return value.clamp(0.0, subtotal);
  }

  double get total => subtotal - discount;

  double get paidAmount {
    if (!_isPartialPayment) return total;
    final value = double.tryParse(_paidAmountController.text) ?? 0.0;
    return value.clamp(0.0, total);
  }

  double get remainingAmount => total - paidAmount;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildCompactHeader(),
                const SizedBox(height: 20),

                // Payment Method
                _buildPaymentMethodSection(),
                const SizedBox(height: 16),

                // Customer Info (compact)
                _buildCompactCustomerInfo(),
                const SizedBox(height: 16),

                // Discount
                _buildCompactDiscount(),
                const SizedBox(height: 16),

                // Summary
                _buildCompactSummary(),
                const SizedBox(height: 20),

                // Actions
                _buildCompactFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Compact Header
  Widget _buildCompactHeader() {
    return Row(
      children: [
        const Icon(Icons.payment, color: AppColors.primary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إتمام عملية الدفع',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${widget.items.length} منتج - ${subtotal.toInt()} د.ع',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          tooltip: 'إغلاق',
        ),
      ],
    );
  }

  // ✅ Payment Method Section
  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة الدفع',
          style: GoogleFonts.tajawal(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: PaymentMethod.values.map((method) {
            final isSelected = _selectedPaymentMethod == method;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedPaymentMethod = method);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getPaymentMethodIcon(method),
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          method.arabicName,
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.deferred:
        return Icons.event_note;
    }
  }

  // Compact Customer Info
  Widget _buildCompactCustomerInfo() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _customerNameController,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[<>{}"\\\[\]]')),
              LengthLimitingTextInputFormatter(100),
            ],
            decoration: InputDecoration(
              labelText: 'اسم العميل',
              labelStyle: GoogleFonts.tajawal(fontSize: 13),
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            style: GoogleFonts.tajawal(fontSize: 14),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (InputSanitizer.containsXss(value) ||
                    InputSanitizer.containsSqlInjection(value)) {
                  return 'اسم العميل يحتوي على أحرف غير مسموح بها';
                }
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _customerPhoneController,
            decoration: InputDecoration(
              labelText: 'رقم الهاتف',
              labelStyle: GoogleFonts.tajawal(fontSize: 13),
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            style: GoogleFonts.tajawal(fontSize: 14),
            keyboardType: TextInputType.phone,
            inputFormatters: InputSanitizer.phoneFormatters,
          ),
        ),
      ],
    );
  }

  // Compact Discount
  Widget _buildCompactDiscount() {
    return TextFormField(
      controller: _discountController,
      decoration: InputDecoration(
        labelText: 'الخصم (د.ع)',
        labelStyle: GoogleFonts.tajawal(fontSize: 13),
        hintText: '0',
        prefixIcon: const Icon(Icons.discount_outlined, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      style: GoogleFonts.tajawal(fontSize: 14),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) => setState(() {}),
      validator: (value) {
        final val = double.tryParse(value ?? '0') ?? 0;
        if (val < 0) return 'القيمة يجب أن تكون موجبة';
        if (val > subtotal) return 'الخصم أكبر من المجموع';
        return null;
      },
    );
  }

  // Compact Summary
  Widget _buildCompactSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المجموع الفرعي:', style: GoogleFonts.tajawal(fontSize: 13)),
              Text('${subtotal.toInt()} د.ع',
                  style: GoogleFonts.tajawal(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الخصم:',
                    style: GoogleFonts.tajawal(
                        fontSize: 13, color: AppColors.error)),
                Text('-${discount.toInt()} د.ع',
                    style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error)),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي:',
                  style: GoogleFonts.tajawal(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${total.toInt()} د.ع',
                  style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),

          // 💰 خيار الدفع الجزئي
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _isPartialPayment,
            onChanged: (value) {
              setState(() {
                _isPartialPayment = value ?? false;
                if (!_isPartialPayment) {
                  _paidAmountController.clear();
                }
              });
            },
            title: Text(
              'دفع جزئي (دين)',
              style: GoogleFonts.tajawal(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          // 💰 حقل المبلغ المدفوع
          if (_isPartialPayment) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _paidAmountController,
              decoration: InputDecoration(
                labelText: 'المبلغ المدفوع (د.ع)',
                labelStyle: GoogleFonts.tajawal(fontSize: 13),
                hintText: '0',
                prefixIcon: const Icon(Icons.payments, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              style: GoogleFonts.tajawal(fontSize: 14),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => setState(() {}),
              validator: (value) {
                if (!_isPartialPayment) return null;
                final val = double.tryParse(value ?? '0') ?? 0;
                if (val < 0) return 'القيمة يجب أن تكون موجبة';
                if (val > total) return 'المبلغ أكبر من الإجمالي';
                if (val == 0 && _customerNameController.text.isEmpty) {
                  return 'أدخل اسم العميل للدين';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            if (remainingAmount > 0)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'المتبقي (دين): ${remainingAmount.toInt()} د.ع',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // Compact Footer
  Widget _buildCompactFooter() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('إلغاء',
                style: GoogleFonts.tajawal(
                    fontSize: 15, fontWeight: FontWeight.w600)),
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
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.print, size: 20),
                      const SizedBox(width: 8),
                      Text('طباعة ودفع',
                          style: GoogleFonts.tajawal(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ✅ Handle Payment - الطباعة ثم الدفع مع دعم الدفع الجزئي
  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (total <= 0) {
      _showError('الإجمالي يجب أن يكون أكبر من صفر');
      return;
    }

    // 💰 التحقق من اسم العميل إذا كان هناك دين
    if (_isPartialPayment && remainingAmount > 0) {
      if (_customerNameController.text.trim().isEmpty) {
        _showError('يجب إدخال اسم العميل للدفع الآجل');
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      // ✅ الحصول على المستخدم الحالي من النظام
      final currentUser = await UserService.getCurrentUser();

      if (currentUser == null) {
        _showError('لم يتم العثور على معلومات المستخدم');
        setState(() => _isProcessing = false);
        return;
      }

      // ✅ إنشاء البيع وحفظه في قاعدة البيانات مع دعم الدفع الجزئي
      final sale = await ref.read(cartProvider).completeSale(
            cashierId: currentUser.id,
            cashierName: currentUser.fullName,
            paymentMethod: _selectedPaymentMethod,
            customerName: _customerNameController.text.isNotEmpty
                ? _customerNameController.text
                : null,
            customerPhone: _customerPhoneController.text.isNotEmpty
                ? _customerPhoneController.text
                : null,
            discount: discount,
            paidAmount:
                _isPartialPayment ? paidAmount : null, // 💰 المبلغ المدفوع
          );

      if (!mounted) return;

      // ✅ الطباعة مباشرة قبل إغلاق الـ dialog
      try {
        // ✅ استخدام sale.items بدلاً من widget.items (لأن السلة تُمسح في completeSale)
        final itemsForPrint = sale.items
            .map((item) => {
                  'productName': item.productName,
                  'quantity': item.quantity,
                  'price': item.unitPrice,
                })
            .toList();

        // ✅ استخدام قيم sale مباشرة (تدعم الدين والدفع الجزئي)
        await PrinterService.printReceipt(
          sale: sale,
          items: itemsForPrint,
          customerName: _customerNameController.text.isNotEmpty
              ? _customerNameController.text
              : null,
          totalAmount: sale.total, // ✅ الإجمالي من sale
          amountPaid: sale.paidAmount, // ✅ المدفوع من sale (يدعم الدفع الجزئي)
          change: sale.remainingAmount, // ✅ الباقي/الدين من sale
        );
      } catch (printError) {
        // إذا فشلت الطباعة، نعرض رسالة لكن لا نلغي البيع
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ البيع بنجاح لكن فشلت الطباعة: $printError',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (!mounted) return;

      // حفظ context قبل العمليات async
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      widget.onPaymentComplete(sale);
      navigator.pop();

      // Success message مع رقم الفاتورة المحدث
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تمت العملية بنجاح ✓',
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'فاتورة رقم: ${sale.id}',
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isProcessing = false);

      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.tajawal(),
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
