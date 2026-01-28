import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/entities/sale.dart';
import '../providers/pos_providers.dart';
import '../../../services/user_service.dart';
import '../../../core/services/printer_service.dart';

/// Checkout Panel - لوحة الدفع المدمجة
class CheckoutPanel extends ConsumerStatefulWidget {
  const CheckoutPanel({super.key});

  @override
  ConsumerState<CheckoutPanel> createState() => _CheckoutPanelState();
}

class _CheckoutPanelState extends ConsumerState<CheckoutPanel> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _paidAmountController = TextEditingController();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;
  bool _isPartialPayment = false;

  // ✅ تحسين: السماح بالأرقام العشرية (فواصل)
  final _amountFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  double get discount {
    final value = double.tryParse(_discountController.text) ?? 0.0;
    final cart = ref.read(cartProvider);
    // ✅ تحسين: منع الخصم من تجاوز المجموع الكلي
    return value.clamp(0.0, cart.total);
  }

  double get paidAmount {
    final cart = ref.read(cartProvider);
    final total = cart.total - discount;
    if (!_isPartialPayment)
      return total; // إذا لم يكن جزئي، فالمبلغ المدفوع هو الكل

    final value = double.tryParse(_paidAmountController.text) ?? 0.0;
    // ✅ تحسين: المبلغ المدفوع لا يمكن أن يتجاوز الإجمالي
    return value.clamp(0.0, total);
  }

  double get remainingAmount {
    final cart = ref.read(cartProvider);
    final total = cart.total - discount;
    // إذا كان الإجمالي 0، المتبقي 0
    if (total <= 0) return 0;
    return total - paidAmount;
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = cart.total - discount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'إتمام البيع',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // طريقة الدفع
              _buildPaymentMethodSelector(),
              const SizedBox(height: 16),

              // معلومات العميل
              _buildCustomerFields(),
              const SizedBox(height: 16),

              // الخصم
              _buildDiscountField(cart.total),
              const SizedBox(height: 16),

              // الدفع الجزئي
              _buildPartialPaymentSection(total),
              const SizedBox(height: 20),

              // ملخص الفاتورة
              _buildSummary(cart, total),
              const SizedBox(height: 20),

              // أزرار
              _buildActionButtons(cart, total),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة الدفع',
          style: GoogleFonts.tajawal(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: PaymentMethod.values.map((method) {
            final isSelected = _selectedPaymentMethod == method;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: method != PaymentMethod.values.first ? 8 : 0,
                ),
                child: InkWell(
                  onTap: () => setState(() => _selectedPaymentMethod = method),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getPaymentIcon(method),
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method.arabicName,
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
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

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.deferred:
        return Icons.event_note;
    }
  }

  Widget _buildCustomerFields() {
    return Column(
      children: [
        TextFormField(
          controller: _customerNameController,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[<>{}\"\\]')),
            LengthLimitingTextInputFormatter(100),
          ],
          decoration: InputDecoration(
            labelText: 'اسم العميل (اختياري)',
            labelStyle: GoogleFonts.tajawal(fontSize: 12),
            prefixIcon: const Icon(Icons.person_outline, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            isDense: true,
          ),
          style: GoogleFonts.tajawal(fontSize: 13),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (InputSanitizer.containsXss(value) ||
                  InputSanitizer.containsSqlInjection(value)) {
                return 'اسم غير صالح';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _customerPhoneController,
          decoration: InputDecoration(
            labelText: 'رقم الهاتف (اختياري)',
            labelStyle: GoogleFonts.tajawal(fontSize: 12),
            prefixIcon: const Icon(Icons.phone_outlined, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            isDense: true,
          ),
          style: GoogleFonts.tajawal(fontSize: 13),
          keyboardType: TextInputType.phone,
          inputFormatters: InputSanitizer.phoneFormatters,
        ),
      ],
    );
  }

  Widget _buildDiscountField(double totalCartValue) {
    return TextFormField(
      controller: _discountController,
      decoration: InputDecoration(
        labelText: 'الخصم (د.ع)',
        labelStyle: GoogleFonts.tajawal(fontSize: 12),
        prefixIcon: const Icon(Icons.discount_outlined, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        isDense: true,
        // ✅ إضافة تلميح للمستخدم إذا كان الخصم أكبر من المجموع
        errorText:
            (double.tryParse(_discountController.text) ?? 0) > totalCartValue
                ? 'الخصم يتجاوز المجموع'
                : null,
      ),
      style: GoogleFonts.tajawal(fontSize: 13),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_amountFormatter],
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPartialPaymentSection(double total) {
    return Column(
      children: [
        CheckboxListTile(
          value: _isPartialPayment,
          onChanged: (value) {
            setState(() {
              _isPartialPayment = value ?? false;
              if (!_isPartialPayment) _paidAmountController.clear();
            });
          },
          title: Text(
            'دفع جزئي (دين)',
            style:
                GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        if (_isPartialPayment) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _paidAmountController,
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع (د.ع)',
                    labelStyle: GoogleFonts.tajawal(fontSize: 12),
                    prefixIcon: const Icon(Icons.payments, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    isDense: true,
                  ),
                  style: GoogleFonts.tajawal(fontSize: 13),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [_amountFormatter],
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (!_isPartialPayment) return null;
                    if (_customerNameController.text.trim().isEmpty) {
                      return 'أدخل اسم العميل للدين';
                    }
                    return null;
                  },
                ),
              ),
              // ✅ زر سريع لملء المبلغ
              if (total > 0)
                IconButton(
                  onPressed: () {
                    _paidAmountController.text = total.toInt().toString();
                    setState(() {});
                  },
                  icon: const Icon(Icons.done_all, color: AppColors.primary),
                  tooltip: 'كامل المبلغ',
                ),
            ],
          ),
          if (remainingAmount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'المتبقي (دين): ${_formatNumber(remainingAmount)} د.ع',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSummary(CartProvider cart, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
              'المجموع الفرعي', '${_formatNumber(cart.total)} د.ع'),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _buildSummaryRow('الخصم', '-${_formatNumber(discount)} د.ع',
                color: AppColors.error),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_formatNumber(total)} د.ع',
                style: GoogleFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${cart.itemCount} منتج',
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              GoogleFonts.tajawal(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(CartProvider cart, double total) {
    return Row(
      children: [
        // إلغاء
        Expanded(
          child: OutlinedButton(
            onPressed: cart.items.isEmpty || _isProcessing
                ? null
                : () => _showClearDialog(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // إتمام البيع
        Expanded(
          flex: 2,
          child: ElevatedButton(
            // ✅ تحسين: السماح بالدفع إذا كان المجموع 0 أو أكثر
            onPressed: cart.items.isEmpty || _isProcessing
                ? null
                : () => _handlePayment(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.print, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'طباعة ودفع',
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إفراغ السلة', style: GoogleFonts.tajawal()),
        content: Text('هل أنت متأكد؟', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider).clearCart();
              Navigator.pop(ctx);
              _resetForm();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('إفراغ', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _customerNameController.clear();
    _customerPhoneController.clear();
    _discountController.text = '0';
    _paidAmountController.clear();
    setState(() {
      _isProcessing = false; // ✅ إعادة تعيين حالة المعالجة
      _isPartialPayment = false;
      _selectedPaymentMethod = PaymentMethod.cash;
    });
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = ref.read(cartProvider);
    final total = cart.total - discount;

    // ✅ تحسين: السماح بالفواتير الصفرية (هدايا/عروض)
    if (total < 0) {
      AppToast.error(context, 'الإجمالي لا يمكن أن يكون بالسالب');
      return;
    }

    if (_isPartialPayment && remainingAmount > 0) {
      if (_customerNameController.text.trim().isEmpty) {
        AppToast.error(context, 'يجب إدخال اسم العميل للدفع الآجل');
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) {
        AppToast.error(context, 'لم يتم العثور على معلومات المستخدم');
        setState(() => _isProcessing = false);
        return;
      }

      final sale = await cart.completeSale(
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
        paidAmount: _isPartialPayment ? paidAmount : null,
      );

      if (!mounted) return;

      // الطباعة
      try {
        final itemsForPrint = sale.items
            .map((item) => {
                  'productName': item.productName,
                  'quantity': item.quantity,
                  'price': item.unitPrice,
                })
            .toList();

        await PrinterService.printReceipt(
          sale: sale,
          items: itemsForPrint,
          customerName: _customerNameController.text.isNotEmpty
              ? _customerNameController.text
              : null,
          totalAmount: sale.total,
          amountPaid: sale.paidAmount,
          change: sale.remainingAmount,
        );
      } catch (printError) {
        if (mounted) {
          AppToast.warning(context, 'تم حفظ البيع لكن فشلت الطباعة');
        }
      }

      if (!mounted) return;

      // ✅ اهتزاز خفيف للتأكيد
      HapticFeedback.mediumImpact();

      AppToast.success(context, 'تمت العملية بنجاح ✓ فاتورة: ${sale.id}');
      _resetForm();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // ✅ دالة مساعدة لتنسيق الأرقام (تظهر الكسور إذا وجدت)
  String _formatNumber(double number) {
    final text = number == number.truncateToDouble()
        ? number.toInt().toString() // عدد صحيح
        : number.toStringAsFixed(2); // عشري
    return text.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
