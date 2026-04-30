import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/features/notifications/notifications_injection.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/get_notifications_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/get_unread_count_use_case.dart';
import 'package:soundcloud_clone/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:soundcloud_clone/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notification_preferences_bloc.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_model.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_preferences_model.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';

class FakeNotificationsRemoteDataSource implements NotificationsRemoteDataSource {
  @override
  Future<void> deleteNotification(String notificationId) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Stream<NotificationModel> get notificationStream => const Stream<NotificationModel>.empty();

  @override
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20, String? type, bool? isRead}) async => <NotificationModel>[];

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<NotificationPreferencesModel> getPreferences() async => NotificationPreferencesModel.fromEntity(NotificationPreferencesEntity.defaults());

  @override
  Future<void> registerDevice({required String deviceToken, required String platform}) async {}

  @override
  Future<void> removeDevice(String deviceId) async {}

  @override
  Future<void> updatePreferences(NotificationPreferencesModel preferences) async {}
}
void main() {
  test('registerNotificationsModule registers expected types', () async {
    final sl = GetIt.asNewInstance();

    // Pre-register a fake remote data source so registerNotificationsModule does not require DioClient
    sl.registerLazySingleton<NotificationsRemoteDataSource>(() => FakeNotificationsRemoteDataSource());

    registerNotificationsModule(sl);

    expect(sl.isRegistered<NotificationsRepository>(), isTrue);
    expect(sl.isRegistered<GetNotificationsUseCase>(), isTrue);
    expect(sl.isRegistered<GetUnreadCountUseCase>(), isTrue);
    expect(sl.isRegistered<NotificationsBloc>(), isTrue);
    expect(sl.isRegistered<NotificationPreferencesBloc>(), isTrue);
  });
}
