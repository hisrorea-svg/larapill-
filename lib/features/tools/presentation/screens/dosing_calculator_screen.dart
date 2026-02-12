import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/usecases/calculate_dose_usecase.dart';
import '../providers/tools_providers.dart';

/// Screen for calculating pediatric medication doses.
///
/// Allows users to search for medicines and calculate doses
/// based on either weight or age.
class DosingCalculatorScreen extends ConsumerWidget {
  const DosingCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(medicinesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: medicinesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => _buildErrorState(error.toString()),
          data: (medicines) => _DosingCalculatorContent(medicines: medicines),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medication_liquid, color: Colors.white, size: 24),
          SizedBox(width: 10),
          Text(
            'حاسبة الجرعات',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'خطأ في تحميل البيانات',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Main content of the dosing calculator.
class _DosingCalculatorContent extends ConsumerStatefulWidget {
  final List<Medicine> medicines;

  const _DosingCalculatorContent({required this.medicines});

  @override
  ConsumerState<_DosingCalculatorContent> createState() =>
      _DosingCalculatorContentState();
}

class _DosingCalculatorContentState
    extends ConsumerState<_DosingCalculatorContent> {
  final _searchController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dosingCalculatorProvider);
    final notifier = ref.read(dosingCalculatorProvider.notifier);

    final filteredMedicines = _searchQuery.isEmpty
        ? widget.medicines
        : widget.medicines
            .where((m) =>
                m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                m.category.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Row(
      children: [
        // Medicine list sidebar
        _MedicineSidebar(
          medicines: filteredMedicines,
          selectedMedicine: state.selectedMedicine,
          searchController: _searchController,
          onSearchChanged: (value) => setState(() => _searchQuery = value),
          onMedicineSelected: (medicine) {
            notifier.selectMedicine(medicine);
            _weightController.clear();
            _ageController.clear();
          },
        ),
        // Main calculator area
        Expanded(
          child: state.selectedMedicine == null
              ? const _EmptyState()
              : _CalculatorPanel(
                  medicine: state.selectedMedicine!,
                  useAge: state.useAge,
                  result: state.result,
                  weightController: _weightController,
                  ageController: _ageController,
                  onUseAgeChanged: notifier.setUseAge,
                  onWeightChanged: notifier.setWeight,
                  onAgeChanged: notifier.setAge,
                  onCalculate: notifier.calculateDose,
                ),
        ),
      ],
    );
  }
}

/// Sidebar containing the list of medicines with search.
class _MedicineSidebar extends StatelessWidget {
  final List<Medicine> medicines;
  final Medicine? selectedMedicine;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Medicine> onMedicineSelected;

