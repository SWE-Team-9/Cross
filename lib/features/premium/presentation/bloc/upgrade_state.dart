import 'package:equatable/equatable.dart';

enum UpgradeStatus {
  initial,
  loading,
  success,
  error,
}

class UpgradeState extends Equatable {
  final String selectedPlan;
  final UpgradeStatus status;
  final String? errorMessage;

  const UpgradeState({
    this.selectedPlan = 'PRO',
    this.status = UpgradeStatus.initial,
    this.errorMessage,
  });

  UpgradeState copyWith({
    String? selectedPlan,
    UpgradeStatus? status,
    String? errorMessage,
  }) {
    return UpgradeState(
      selectedPlan: selectedPlan ?? this.selectedPlan,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [selectedPlan, status, errorMessage];
}
