import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../screens/main_layout.dart';
import 'package:pelaicons/pelaicons.dart';

class SidebarMenu extends ConsumerWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    return Container(
      width: 250,
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
                    icon: Pelaicons.homeBold,
                    title: 'الرئيسية',
                    index: 0,
                    selectedIndex: selectedIndex,
                    onTap: () =>
                        ref.read(selectedIndexProvider.notifier).state = 0,
                  ),
                  _buildMenuItem(
                    icon: Icons.point_of_sale,
                    title: 'نقطة البيع',
                    index: 1,
                    selectedIndex: selectedIndex,
                    onTap: () =>
                        ref.read(selectedIndexProvider.notifier).state = 1,
                  ),
                  _buildMenuItem(
                    icon: Icons.inventory_2,
                    title: 'إدارة المخزون',
                    index: 2,
                    selectedIndex: selectedIndex,
                    onTap: () =>
                        ref.read(selectedIndexProvider.notifier).state = 2,
                  ),
                  _buildMenuItem(
                    icon: Icons.shopping_cart,
                    title: 'المشتريات والطلبيات',
                    index: 3,
                    selectedIndex: selectedIndex,
                    onTap: () =>
                        ref.read(selectedIndexProvider.notifier).state = 3,
                  ),
                  _buildMenuItem(
                    icon: Icons.assignment_return,
                    title: 'إدارة المرتجعات',
                    index: 4,
                    selectedIndex: selectedIndex,
                    onTap: () =>
                        ref.read(selectedIndexProvider.notifier).state = 4,
                  ),
                  _buildMenuItem(
                    icon: Icons.account_balance_wallet,
                    title: 'إدارة الديون',
                    index: 5,
                    selectedIndex: selectedIndex,
                    onTap: () =>
                        ref.read(selectedIndexProvider.notifier).state = 5,
                  ),
                  _buildMenuItem(
                    icon: Icons.assessment,
                    title: 'التقارير',
                    index: 6,
                    selectedIndex: selectedIndex,
                    onTap: () =>
                        ref.read(selectedIndexProvider.notifier).state = 6,
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'الإعدادات',
                    index: 7,
                    selectedIndex: selectedIndex,
                    onTap: () =>
                        ref.read(selectedIndexProvider.notifier).state = 7,
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              border: const Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      // إضافة Expanded
                      child: Text(
                        'متصل - آخر مزامنة: الآن',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          color: AppColors.success,
                        ),
                        overflow: TextOverflow.ellipsis, // إضافة overflow
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'الإصدار 1.0.0',
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    required int selectedIndex,
    required VoidCallback onTap,
  }) {
    final isSelected = index == selectedIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
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
                const SizedBox(width: 15),
                Expanded(
                  // إضافة Expanded للنص
                  child: Text(
                    title,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis, // منع الـ overflow
                    maxLines: 2, // السماح بسطرين كحد أقصى
                  ),
                ),
                if (isSelected)
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
