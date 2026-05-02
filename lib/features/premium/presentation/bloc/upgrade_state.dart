import 'package:equatable/equatable.dart';

enum UpgradeStatus { initial, loading, success, error }

class UpgradeState extends Equatable {
  final String selectedPlan;
  final UpgradeStatus status;
  final String? checkoutUrl;
  final String? errorMessage;

  const UpgradeState({
    this.selectedPlan = 'PRO',
    this.status = UpgradeStatus.initial,
    this.checkoutUrl,
    this.errorMessage,
  });

  UpgradeState copyWith({
    String? selectedPlan,
    UpgradeStatus? status,
    String? checkoutUrl,
    String? errorMessage,
  }) {
    return UpgradeState(
      selectedPlan: selectedPlan ?? this.selectedPlan,
      status: status ?? this.status,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [selectedPlan, status, checkoutUrl, errorMessage];
}
