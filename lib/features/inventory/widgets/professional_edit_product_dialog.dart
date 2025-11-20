import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../database/daos/product_dao.dart';
import '../../../models/product.dart';
import '../../../models/medicine_unit.dart';
import '../providers/inventory_providers.dart';

class ProfessionalEditProductDialog extends ConsumerStatefulWidget {
  final String productId;
  final VoidCallback onProductUpdated;

  const ProfessionalEditProductDialog({
    super.key,
    required this.productId,
    required this.onProductUpdated,
  });

  @override
  ConsumerState<ProfessionalEditProductDialog> createState() =>
      _ProfessionalEditProductDialogState();
}

class _ProfessionalEditProductDialogState
    extends ConsumerState<ProfessionalEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productDao = ProductDAO();

  bool _isLoading = true;
  bool _isSaving = false;
  Product? _product;

  // Controllers
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minStockController = TextEditingController();

  // Dates
  DateTime? _expiryDate;
  DateTime? _productionDate;

  // Category & Base Unit
  ProductCategory? _selectedCategory;
  MedicineUnit? _selectedBaseUnit;

  // Units info
  Map<MedicineUnit, Map<String, dynamic>> _unitsData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
    });
  }

  Future<void> _loadProduct() async {
    try {
      setState(() => _isLoading = true);

      final product = await _productDao.findById(widget.productId);

      if (product == null) {
        throw Exception('المنتج غير موجود');
      }

      if (!mounted) return;

      setState(() {
        _product = product;

        // Fill basic info
        _nameController.text = product.name;
        _scientificNameController.text = product.scientificName ?? '';
        _companyController.text = product.company;
        _barcodeController.text = product.barcode;
        _currentStockController.text = product.currentStock.toInt().toString();
        _minStockController.text = product.minStockLevel.toInt().toString();

        // Dates
        _expiryDate = product.expiryDate;
        _productionDate = product.productionDate;

        // Category & Base Unit
        _selectedCategory = product.category;
        _selectedBaseUnit = product.baseUnit;

        // Units data
        _unitsData = {};
        product.unitInfo.forEach((unit, info) {
          _unitsData[unit] = {
            'sellingPrice': info.sellingPrice,
            'costPrice': info.costPrice,
            'conversionToBase': info.conversionToBase,
            'description': info.description,
            'quantity': info.quantity ?? 0,
          };
        });

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تحميل المنتج: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                            _buildBasicInfoSection(),
                            const SizedBox(height: 24),
                            _buildCategoryAndUnitSection(),
                            const SizedBox(height: 24),
                            _buildStockSection(),
                            const SizedBox(height: 24),
                            _buildDatesSection(),
                            const SizedBox(height: 24),
                            _buildUnitsSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildFooter(),
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
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعديل المنتج',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _product?.name ?? '',
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('المعلومات الأساسية', Icons.info_outline),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _nameController,
                label: 'اسم المنتج *',
                icon: Icons.medication,
                required: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _barcodeController,
                label: 'الباركود *',
                icon: Icons.qr_code,
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _scientificNameController,
                label: 'الاسم العلمي',
                icon: Icons.science,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _companyController,
                label: 'الشركة المصنعة *',
                icon: Icons.business,
                required: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryAndUnitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('التصنيف والوحدة', Icons.category),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ProductCategory>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'الفئة *',
                  labelStyle: GoogleFonts.tajawal(),
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                items: ProductCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category.arabicName,
                      style: GoogleFonts.tajawal(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) =>
                    value == null ? 'الرجاء اختيار الفئة' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<MedicineUnit>(
                initialValue: _selectedBaseUnit,
                decoration: InputDecoration(
                  labelText: 'الوحدة الأساسية *',
                  labelStyle: GoogleFonts.tajawal(),
                  prefixIcon: const Icon(Icons.inventory_2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                items: MedicineUnit.values.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(
                      unit.arabicName,
                      style: GoogleFonts.tajawal(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedBaseUnit = value);
                },
                validator: (value) =>
                    value == null ? 'الرجاء اختيار الوحدة الأساسية' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('المخزون', Icons.storage),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _currentStockController,
                label: 'الكمية الحالية',
                icon: Icons.inventory,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _minStockController,
                label: 'الحد الأدنى للمخزون',
                icon: Icons.warning_amber,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('التواريخ', Icons.calendar_today),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildDateField('تاريخ الإنتاج', _productionDate,
                    (date) => setState(() => _productionDate = date))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildDateField('تاريخ الصلاحية', _expiryDate,
                    (date) => setState(() => _expiryDate = date))),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitsSection() {
    if (_unitsData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('وحدات البيع والأسعار', Icons.attach_money),
        const SizedBox(height: 16),
        ..._unitsData.entries.map((entry) {
          return _buildUnitCard(entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildUnitCard(MedicineUnit unit, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    unit.arabicName,
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (data['conversionToBase'] > 1)
                  Text(
                    'الواحد = ${data['conversionToBase'].toInt()} ${_selectedBaseUnit?.arabicName ?? ''}',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: data['sellingPrice'].toString(),
                    decoration: InputDecoration(
                      labelText: 'سعر البيع (د.ع)',
                      labelStyle: GoogleFonts.tajawal(),
                      prefixIcon: const Icon(Icons.sell, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    style: GoogleFonts.tajawal(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      data['sellingPrice'] = double.tryParse(value) ?? 0.0;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: data['costPrice'].toString(),
                    decoration: InputDecoration(
                      labelText: 'سعر التكلفة (د.ع)',
                      labelStyle: GoogleFonts.tajawal(),
                      prefixIcon: const Icon(Icons.shopping_cart, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    style: GoogleFonts.tajawal(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      data['costPrice'] = double.tryParse(value) ?? 0.0;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.tajawal(),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      style: GoogleFonts.tajawal(),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: required
          ? (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, Function(DateTime?) onSelected) {
    return InkWell(
      onTap: () => _selectDate(onSelected),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.tajawal(),
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        child: Text(
          date != null
              ? '${date.year}-${date.month.toString().padLeft(2, '0')}'
              : 'اختر التاريخ',
          style: GoogleFonts.tajawal(),
        ),
      ),
    );
  }

  Future<void> _selectDate(Function(DateTime?) onSelected) async {
    final selected = await showMonthPicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (selected != null) {
      // ✅ تحويل التاريخ لآخر يوم في الشهر المختار
      final lastDayOfMonth = DateTime(selected.year, selected.month + 1, 0);
      onSelected(lastDayOfMonth);
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Text(
                'إلغاء',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'حفظ التغييرات',
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _product == null) return;

    setState(() => _isSaving = true);

    try {
      // إنشاء Map لمعلومات الوحدات المحدثة
      final updatedUnitInfo = <MedicineUnit, UnitInfo>{};

      _unitsData.forEach((unit, data) {
        updatedUnitInfo[unit] = UnitInfo(
          sellingPrice: data['sellingPrice'],
          costPrice: data['costPrice'],
          conversionToBase: data['conversionToBase'],
          description: data['description'],
          quantity: data['quantity'],
        );
      });

      // إنشاء المنتج المحدث
      final updatedProduct = Product(
        id: _product!.id,
        name: _nameController.text.trim(),
        scientificName: _scientificNameController.text.trim().isNotEmpty
            ? _scientificNameController.text.trim()
            : null,
        company: _companyController.text.trim(),
        category: _selectedCategory!,
        barcode: _barcodeController.text.trim(),
        baseUnit: _selectedBaseUnit!,
        currentStock: double.tryParse(_currentStockController.text) ?? 0.0,
        minStockLevel: double.tryParse(_minStockController.text) ?? 0.0,
        expiryDate: _expiryDate,
        productionDate: _productionDate,
        unitInfo: updatedUnitInfo,
        createdAt: _product!.createdAt,
        updatedAt: DateTime.now(),
      );

      // حفظ في قاعدة البيانات
      final success = await _productDao.update(updatedProduct);

      if (!mounted) return;

      if (success) {
        // تحديث الـ providers
        ref.invalidate(productsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث المنتج بنجاح ✓',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        widget.onProductUpdated();
        Navigator.pop(context);
      } else {
        throw Exception('فشل التحديث');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل حفظ التغييرات: $e',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _companyController.dispose();
    _barcodeController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }
}
