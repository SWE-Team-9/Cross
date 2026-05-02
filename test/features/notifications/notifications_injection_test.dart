import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversation_meta_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';
import 'package:soundcloud_clone/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_model.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_preferences_model.dart';
import 'package:soundcloud_clone/features/notifications/data/services/fcm_registration_service.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/delete_notification_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/device_use_cases.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/get_notifications_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/get_unread_count_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/notification_preferences_use_cases.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/resolve_notification_tap_target_use_case.dart';
import 'package:soundcloud_clone/features/notifications/notifications_injection.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notification_preferences_bloc.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';

class FakeNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  @override
  Future<void> deleteNotification(String notificationId) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Stream<NotificationModel> get notificationStream =>
      const Stream<NotificationModel>.empty();

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) async =>
      <NotificationModel>[];

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<NotificationPreferencesModel> getPreferences() async =>
      NotificationPreferencesModel.fromEntity(
        NotificationPreferencesEntity.defaults(),
      );

  @override
  Future<void> registerDevice({
    required String deviceToken,
    required String platform,
  }) async {}

  @override
  Future<void> removeDevice(String deviceId) async {}

  @override
  Future<void> updatePreferences(
      NotificationPreferencesModel preferences) async {}
}

void main() {
  test('registerNotificationsModule registers expected types', () async {
    final sl = GetIt.asNewInstance();
    sl.registerLazySingleton<NotificationsRemoteDataSource>(
      () => FakeNotificationsRemoteDataSource(),
    );

    registerNotificationsModule(sl);

    expect(sl.isRegistered<NotificationsRepository>(), isTrue);
    expect(sl.isRegistered<GetNotificationsUseCase>(), isTrue);
    expect(sl.isRegistered<GetUnreadCountUseCase>(), isTrue);
    expect(sl.isRegistered<MarkNotificationAsReadUseCase>(), isTrue);
    expect(sl.isRegistered<MarkAllNotificationsAsReadUseCase>(), isTrue);
    expect(sl.isRegistered<DeleteNotificationUseCase>(), isTrue);
    expect(sl.isRegistered<GetNotificationPreferencesUseCase>(), isTrue);
    expect(sl.isRegistered<UpdateNotificationPreferencesUseCase>(), isTrue);
    expect(sl.isRegistered<RegisterDeviceUseCase>(), isTrue);
    expect(sl.isRegistered<RemoveDeviceUseCase>(), isTrue);
    expect(sl.isRegistered<ResolveNotificationTapTargetUseCase>(), isTrue);
    expect(sl.isRegistered<GetConversationMetaUseCase>(), isTrue);
    expect(sl.isRegistered<GetOrCreateDirectConversationUseCase>(), isTrue);
    expect(sl.isRegistered<FcmRegistrationService>(), isTrue);
    expect(sl.isRegistered<NotificationsBloc>(), isTrue);
    expect(sl.isRegistered<NotificationPreferencesBloc>(), isTrue);
  });
}
