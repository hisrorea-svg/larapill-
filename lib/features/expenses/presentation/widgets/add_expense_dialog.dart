import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../domain/entities/expense.dart';
import '../providers/expenses_management_provider.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;

  const AddExpenseDialog({super.key, this.expenseToEdit});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.expenseToEdit?.amount.toString() ?? '');
    _noteController =
        TextEditingController(text: widget.expenseToEdit?.note ?? '');

    if (widget.expenseToEdit != null) {
      _selectedCategoryId = widget.expenseToEdit!.categoryId;
      _selectedDate = widget.expenseToEdit!.date;
      _isRecurring = widget.expenseToEdit!.isRecurring;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expensesManagementProvider);
    final isEditing = widget.expenseToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'تعديل المصروف' : 'إضافة مصروف جديد',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Category Selection
              const Text('اختر الفئة',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              state.categories.when(
                data: (categories) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: categories.map((cat) {
                    final isSelected = _selectedCategoryId == cat.id;
                    return FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      checkmarkColor: Colors.white,
                      selectedColor: Color(cat.color),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? cat.id : null;
                        });
                      },
                      avatar: Icon(
                        IconData(
                          int.tryParse(cat.icon) ?? Icons.error.codePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                        size: 18,
                        color: isSelected ? Colors.white : Color(cat.color),
                      ),
                    );
                  }).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading categories: $e'),
              ),
              if (_selectedCategoryId == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'يرجى اختيار فئة',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // Amount & Date
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'مطلوب';
                        }
                        if (double.tryParse(value) == null) {
                          return 'رقم غير صحيح';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'التاريخ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          intl.DateFormat('yyyy-MM-dd').format(_selectedDate),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Recurring Toggle
              SwitchListTile(
                title: const Text('مصروف متكرر شهرياً'),
                subtitle: const Text(
                    'سيتم تكراره تلقائياً في نفس اليوم من كل شهر (ميزة مستقبلية)'),
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),

              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          _selectedCategoryId != null) {
                        if (isEditing) {
                          ref
                              .read(expensesManagementProvider.notifier)
                              .updateExpense(
                                id: widget.expenseToEdit!.id,
                                categoryId: _selectedCategoryId!,
                                amount: double.parse(_amountController.text),
                                date: _selectedDate,
                                note: _noteController.text.isEmpty
                                    ? null
                                    : _noteController.text,
                                isRecurring: _isRecurring,
                              );
                        } else {
                          ref
                              .read(expensesManagementProvider.notifier)
                              .addExpense(
                                categoryId: _selectedCategoryId!,
                                amount: double.parse(_amountController.text),
                                date: _selectedDate,
                                note: _noteController.text.isEmpty
                                    ? null
                                    : _noteController.text,
                                isRecurring: _isRecurring,
                              );
                        }
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
