import '../repositories/notifications_repository.dart';
import '../entities/notifications_result.dart';

class RegisterDeviceUseCase {
  final NotificationsRepository _repository;

  const RegisterDeviceUseCase(this._repository);

  Future<NotificationsResult<void>> call({
    required String deviceToken,
    required String platform,
  }) =>
      _repository.registerDevice(
        deviceToken: deviceToken,
        platform: platform,
      );
}

class RemoveDeviceUseCase {
  final NotificationsRepository _repository;

  const RemoveDeviceUseCase(this._repository);

  Future<NotificationsResult<void>> call(String deviceId) =>
      _repository.removeDevice(deviceId);
}
