import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/main_layout.dart';

// Provider لحالة الـ Sidebar (موسع أو مطوي)
final sidebarExpandedProvider = StateProvider<bool>((ref) => true);

class SidebarMenu extends ConsumerWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final isExpanded = ref.watch(sidebarExpandedProvider);
    const animationDuration = Duration(milliseconds: 300);

    return Container(
      width: isExpanded ? 200 : 70,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: animationDuration,
        curve: Curves.easeInOut,
        child: SizedBox(
          width: isExpanded ? 200 : 70,
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Column(
              children: [
                // Menu Items
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: false,
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      children: [
                        _buildMenuItem(
                          icon: Icons.home_filled,
                          title: 'الرئيسية',
                          index: 0,
                          selectedIndex: selectedIndex,
                          isExpanded: isExpanded,
                          onTap: () => ref
                              .read(selectedIndexProvider.notifier)
                              .state = 0,
                        ),
                        _buildMenuItem(
                          icon: Icons.shopping_cart_outlined,
                          title: 'نقطة البيع',
                          index: 1,
                          selectedIndex: selectedIndex,
                          isExpanded: isExpanded,
                          onTap: () => ref
                              .read(selectedIndexProvider.notifier)
                              .state = 1,
                        ),
                        _buildMenuItem(
                          icon: Icons.inventory_2_outlined,
                          title: 'إدارة المخزون',
                          index: 2,
                          selectedIndex: selectedIndex,
                          isExpanded: isExpanded,
                          onTap: () => ref
                              .read(selectedIndexProvider.notifier)
                              .state = 2,
                        ),
                        _buildMenuItem(
                          icon: Icons.local_shipping_outlined,
                          title: 'المشتريات والطلبيات',
                          index: 3,
                          selectedIndex: selectedIndex,
                          isExpanded: isExpanded,
                          onTap: () => ref
                              .read(selectedIndexProvider.notifier)
                              .state = 3,
                        ),
                        _buildMenuItem(
                          icon: Icons.assignment_return_outlined,
                          title: 'إدارة المرتجعات',
                          index: 4,
                          selectedIndex: selectedIndex,
                          isExpanded: isExpanded,
                          onTap: () => ref
                              .read(selectedIndexProvider.notifier)
                              .state = 4,
                        ),
                        _buildMenuItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'إدارة الديون',
                          index: 5,
                          selectedIndex: selectedIndex,
                          isExpanded: isExpanded,
                          onTap: () => ref
                              .read(selectedIndexProvider.notifier)
                              .state = 5,
                        ),
                        _buildMenuItem(
                          icon: Icons.assessment_outlined,
                          title: 'التقارير',
                          index: 6,
                          selectedIndex: selectedIndex,
                          isExpanded: isExpanded,
                          onTap: () => ref
                              .read(selectedIndexProvider.notifier)
                              .state = 6,
                        ),
                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          title: 'الإعدادات',
                          index: 7,
                          selectedIndex: selectedIndex,
                          isExpanded: isExpanded,
                          onTap: () => ref
                              .read(selectedIndexProvider.notifier)
                              .state = 7,
                        ),
                      ],
                    ),
                  ),
                ),

                // Collapse/Expand Button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.5),
                    border: const Border(
                      top: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ref.read(sidebarExpandedProvider.notifier).state =
                            !isExpanded;
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isExpanded ? 12 : 8,
                          vertical: 8,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: isExpanded ? 234 : 64,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.arrow_back_outlined
                                  : Icons.arrow_forward_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            if (isExpanded) ...[
                              const SizedBox(width: 8),
                              const Text(
                                'إخفاء',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    required int selectedIndex,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final isSelected = index == selectedIndex;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isExpanded ? 12 : 6,
        vertical: 2,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 6,
              vertical: 14,
            ),
            constraints: BoxConstraints(
              maxWidth: isExpanded ? 218 : 68,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 30,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
                if (isSelected && isExpanded)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