  const _MedicineSidebar({
    required this.medicines,
    required this.selectedMedicine,
    required this.searchController,
    required this.onSearchChanged,
    required this.onMedicineSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom:
                    BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
              ),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن دواء...',
                hintStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          // Medicine count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.background.withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(
                  Icons.medication,
                  size: 16,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  '${medicines.length} دواء',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Medicine list
          Expanded(
            child: ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final medicine = medicines[index];
                final isSelected = selectedMedicine?.name == medicine.name;

                return _MedicineListTile(
                  medicine: medicine,
                  isSelected: isSelected,
                  onTap: () => onMedicineSelected(medicine),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// List tile for a medicine item.
class _MedicineListTile extends StatelessWidget {
  final Medicine medicine;
  final bool isSelected;
  final VoidCallback onTap;

  const _MedicineListTile({
    required this.medicine,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            // Medicine info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    medicine.category,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when no medicine is selected.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_liquid_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'اختر دواء من القائمة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابحث واختر الدواء لحساب الجرعة المناسبة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Main calculator panel.
class _CalculatorPanel extends StatelessWidget {
  final Medicine medicine;
  final bool useAge;
  final DoseResult? result;
  final TextEditingController weightController;
  final TextEditingController ageController;
  final ValueChanged<bool> onUseAgeChanged;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onAgeChanged;
  final VoidCallback onCalculate;

  const _CalculatorPanel({
    required this.medicine,
    required this.useAge,
    required this.result,
    required this.weightController,
    required this.ageController,
    required this.onUseAgeChanged,
    required this.onWeightChanged,
    required this.onAgeChanged,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MedicineInfoCard(medicine: medicine),
          const SizedBox(height: 16),
          _InputCard(
            useAge: useAge,
            weightController: weightController,
            ageController: ageController,
            onUseAgeChanged: onUseAgeChanged,
            onWeightChanged: onWeightChanged,
            onAgeChanged: onAgeChanged,
          ),
          const SizedBox(height: 16),
          _CalculateButton(onPressed: onCalculate),
          const SizedBox(height: 16),
          if (result != null) _ResultCard(result: result!),
        ],
      ),
    );
  }
}

/// Card displaying medicine information.
class _MedicineInfoCard extends StatelessWidget {
  final Medicine medicine;

  const _MedicineInfoCard({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and route badges
          Row(
            children: [
              _Badge(
                text: medicine.category,
                color: AppColors.primary,
                icon: Icons.category,
              ),
              const SizedBox(width: 8),
              _Badge(
                text: medicine.route,
                color: Colors.green,
                icon: Icons.route,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Medicine name
          Text(
            medicine.name,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          // Indication
          Text(
            medicine.indication,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Standard dose
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.1),
                  Colors.orange.withValues(alpha: 0.05),
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'الجرعة القياسية: ${medicine.standardDose}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge widget for category and route.
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Badge({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for weight/age input.
class _InputCard extends StatelessWidget {
  final bool useAge;
  final TextEditingController weightController;
  final TextEditingController ageController;
  final ValueChanged<bool> onUseAgeChanged;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onAgeChanged;

  const _InputCard({
    required this.useAge,
    required this.weightController,
    required this.ageController,
    required this.onUseAgeChanged,
    required this.onWeightChanged,
    required this.onAgeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'طريقة الحساب',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Toggle buttons
          Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  title: 'بالوزن',
                  icon: Icons.scale,
                  isSelected: !useAge,
                  onTap: () => onUseAgeChanged(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToggleButton(
                  title: 'بالعمر',
                  icon: Icons.cake,
                  isSelected: useAge,
                  onTap: () => onUseAgeChanged(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Input field
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: useAge
                ? _InputField(
                    key: const ValueKey('age'),
                    controller: ageController,
                    label: 'العمر (بالسنوات)',
                    hint: 'مثال: 5',
                    icon: Icons.cake_outlined,
                    onChanged: onAgeChanged,
                  )
                : _InputField(
                    key: const ValueKey('weight'),
                    controller: weightController,
                    label: 'الوزن (كجم)',
                    hint: 'مثال: 15',
                    icon: Icons.scale_outlined,
                    onChanged: onWeightChanged,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Toggle button for weight/age selection.
class _ToggleButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: widget.isSelected ? null : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : _isHovered
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight:
                      widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Input field widget.
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _InputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textSecondary,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      onChanged: onChanged,
    );
  }
}

/// Calculate button.
class _CalculateButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _CalculateButton({required this.onPressed});

  @override
  State<_CalculateButton> createState() => _CalculateButtonState();
}

class _CalculateButtonState extends State<_CalculateButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.scale(
        scale: _isPressed ? 0.98 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _isPressed
                    ? AppColors.primary.withValues(alpha: 0.9)
                    : AppColors.primary,
                _isPressed
                    ? AppColors.secondary.withValues(alpha: 0.9)
                    : AppColors.secondary,
              ],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: _isPressed ? 8 : 15,
                offset: Offset(0, _isPressed ? 2 : 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calculate, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'احسب الجرعة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card displaying the calculation result.
class _ResultCard extends StatelessWidget {
  final DoseResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.isSuccess) {
      return _ErrorResult(message: result.errorMessage ?? 'خطأ غير معروف');
    }

    return _SuccessResult(result: result);
  }
}

/// Error result display.
class _ErrorResult extends StatelessWidget {
  final String message;

  const _ErrorResult({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Success result display.
class _SuccessResult extends StatelessWidget {
  final DoseResult result;

  const _SuccessResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final weightBand = result.weightBand!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.08),
            Colors.teal.withValues(alpha: 0.03),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'النتيجة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Estimated weight notice
          if (result.estimatedWeight != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'الوزن التقديري: ${result.estimatedWeight!.toStringAsFixed(1)} كجم',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Weight band and dose
          Row(
            children: [
              Expanded(
                child: _ResultItem(
                  label: 'نطاق الوزن',
                  value: '${weightBand.minKg} - ${weightBand.maxKg} كجم',
                  icon: Icons.scale,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ResultItem(
                  label: 'الجرعة',
                  value: '${weightBand.doseMg} ملجم',
                  icon: Icons.medication,
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Formulations
          const Text(
            'التركيبات المتاحة:',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...weightBand.formulations.map(
            (f) => _FormulationItem(formulation: f),
          ),
        ],
      ),
    );
  }
}

/// Individual result item.
class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _ResultItem({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? Colors.green.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.green.shade700 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulation item widget.
class _FormulationItem extends StatelessWidget {
  final Formulation formulation;

  const _FormulationItem({required this.formulation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formulation.type,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Strength
          Expanded(
            child: Text(
              formulation.strength,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.15),
                  Colors.teal.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              formulation.amount,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
