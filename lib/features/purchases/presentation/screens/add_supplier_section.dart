import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/datasources/local/suppliers_dao.dart';

class AddSupplierSection extends ConsumerStatefulWidget {
  const AddSupplierSection({super.key});

  @override
  ConsumerState<AddSupplierSection> createState() => _AddSupplierSectionState();
}

class _AddSupplierSectionState extends ConsumerState<AddSupplierSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactController = TextEditingController();
  String _paymentType = 'cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supplier = SupplierItem(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        contactPerson: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        paymentType: _paymentType,
      );

      await SuppliersDao().addSupplier(supplier);

      if (!mounted) return;
      AppToast.success(context, 'تم إضافة المورد بنجاح');

      // Reset form
      _nameController.clear();
      _phoneController.clear();
      _contactController.clear();
      setState(() => _paymentType = 'cash');

      // Update Providers
      ref.invalidate(suppliersProvider);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'خطأ في إضافة المورد: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon & Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_add_alt_1,
                                size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'تسجيل مورد جديد',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'أدخل بيانات المورد للتواصل والتعاملات المالية',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Fields
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v?.trim().isEmpty == true
                          ? 'يرجى إدخال اسم المورد'
                          : null,
                      decoration:
                          _inputDecoration('اسم المورد', Icons.business),
                      style: const TextStyle(fontFamily: 'Tajawal'),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration:
                                _inputDecoration('رقم الهاتف', Icons.phone),
                            style: const TextStyle(fontFamily: 'Tajawal'),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _contactController,
                            decoration:
                                _inputDecoration('مسؤول التواصل', Icons.person),
                            style: const TextStyle(fontFamily: 'Tajawal'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _paymentType,
                      decoration:
                          _inputDecoration('نوع التعامل', Icons.payment),
                      items: const [
                        DropdownMenuItem(
                            value: 'cash',
                            child: Text('نقد',
                                style: TextStyle(fontFamily: 'Tajawal'))),
                        DropdownMenuItem(
                            value: 'weekly',
                            child: Text('أسبوعي',
                                style: TextStyle(fontFamily: 'Tajawal'))),
                        DropdownMenuItem(
                            value: 'monthly',
                            child: Text('شهري',
                                style: TextStyle(fontFamily: 'Tajawal'))),
                        DropdownMenuItem(
                            value: 'credit',
                            child: Text('آجل',
                                style: TextStyle(fontFamily: 'Tajawal'))),
                      ],
                      onChanged: (v) => setState(() => _paymentType = v!),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveSupplier,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                          _isLoading ? 'جاري الحفظ...' : 'حفظ بيانات المورد',
                          style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          fontFamily: 'Tajawal', color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
