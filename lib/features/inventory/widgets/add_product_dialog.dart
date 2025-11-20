import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';
import '../../../models/medicine_unit.dart';
import '../../../database/daos/product_dao.dart';
import '../../../database/database_helper.dart';
import '../../../services/meds_data_service.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../providers/inventory_providers.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class SimpleAddProductDialog extends ConsumerStatefulWidget {
  const SimpleAddProductDialog({super.key});

  @override
  ConsumerState<SimpleAddProductDialog> createState() =>
      _SimpleAddProductDialogState();
}

class _SimpleAddProductDialogState
    extends ConsumerState<SimpleAddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();

  ProductCategory _category = ProductCategory.tablets;
  DateTime? _expiryDate;
  bool _isLoading = false;

  // ✅ الوحدات - بتسميات واضحة
  MedicineUnit _singleUnit = MedicineUnit.strip; // الوحدة المفردة
  bool _hasPackage = false; // هل له تعبئة (باكيت/كرتون)؟
  int _qtyPerPackage = 10; // كم وحدة في الباكيت

  // ✅ توضيح السعر المُدخل
  String _priceFor = 'single'; // 'single' أو 'package'

  // AutoComplete
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

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

  void _selectFromDatabase(Map<String, dynamic> med) {
    setState(() {
      _nameController.text = med['name'] ?? '';
      _companyController.text = med['manufacturer'] ?? '';
      _barcodeController.text = med['barcode'] ?? '';

      // ✅ تحليل ذكي جداً للـ unit من JSON
      final String unit = med['unit']?.toString().toLowerCase() ?? '';

      // 🧠 تحليل الوحدة والفئة تلقائياً
      _analyzeUnitAndCategory(unit);

      final double price = med['price']?.toDouble() ?? 0.0;
      final double cost = med['cost']?.toDouble() ?? 0.0;

      _priceController.text = price > 0 ? price.toStringAsFixed(0) : '';
      _costController.text = cost > 0 ? cost.toStringAsFixed(0) : '';

      _showSuggestions = false;
      _suggestions = [];
    });

    // ✅ إظهار رسالة التحليل الذكي
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🧠 تحليل ذكي: ${_category.arabicName} • ${_singleUnit.arabicName}'
            '${_hasPackage ? " • باكيت ($_qtyPerPackage)" : ""}',
            style: GoogleFonts.tajawal(fontSize: 13),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 🧠 تحليل ذكي للوحدة والفئة من النص
  void _analyzeUnitAndCategory(String unit) {
    // تنظيف النص
    final u = unit.toLowerCase().trim();

    // ✅ أقراص وكبسولات
    if (u.contains('tab') || u.contains('cap') || u.contains('caplet')) {
      _category = ProductCategory.tablets;
      _singleUnit = MedicineUnit.strip;
      _hasPackage = true;
      _priceFor = 'package';

      // محاولة استخراج العدد من النص
      final match = RegExp(r'(\d+)\s*(tab|cap)').firstMatch(u);
      if (match != null) {
        _qtyPerPackage = int.tryParse(match.group(1) ?? '10') ?? 10;
      } else {
        _qtyPerPackage = 10; // افتراضي
      }
    }
    // ✅ شراب/زجاجة
    else if (u.contains('syrup') ||
        u.contains('bottle') ||
        u.contains('susp')) {
      _category = ProductCategory.syrups;
      _singleUnit = MedicineUnit.bottle;
      _hasPackage = false;
      _priceFor = 'single';
    }
    // ✅ حقن - أمبول أو فيال
    else if (u.contains('amp') ||
        u.contains('vial') ||
        u.contains('inj') ||
        u.contains('i.m') ||
        u.contains('i.v')) {
      _category = ProductCategory.injections;

      // تحديد أمبول أو فيال
      if (u.contains('vial')) {
        _singleUnit = MedicineUnit.vial;
      } else {
        _singleUnit = MedicineUnit.ampoule;
      }

      // هل له باكيت؟
      final match = RegExp(r'(\d+)\s*(amp|vial)').firstMatch(u);
      if (match != null) {
        final qty = int.tryParse(match.group(1) ?? '1') ?? 1;
        if (qty > 1) {
          _hasPackage = true;
          _qtyPerPackage = qty;
          _priceFor = 'package';
        } else {
          _hasPackage = false;
          _priceFor = 'single';
        }
      } else {
        _hasPackage = false;
        _priceFor = 'single';
      }
    }
    // ✅ كريم/مرهم/جل
    else if (u.contains('cream') || u.contains('oint') || u.contains('gel')) {
      _category = ProductCategory.creams;
      _singleUnit = MedicineUnit.tube;
      _hasPackage = false;
      _priceFor = 'single';
    }
    // ✅ قطرات
    else if (u.contains('drop') || u.contains('eye') || u.contains('ear')) {
      _category = ProductCategory.drops;
      _singleUnit = MedicineUnit.drops;
      _hasPackage = false;
      _priceFor = 'single';
    }
    // ✅ بخاخ
    else if (u.contains('spray') || u.contains('nasal')) {
      _category = ProductCategory.sprays;
      _singleUnit = MedicineUnit.spray;
      _hasPackage = false;
      _priceFor = 'single';
    }
    // ✅ تحاميل
    else if (u.contains('supp')) {
      _category = ProductCategory.suppositories;
      _singleUnit = MedicineUnit.suppository;

      final match = RegExp(r'(\d+)\s*supp').firstMatch(u);
      if (match != null) {
        _qtyPerPackage = int.tryParse(match.group(1) ?? '6') ?? 6;
        _hasPackage = true;
        _priceFor = 'package';
      } else {
        _qtyPerPackage = 6;
        _hasPackage = true;
        _priceFor = 'package';
      }
    }
    // ✅ الافتراضي
    else {
      _category = ProductCategory.tablets;
      _singleUnit = MedicineUnit.strip;
      _hasPackage = false;
      _priceFor = 'single';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 750,
        constraints: const BoxConstraints(maxHeight: 900),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildProductInfo(),
                const SizedBox(height: 16),
                _buildUnitsSection(),
                const SizedBox(height: 16),
                _buildPricingSection(),
                const SizedBox(height: 16),
                _buildExpiryDate(),
                const SizedBox(height: 24),
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
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_shopping_cart,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إضافة منتج جديد',
                style: GoogleFonts.tajawal(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'أدخل البيانات بوضوح',
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // اسم المنتج مع Autocomplete
        SizedBox(
          height: _showSuggestions ? 300 : 60,
          child: Stack(
            children: [
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[<>{}"\\\[\]]')),
                  LengthLimitingTextInputFormatter(200),
                ],
                decoration: InputDecoration(
                  labelText: 'اسم المنتج *',
                  hintText: 'ابدأ الكتابة للبحث...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medication),
                  labelStyle: GoogleFonts.tajawal(),
                ),
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'مطلوب';
                  if (InputSanitizer.containsXss(v!) ||
                      InputSanitizer.containsSqlInjection(v)) {
                    return 'اسم المنتج يحتوي على أحرف غير مسموح بها';
                  }
                  return null;
                },
              ),
              if (_showSuggestions && _suggestions.isNotEmpty)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 230),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final med = _suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.medication,
                                color: AppColors.primary),
                            title: Text(med['name'] ?? '',
                                style: GoogleFonts.tajawal(fontSize: 13)),
                            subtitle: Text(
                              '${med['manufacturer'] ?? ''} • ${med['price']} د.ع',
                              style: GoogleFonts.tajawal(fontSize: 11),
                            ),
                            onTap: () => _selectFromDatabase(med),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // الشركة والباركود
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _companyController,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[<>{}"\\\[\]]')),
                  LengthLimitingTextInputFormatter(100),
                ],
                decoration: InputDecoration(
                  labelText: 'الشركة',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.business),
                  labelStyle: GoogleFonts.tajawal(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _barcodeController,
                inputFormatters: InputSanitizer.barcodeFormatters,
                decoration: InputDecoration(
                  labelText: 'باركود',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                  labelStyle: GoogleFonts.tajawal(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // الفئة
        DropdownButtonFormField<ProductCategory>(
          initialValue: _category,
          decoration: InputDecoration(
            labelText: 'الفئة *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.category),
            labelStyle: GoogleFonts.tajawal(),
          ),
          items: ProductCategory.values
              .map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat.arabicName, style: GoogleFonts.tajawal()),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _category = v!),
        ),
      ],
    );
  }

  Widget _buildUnitsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'إعدادات الوحدات والتعبئة',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ الوحدة المفردة (واضحة)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الوحدة المفردة (الأساس)',
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<MedicineUnit>(
                      initialValue: _singleUnit,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        labelStyle: GoogleFonts.tajawal(),
                      ),
                      items: [
                        MedicineUnit.strip,
                        MedicineUnit.bottle,
                        MedicineUnit.ampoule,
                        MedicineUnit.vial,
                        MedicineUnit.tube,
                        MedicineUnit.suppository,
                        MedicineUnit.drops,
                        MedicineUnit.spray,
                      ]
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.arabicName,
                                    style: GoogleFonts.tajawal()),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _singleUnit = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ هل له تعبئة (باكيت/كرتون)؟
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _hasPackage,
                  onChanged: (v) => setState(() => _hasPackage = v ?? false),
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Text(
                    'هل المنتج يأتي في باكيت أو كرتون؟',
                    style: GoogleFonts.tajawal(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // ✅ إذا كان له باكيت - كم وحدة في الباكيت؟
          if (_hasPackage) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'كم ${_singleUnit.arabicName} في الباكيت/الكرتون؟',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _qtyPerPackage.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'مثال: 10',
                      labelStyle: GoogleFonts.tajawal(),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) =>
                        setState(() => _qtyPerPackage = int.tryParse(v) ?? 10),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '✅ 1 باكيت = $_qtyPerPackage ${_singleUnit.arabicName}',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
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

  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.amber.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_money,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'الأسعار والكمية',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ الكمية - ديناميكية حسب وجود الباكيت
          TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: InputDecoration(
              labelText: _hasPackage
                  ? 'الكمية (بالباكيت) *'
                  : 'الكمية (بالـ ${_singleUnit.arabicName}) *',
              hintText: _hasPackage
                  ? 'كم باكيت موجود؟'
                  : 'كم ${_singleUnit.arabicName} موجود؟',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.inventory),
              labelStyle: GoogleFonts.tajawal(),
              helperText: _hasPackage
                  ? 'سيتم حساب عدد ${_singleUnit.arabicName} تلقائياً'
                  : null,
              helperStyle: GoogleFonts.tajawal(
                fontSize: 11,
                color: AppColors.success,
              ),
            ),
            validator: (v) =>
                int.tryParse(v ?? '') == null ? 'أدخل رقم صحيح' : null,
          ),

          // ✅ عرض الحساب التلقائي للوحدات
          if (_hasPackage && _quantityController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'الإجمالي: ${(int.tryParse(_quantityController.text) ?? 0) * _qtyPerPackage} ${_singleUnit.arabicName}',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ✅ السعر المُدخل لـ ؟
          Text(
            'السعر المُدخل هو لـ:',
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _priceFor,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _priceFor = value);
            },
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('${_singleUnit.arabicName} واحد',
                        style: GoogleFonts.tajawal(fontSize: 13)),
                    value: 'single',
                    activeColor: AppColors.primary,
                    dense: true,
                  ),
                ),
                if (_hasPackage)
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('الباكيت كامل',
                          style: GoogleFonts.tajawal(fontSize: 13)),
                      value: 'package',
                      activeColor: AppColors.primary,
                      dense: true,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // الأسعار
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'سعر التكلفة *',
                    suffixText: 'د.ع',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.shopping_cart),
                    labelStyle: GoogleFonts.tajawal(),
                  ),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'سعر البيع *',
                    suffixText: 'د.ع',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.sell),
                    labelStyle: GoogleFonts.tajawal(),
                  ),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'مطلوب' : null,
                ),
              ),
            ],
          ),

          // ✅ عرض الأسعار المحسوبة
          if (_priceFor == 'package' && _hasPackage) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 الأسعار للوحدة المفردة:',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildCalculatedPrice(
                    'التكلفة',
                    double.tryParse(_costController.text) ?? 0,
                  ),
                  _buildCalculatedPrice(
                    'البيع',
                    double.tryParse(_priceController.text) ?? 0,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalculatedPrice(String label, double packagePrice) {
    final singlePrice = packagePrice / _qtyPerPackage;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label للـ${_singleUnit.arabicName}:',
          style:
              GoogleFonts.tajawal(fontSize: 11, color: AppColors.textSecondary),
        ),
        Text(
          '${singlePrice.toStringAsFixed(0)} د.ع',
          style: GoogleFonts.tajawal(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryDate() {
    bool showError = (_expiryDate == null);
    return GestureDetector(
      onTap: () async {
        final picked = await showMonthPicker(
          context: context,
          initialDate:
              _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
          firstDate: DateTime.now(),
          lastDate: DateTime(2040),
        );
        if (picked != null) {
          setState(
              () => _expiryDate = DateTime(picked.year, picked.month + 1, 0));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: showError ? Colors.red.shade700 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _expiryDate != null
                  ? 'الصلاحية: ${_expiryDate!.month}/${_expiryDate!.year}'
                  : 'تاريخ الصلاحية ',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: showError ? Colors.red.shade700 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.tajawal()),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveProduct,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text('حفظ المنتج', style: GoogleFonts.tajawal(fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dao = ProductDAO();
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery(
          'SELECT MAX(CAST(id AS INTEGER)) as maxId FROM products WHERE id GLOB "[0-9]*"');
      final maxId = (result.first['maxId'] as int?) ?? 0;
      final newId = (maxId + 1).toString();

      var quantity = int.parse(_quantityController.text);
      var costPrice = double.parse(_costController.text);
      var sellPrice = double.parse(_priceController.text);

      // ✅ تحويل الكمية من باكيت إلى وحدات أساسية
      if (_hasPackage) {
        quantity = quantity * _qtyPerPackage; // الكمية المُدخلة كانت بالباكيت
      }

      // ✅ تحويل الأسعار إذا كانت للباكيت
      if (_priceFor == 'package' && _hasPackage) {
        costPrice = costPrice / _qtyPerPackage;
        sellPrice = sellPrice / _qtyPerPackage;
      }

      // بناء unitInfo
      final Map<MedicineUnit, UnitInfo> unitInfo = {
        _singleUnit: UnitInfo(
          sellingPrice: sellPrice,
          costPrice: costPrice,
          conversionToBase: 1.0,
          description: _singleUnit.arabicName,
        ),
      };

      if (_hasPackage) {
        unitInfo[MedicineUnit.carton] = UnitInfo(
          sellingPrice: sellPrice * _qtyPerPackage,
          costPrice: costPrice * _qtyPerPackage,
          conversionToBase: _qtyPerPackage.toDouble(),
          description: 'باكيت = $_qtyPerPackage ${_singleUnit.arabicName}',
        );
      }

      final product = Product(
        id: newId,
        name: _nameController.text.trim(),
        scientificName: null,
        company: _companyController.text.trim().ifEmpty('غير محدد'),
        category: _category,
        barcode: _barcodeController.text.trim().ifEmpty('BARCODE$newId'),
        baseUnit: _singleUnit,
        unitInfo: unitInfo,
        currentStock: quantity.toDouble(),
        minStockLevel: 10.0,
        expiryDate: _expiryDate,
        productionDate: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dao.insert(product);

      if (!mounted) return;

      ref.invalidate(productsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ تم حفظ ${product.name}', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ: $e', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }
}

extension on String {
  String ifEmpty(String defaultValue) => isEmpty ? defaultValue : this;
}
