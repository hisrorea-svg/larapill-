import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../services/meds_data_service.dart';
import '../domain/entities/add_product_params.dart';
import '../../../../core/utils/input_sanitizer.dart';
import '../providers/inventory_providers.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// حوار إضافة منتج جديد - تصميم مبسط مستوحى من Midgram
/// ═══════════════════════════════════════════════════════════════════════════
class SimpleAddProductDialog extends ConsumerStatefulWidget {
  const SimpleAddProductDialog({super.key});

  @override
  ConsumerState<SimpleAddProductDialog> createState() =>
      _SimpleAddProductDialogState();
}

class _SimpleAddProductDialogState
    extends ConsumerState<SimpleAddProductDialog> {
  final _formKey = GlobalKey<FormState>();

  // ═══════════════ Controllers ═══════════════
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _boxCountController = TextEditingController(text: '1');
  final _unitsPerBoxController = TextEditingController(text: '1');
  final _costController = TextEditingController();
  final _priceController = TextEditingController();

  // ═══════════════ State ═══════════════
  DateTime? _expiryDate;
  bool _isLoading = false;
  bool _hasBox = true;

  // AutoComplete
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  final FocusNode _nameFocusNode = FocusNode();

  // ═══════════════ Computed Values ═══════════════
  int get _boxCount =>
      _hasBox ? (int.tryParse(_boxCountController.text) ?? 0) : 1;
  int get _unitsPerBox =>
      _hasBox ? (int.tryParse(_unitsPerBoxController.text) ?? 1) : 1;
  int get _totalUnits => _hasBox
      ? _boxCount * _unitsPerBox
      : (int.tryParse(_boxCountController.text) ??
          0); // في حالة وحدات فقط: _boxCountController = عدد الوحدات
  double get _boxCost => double.tryParse(_costController.text) ?? 0;
  double get _boxPrice => double.tryParse(_priceController.text) ?? 0;
  double get _unitCost =>
      _hasBox && _unitsPerBox > 0 ? _boxCost / _unitsPerBox : _boxCost;
  double get _unitPrice =>
      _hasBox && _unitsPerBox > 0 ? _boxPrice / _unitsPerBox : _boxPrice;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    // إعادة بناء عند تغيير القيم
    _boxCountController.addListener(() => setState(() {}));
    _unitsPerBoxController.addListener(() => setState(() {}));
    _costController.addListener(() => setState(() {}));
    _priceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _barcodeController.dispose();
    _boxCountController.dispose();
    _unitsPerBoxController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  // ═══════════════ البحث الذكي ═══════════════
  void _onNameChanged() {
    final query = _nameController.text.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final results = MedsDataService.searchMeds(query);
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty;
    });
  }

  /// 🧠 اختيار من قاعدة البيانات - ملء تلقائي ذكي
  void _selectFromDatabase(Map<String, dynamic> med) {
    setState(() {
      _nameController.text = med['name'] ?? '';
      _companyController.text = med['manufacturer'] ?? '';
      _barcodeController.text = med['barcode'] ?? '';

      // ✅ ملء الأسعار تلقائياً
      final double price = med['price']?.toDouble() ?? 0.0;
      final double cost = med['cost']?.toDouble() ?? 0.0;
      _priceController.text = price > 0 ? price.toStringAsFixed(0) : '';
      _costController.text = cost > 0 ? cost.toStringAsFixed(0) : '';

      // ✅ ملء التعبئة إذا متوفرة
      final int unitsPerBox =
          med['units_per_box'] ?? med['strips_per_box'] ?? 0;
      if (unitsPerBox > 0) {
        _unitsPerBoxController.text = unitsPerBox.toString();
        _hasBox = true;
      }

      _showSuggestions = false;
      _suggestions = [];
    });

    if (mounted) {
      AppToast.info(context, '🧠 تم ملء البيانات تلقائياً');
    }
  }

  // ═══════════════ BUILD ═══════════════
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final dialogWidth = isWide
              ? constraints.maxWidth.clamp(500.0, 700.0)
              : constraints.maxWidth;

          return Container(
            width: dialogWidth,
            constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.9),
            padding: EdgeInsets.all(isWide ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  Flexible(child: _buildContent(isWide)),
                  const SizedBox(height: 16),
                  _buildActions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════ الهيدر ═══════════════
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_box_rounded,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إضافة منتج جديد',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'أدخل بيانات المنتج',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  // ═══════════════ المحتوى الرئيسي ═══════════════
  Widget _buildContent(bool isWide) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── معلومات المنتج ───
          _buildSectionTitle('📦 معلومات المنتج'),
          const SizedBox(height: 8),
          _buildProductNameField(),
          const SizedBox(height: 10),
          _buildRow([
            _buildTextField(
              controller: _companyController,
              label: 'الشركة المصنعة',
              icon: Icons.business,
            ),
            _buildTextField(
              controller: _barcodeController,
              label: 'الباركود',
              icon: Icons.qr_code,
            ),
          ]),

          const SizedBox(height: 20),

          // ─── المخزون ───
          _buildSectionTitle('📊 المخزون'),
          const SizedBox(height: 8),

          // ✅ Toggle: وحدات فقط / علبة + وحدات
          _buildEntryModeToggle(),
          const SizedBox(height: 12),

          // الحقول حسب نوع الإدخال
          if (_hasBox) ...[
            // علبة + وحدات
            _buildRow([
              _buildNumberField(
                controller: _boxCountController,
                label: 'عدد العلب',
                icon: Icons.inventory_2_outlined,
              ),
              _buildNumberField(
                controller: _unitsPerBoxController,
                label: 'التعبئة (وحدة/علبة)',
                icon: Icons.grid_view_rounded,
              ),
            ]),
          ] else ...[
            // وحدات فقط
            _buildNumberField(
              controller: _boxCountController,
              label: 'عدد الوحدات',
              icon: Icons.inventory_2_outlined,
            ),
          ],
          const SizedBox(height: 8),
          _buildTotalUnitsCard(),

          const SizedBox(height: 20),

          // ─── الأسعار ───
          _buildSectionTitle(
              _hasBox ? '💰 الأسعار (للعلبة الواحدة)' : '💰 الأسعار (للوحدة)'),
          const SizedBox(height: 8),
          _buildRow([
            _buildPriceField(
              controller: _costController,
              label: 'سعر الشراء',
              icon: Icons.shopping_cart_outlined,
              color: Colors.orange,
            ),
            _buildPriceField(
              controller: _priceController,
              label: 'سعر البيع',
              icon: Icons.sell_outlined,
              color: Colors.green,
            ),
          ]),
          if (_hasBox && _unitsPerBox > 1) ...[
            const SizedBox(height: 8),
            _buildUnitPricesCard(),
          ],

          const SizedBox(height: 20),

          // ─── تاريخ الصلاحية ───
          _buildSectionTitle('📅 تاريخ الصلاحية'),
          const SizedBox(height: 8),
          _buildExpiryDateField(),
        ],
      ),
    );
  }

  // ═══════════════ عنوان القسم ═══════════════
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  // ═══════════════ صف من الحقول ═══════════════
  Widget _buildRow(List<Widget> children) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 10)])
          .toList()
        ..removeLast(),
    );
  }

  // ═══════════════ Toggle: وحدة/علبة ═══════════════
  Widget _buildEntryModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // وحدات فقط
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _hasBox = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_hasBox ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 18,
                      color: !_hasBox ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'وحدات فقط',
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !_hasBox ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // علبة + وحدات
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _hasBox = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _hasBox ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: _hasBox ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'علبة + وحدات',
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _hasBox ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════ حقل اسم المنتج مع البحث ═══════════════
  Widget _buildProductNameField() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          style: GoogleFonts.tajawal(fontSize: 14),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[<>{}\"\\]')),
            LengthLimitingTextInputFormatter(200),
          ],
          decoration: InputDecoration(
            labelText: 'اسم المنتج *',
            hintText: 'ابدأ الكتابة للبحث...',
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.medication, size: 20),
            labelStyle: GoogleFonts.tajawal(fontSize: 13),
          ),
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return 'مطلوب';
            if (InputSanitizer.containsXss(v!) ||
                InputSanitizer.containsSqlInjection(v)) {
              return 'اسم غير صالح';
            }
            return null;
          },
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.primary, width: 2),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length.clamp(0, 5),
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final med = _suggestions[index];
                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: const Icon(Icons.medication,
                      color: AppColors.primary, size: 20),
                  title: Text(
                    med['name'] ?? '',
                    style: GoogleFonts.tajawal(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    med['manufacturer'] ?? '',
                    style:
                        GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                  ),
                  onTap: () => _selectFromDatabase(med),
                );
              },
            ),
          ),
      ],
    );
  }

  // ═══════════════ حقل نص عادي ═══════════════
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.tajawal(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(icon, size: 20),
        labelStyle: GoogleFonts.tajawal(fontSize: 13),
      ),
    );
  }

  // ═══════════════ حقل رقم ═══════════════
  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.tajawal(fontSize: 14),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(icon, size: 20),
        labelStyle: GoogleFonts.tajawal(fontSize: 13),
      ),
      validator: (v) {
        if (v?.isEmpty ?? true) return 'مطلوب';
        if ((int.tryParse(v!) ?? 0) <= 0) return 'أدخل رقم صحيح';
        return null;
      },
    );
  }

  // ═══════════════ حقل سعر ═══════════════
  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.tajawal(fontSize: 14),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(icon, size: 20, color: color),
        suffixText: 'د.ع',
        labelStyle: GoogleFonts.tajawal(fontSize: 13),
      ),
      validator: (v) {
        if (v?.isEmpty ?? true) return 'مطلوب';
        return null;
      },
    );
  }

  // ═══════════════ بطاقة إجمالي الوحدات ═══════════════
  Widget _buildTotalUnitsCard() {
    // بناء نص الإجمالي بالترتيب العربي الصحيح
    String detailText = '';
    if (_hasBox) {
      detailText = '  ($_boxCount علبة × $_unitsPerBox وحدة)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calculate_outlined,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'الإجمالي: $_totalUnits وحدة$detailText',
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // ═══════════════ بطاقة أسعار الوحدة ═══════════════
  Widget _buildUnitPricesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPriceChip('تكلفة الوحدة', _unitCost, Colors.orange),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildPriceChip('بيع الوحدة', _unitPrice, Colors.green),
        ],
      ),
    );
  }

  Widget _buildPriceChip(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style:
              GoogleFonts.tajawal(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(0)} د.ع',
          style: GoogleFonts.tajawal(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══════════════ حقل تاريخ الصلاحية ═══════════════
  Widget _buildExpiryDateField() {
    return InkWell(
      onTap: _pickExpiryDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              size: 20,
              color: _expiryDate != null ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(
              _expiryDate != null
                  ? '${_expiryDate!.month}/${_expiryDate!.year}'
                  : 'اختر تاريخ الانتهاء *',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color:
                    _expiryDate != null ? AppColors.textPrimary : Colors.grey,
              ),
            ),
            const Spacer(),
            if (_expiryDate != null)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  // ═══════════════ الأزرار ═══════════════
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_circle_outline, size: 20),
            label: Text(
              _isLoading ? 'جاري الإضافة...' : 'إضافة المنتج',
              style: GoogleFonts.tajawal(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════ إرسال البيانات ═══════════════
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_expiryDate == null) {
      AppToast.warning(context, 'اختر تاريخ الانتهاء');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final params = AddProductParams(
        name: _nameController.text.trim(),
        company: _companyController.text.trim(),
        barcode: _barcodeController.text.trim(),
        quantity: _totalUnits,
        cost: _unitCost,
        price: _unitPrice,
        expiryDate: _expiryDate!,
        boxCount: _boxCount,
        unitsPerBox: _unitsPerBox,
        boxCost: _boxCost,
        boxPrice: _boxPrice,
      );

      await ref.read(inventoryControllerProvider.notifier).addProduct(params);

      if (mounted) {
        AppToast.success(context, 'تم إضافة المنتج بنجاح ✅');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'حدث خطأ: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
