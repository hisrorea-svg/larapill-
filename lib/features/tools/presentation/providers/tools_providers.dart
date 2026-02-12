import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/medicine_local_datasource.dart';
import '../../data/repositories/medicine_repository_impl.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../../domain/usecases/calculate_dose_usecase.dart';

/// Provider for the local data source.
final medicineLocalDataSourceProvider =
    Provider<MedicineLocalDataSource>((ref) {
  return MedicineLocalDataSource();
});

/// Provider for the medicine repository.
final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  final localDataSource = ref.watch(medicineLocalDataSourceProvider);
  return MedicineRepositoryImpl(localDataSource);
});

/// Provider for the calculate dose use case.
final calculateDoseUseCaseProvider = Provider<CalculateDoseUseCase>((ref) {
  final repository = ref.watch(medicineRepositoryProvider);
  return CalculateDoseUseCase(repository);
});

/// Provider that loads all medicines asynchronously.
final medicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  final repository = ref.watch(medicineRepositoryProvider);
  return repository.getAllMedicines();
});

/// Provider for filtered medicines based on search query.
final filteredMedicinesProvider =
    FutureProvider.family<List<Medicine>, String>((ref, query) async {
  final repository = ref.watch(medicineRepositoryProvider);
  return repository.searchMedicines(query);
});

/// State for the dosing calculator.
class DosingCalculatorState {
  final Medicine? selectedMedicine;
  final bool useAge;
  final String weightText;
  final String ageText;
  final DoseResult? result;

  const DosingCalculatorState({
    this.selectedMedicine,
    this.useAge = false,
    this.weightText = '',
    this.ageText = '',
    this.result,
  });

  DosingCalculatorState copyWith({
    Medicine? selectedMedicine,
    bool? useAge,
    String? weightText,
    String? ageText,
    DoseResult? result,
    bool clearResult = false,
  }) {
    return DosingCalculatorState(
      selectedMedicine: selectedMedicine ?? this.selectedMedicine,
      useAge: useAge ?? this.useAge,
      weightText: weightText ?? this.weightText,
      ageText: ageText ?? this.ageText,
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

/// StateNotifier for managing dosing calculator state.
class DosingCalculatorNotifier extends StateNotifier<DosingCalculatorState> {
  final CalculateDoseUseCase _calculateDoseUseCase;

  DosingCalculatorNotifier(this._calculateDoseUseCase)
      : super(const DosingCalculatorState());

  /// Selects a medicine for dose calculation.
  void selectMedicine(Medicine medicine) {
    state = state.copyWith(selectedMedicine: medicine, clearResult: true);
  }

  /// Toggles between weight-based and age-based calculation.
  void setUseAge(bool useAge) {
    state = state.copyWith(useAge: useAge, clearResult: true);
  }

  /// Updates the weight input text.
  void setWeight(String weight) {
    state = state.copyWith(weightText: weight, clearResult: true);
  }

  /// Updates the age input text.
  void setAge(String age) {
    state = state.copyWith(ageText: age, clearResult: true);
  }

  /// Calculates the dose based on current state.
  void calculateDose() {
    if (state.selectedMedicine == null) return;

    final double? weight =
        state.useAge ? null : double.tryParse(state.weightText);
    final double? age = state.useAge ? double.tryParse(state.ageText) : null;

    final result = _calculateDoseUseCase.calculate(
      medicine: state.selectedMedicine!,
      weightKg: weight,
      ageYears: age,
    );

    state = state.copyWith(result: result);
  }

  /// Clears all inputs and results.
  void reset() {
    state = const DosingCalculatorState();
  }
}

/// Provider for the dosing calculator state notifier.
final dosingCalculatorProvider =
    StateNotifierProvider<DosingCalculatorNotifier, DosingCalculatorState>(
        (ref) {
  final useCase = ref.watch(calculateDoseUseCaseProvider);
  return DosingCalculatorNotifier(useCase);
});
