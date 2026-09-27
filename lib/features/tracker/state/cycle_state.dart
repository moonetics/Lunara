import '../../../core/database/models/cycle_model.dart';
import '../../../core/services/cycle_engine.dart';

/// State Immutable Siklus Menstruasi Lunara
class CycleState {
  final List<CycleModel> allCycles;
  final CycleModel? activeCycle;
  final double averageCycleLength;
  final CyclePhaseInfo? currentPhaseInfo;
  final DateTime? nextPeriodDate;
  final int delayDays;
  final bool isDelayed;
  final bool isLoading;
  final String? errorMessage;

  const CycleState({
    this.allCycles = const [],
    this.activeCycle,
    this.averageCycleLength = 28.0,
    this.currentPhaseInfo,
    this.nextPeriodDate,
    this.delayDays = 0,
    this.isDelayed = false,
    this.isLoading = false,
    this.errorMessage,
  });

  CycleState copyWith({
    List<CycleModel>? allCycles,
    CycleModel? activeCycle,
    double? averageCycleLength,
    CyclePhaseInfo? currentPhaseInfo,
    DateTime? nextPeriodDate,
    int? delayDays,
    bool? isDelayed,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CycleState(
      allCycles: allCycles ?? this.allCycles,
      activeCycle: activeCycle ?? this.activeCycle,
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      currentPhaseInfo: currentPhaseInfo ?? this.currentPhaseInfo,
      nextPeriodDate: nextPeriodDate ?? this.nextPeriodDate,
      delayDays: delayDays ?? this.delayDays,
      isDelayed: isDelayed ?? this.isDelayed,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
