import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expenses_management_provider.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/manage_categories_dialog.dart';

class ExpensesManagementScreen extends ConsumerStatefulWidget {
  const ExpensesManagementScreen({super.key});

  @override
  ConsumerState<ExpensesManagementScreen> createState() =>
      _ExpensesManagementScreenState();
}

class _ExpensesManagementScreenState
    extends ConsumerState<ExpensesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expensesManagementProvider);
    final notifier = ref.read(expensesManagementProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المصروفات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'إدارة الفئات',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ManageCategoriesDialog(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddExpenseDialog(),
          );
        },
        label: const Text('إضافة مصروف'),
        icon: const Icon(Icons.add),
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            // Month Selector & Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      notifier.changeMonth(DateTime(
                        state.selectedMonth.year,
                        state.selectedMonth.month - 1,
                      ));
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'ar').format(state.selectedMonth),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      notifier.changeMonth(DateTime(
                        state.selectedMonth.year,
                        state.selectedMonth.month + 1,
                      ));
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Faded Summary Card - Comfortable Color (Indigo)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.withValues(alpha: 0.0),
                        Colors.indigo.withValues(alpha: 0.8),
                        Colors.indigo.withValues(alpha: 0.8),
                        Colors.indigo.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                    child: state.expenses.when(
                      data: (expenses) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 28,
                                color: Colors.white,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'إجمالي مصروفات الشهر',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            NumberFormat.currency(
                                    symbol: 'د.ع ', decimalDigits: 0)
                                .format(state.totalExpenses),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),

            // 4-Column Grid Layout
            Expanded(
              child: state.expenses.when(
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return const Center(child: Text('لا توجد مصروفات'));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // 4 Columns
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      mainAxisExtent: 110, // Smaller Rectangles
                    ),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final categoryColor = Color(expense.categoryColor);

                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius:
                              BorderRadius.circular(16), // Softer corners
                          border: Border.all(
                            color: categoryColor.withValues(alpha: 0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // 1. Premium Gradient Background (Subtle & Deep)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        categoryColor.withValues(alpha: 0.08),
                                        Colors.white.withValues(
                                            alpha: 0.05), // Light gloss
                                      ],
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                    ),
                                  ),
                                ),
                              ),

                              // 2. Amount - ABSOLUTE CENTER (The Hero)
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      NumberFormat.currency(
                                              symbol: '', decimalDigits: 0)
                                          .format(expense.amount),
                                      style: TextStyle(
                                        fontFamily:
                                            'Roboto', // Clean number font
                                        fontWeight: FontWeight.w900,
                                        fontSize: 24, // Very Large
                                        color: categoryColor.withValues(
                                            alpha: 1.0),
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 3. Category Name - Bottom Center
                              Positioned(
                                bottom: 10,
                                left: 4,
                                right: 4,
                                child: Text(
                                  expense.categoryName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // 4. Category Icon - Top Right (Subtle branding)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    IconData(
                                      int.parse(expense.categoryIcon),
                                      fontFamily: 'MaterialIcons',
                                    ),
                                    color: categoryColor,
                                    size: 16,
                                  ),
                                ),
                              ),

                              // 5. Delete Action - Top Left (Restored & Stylish)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.hardEdge,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: Colors.red.withValues(alpha: 0.6),
                                      size: 18,
                                    ),
                                    splashColor:
                                        Colors.red.withValues(alpha: 0.1),
                                    highlightColor:
                                        Colors.red.withValues(alpha: 0.1),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          title: const Text('حذف المصروف'),
                                          content: const Text(
                                              'هل أنت متأكد من حذف هذا المصروف؟'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('إلغاء'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text(
                                                'حذف',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        notifier.deleteExpense(expense.id);
                                      }
                                    },
                                  ),
                                ),
                              ),

                              // Edit Action - Tap on Card
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AddExpenseDialog(
                                          expenseToEdit: expense,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, stack) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
