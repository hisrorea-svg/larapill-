import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/custom_month_picker.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/product_repository.dart';
import '../../../../core/models/shared/product.dart';
import '../../../../core/models/shared/medicine_unit.dart';
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

  // Price controllers for units
  final Map<MedicineUnit, TextEditingController> _sellingPriceControllers = {};
  final Map<MedicineUnit, TextEditingController> _costPriceControllers = {};

  // Dates
  DateTime? _expiryDate;
  DateTime? _productionDate;

  // Base Unit
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

      final productRepo = ref.read(productRepositoryProvider);
      final product = await productRepo.getProductById(widget.productId);

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

        // Base Unit
        _selectedBaseUnit = product.baseUnit;

        // Units data
        _unitsData = {};
        _sellingPriceControllers.clear();
        _costPriceControllers.clear();
        product.unitInfo.forEach((unit, info) {
          _unitsData[unit] = {
            'sellingPrice': info.sellingPrice,
            'costPrice': info.costPrice,
            'conversionToBase': info.conversionToBase,
            'description': info.description,
            'quantity': info.quantity ?? 0,
          };
          // Create controllers for prices
          _sellingPriceControllers[unit] =
              TextEditingController(text: info.sellingPrice.toString());
          _costPriceControllers[unit] =
              TextEditingController(text: info.costPrice.toString());
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBasicInfoSection(),
                            const SizedBox(height: 20),
                            _buildStockSection(),
                            const SizedBox(height: 20),
                            _buildExpiryDateSection(),
                            const SizedBox(height: 20),
                            _buildUnitsSection(), // ✅ قسم الوحدات والأسعار
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooter(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.edit,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تعديل المنتج',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _product?.name ?? '',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          tooltip: 'إغلاق',
        ),
      ],
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

  // ✅ قسم تاريخ الصلاحية فقط (بدون تاريخ الإنتاج)
  Widget _buildExpiryDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('تاريخ الصلاحية', Icons.calendar_today),
        const SizedBox(height: 12),
        _buildDateField('تاريخ الصلاحية', _expiryDate,
            (date) => setState(() => _expiryDate = date)),
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
    final sellingPriceController = _sellingPriceControllers[unit];
    final costPriceController = _costPriceControllers[unit];

    if (sellingPriceController == null || costPriceController == null) {
      return const SizedBox.shrink();
    }

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
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
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
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
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
                    controller: sellingPriceController,
                    decoration: InputDecoration(
                      labelText: 'سعر البيع (د.ع)',
                      labelStyle: const TextStyle(
                        fontFamily: 'Tajawal',
                      ),
                      prefixIcon: const Icon(Icons.sell, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: costPriceController,
                    decoration: InputDecoration(
                      labelText: 'سعر التكلفة (د.ع)',
                      labelStyle: const TextStyle(
                        fontFamily: 'Tajawal',
                      ),
                      prefixIcon: const Icon(Icons.shopping_cart, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                    ),
                    keyboardType: TextInputType.number,
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
          style: const TextStyle(
            fontFamily: 'Tajawal',
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
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
        ),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      style: const TextStyle(
        fontFamily: 'Tajawal',
      ),
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
          labelStyle: const TextStyle(
            fontFamily: 'Tajawal',
          ),
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
          style: const TextStyle(
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(Function(DateTime?) onSelected) async {
    final selected = await showCustomMonthPicker(
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
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 22),
                        SizedBox(width: 12),
                        Text(
                          'حفظ التغييرات',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
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
        final sellingPriceController = _sellingPriceControllers[unit];
        final costPriceController = _costPriceControllers[unit];

        updatedUnitInfo[unit] = UnitInfo(
          sellingPrice: sellingPriceController != null
              ? double.tryParse(sellingPriceController.text) ?? 0.0
              : data['sellingPrice'],
          costPrice: costPriceController != null
              ? double.tryParse(costPriceController.text) ?? 0.0
              : data['costPrice'],
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
      final productRepo = ref.read(productRepositoryProvider);
      await productRepo.updateProduct(updatedProduct);

      if (!mounted) return;

      // تحديث الـ providers
      ref.invalidate(productsProvider);

      AppToast.success(context, 'تم تحديث المنتج بنجاح ✓');

      widget.onProductUpdated();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      AppToast.error(context, 'فشل حفظ التغييرات: $e');
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
    // Dispose price controllers
    for (final controller in _sellingPriceControllers.values) {
      controller.dispose();
    }
    for (final controller in _costPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
