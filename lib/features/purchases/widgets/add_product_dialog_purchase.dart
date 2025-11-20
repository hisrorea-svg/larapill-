import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/daily_purchase_provider.dart';

class AddPurchaseProductDialog extends ConsumerStatefulWidget {
  const AddPurchaseProductDialog({super.key});

  @override
  ConsumerState<AddPurchaseProductDialog> createState() =>
      _AddPurchaseProductDialogState();
}

class _AddPurchaseProductDialogState
    extends ConsumerState<AddPurchaseProductDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '10');
  final TextEditingController _unitController = TextEditingController();
  bool _isLoading = false;
  List<String> _medsSuggestions = [];
  bool _isLoadingMeds = true;

  @override
  void initState() {
    super.initState();
    _loadMedsSuggestions();
  }

  Future<void> _loadMedsSuggestions() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/meds.json');
      final List<dynamic> medsData = json.decode(jsonString);

      setState(() {
        _medsSuggestions = medsData
            .map((item) => item['name'] as String)
            .toSet()
            .toList()
          ..sort();
        _isLoadingMeds = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMeds = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
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
                  child: Text(
                    'إضافة منتج للطلبية',
                    style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // حقل اسم المنتج مع Autocomplete
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                final searchLower = textEditingValue.text.toLowerCase();
                return _medsSuggestions.where((String option) {
                  return option.toLowerCase().contains(searchLower);
                }).take(5);
              },
              onSelected: (String selection) {
                _nameController.text = selection;
              },
              fieldViewBuilder: (
                BuildContext context,
                TextEditingController fieldController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                // مزامنة مع controller الرئيسي
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (fieldController.text != _nameController.text) {
                    fieldController.text = _nameController.text;
                  }
                });

                return TextField(
                  controller: fieldController,
                  focusNode: focusNode,
                  autofocus: true,
                  onChanged: (value) {
                    _nameController.text = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'اسم المنتج',
                    labelStyle: GoogleFonts.tajawal(),
                    hintText: 'مثال: شراب راستول',
                    hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                    prefixIcon: const Icon(Icons.medication),
                    suffixIcon: _isLoadingMeds
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  style: GoogleFonts.tajawal(fontSize: 16),
                  textInputAction: TextInputAction.next,
                );
              },
              optionsViewBuilder: (
                BuildContext context,
                AutocompleteOnSelected<String> onSelected,
                Iterable<String> options,
              ) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.medication,
                                      size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: GoogleFonts.tajawal(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // حقل الكمية والوصف في صف واحد
            Row(
              children: [
                // حقل الكمية
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'الكمية',
                      labelStyle: GoogleFonts.tajawal(),
                      hintText: '10',
                      hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                    ),
                    style: GoogleFonts.tajawal(fontSize: 16),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                // حقل الوصف (باكيت، شريط، علبة)
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _unitController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      labelStyle: GoogleFonts.tajawal(),
                      hintText: 'باكيت، شريط، علبة',
                      hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                    ),
                    style: GoogleFonts.tajawal(fontSize: 16),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addProduct(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // زر الإضافة
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'إضافة للطلبية',
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProduct() async {
    final productName = _nameController.text.trim();

    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الرجاء إدخال اسم المنتج',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final quantityText = _quantityController.text.trim();
    if (quantityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الرجاء إدخال الكمية',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الرجاء إدخال كمية صحيحة',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // استخدام timestamp كـ ID فريد
      final productId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
      final unit = _unitController.text.trim();

      // دمج الكمية مع الوصف للعرض
      final displayQuantity =
          unit.isEmpty ? quantity.toString() : '$quantity $unit';

      await ref.read(dailyPurchaseNotifierProvider.notifier).addManualRequest(
            productId: productId,
            productName: productName,
            quantity: quantity,
            unit: unit, // إضافة الوحدة
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تمت إضافة $productName - $displayQuantity للطلبية ✓',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
