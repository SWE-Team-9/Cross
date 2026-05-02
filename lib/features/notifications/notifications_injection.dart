import 'package:get_it/get_it.dart';

import 'data/datasources/notifications_remote_data_source.dart';
import 'data/models/notification_model.dart';
import 'data/repositories/notifications_repository_impl.dart';
import 'data/services/fcm_registration_service.dart';
import 'domain/repositories/notifications_repository.dart';
import 'domain/usecases/delete_notification_use_case.dart';
import 'domain/usecases/device_use_cases.dart';
import 'domain/usecases/get_notifications_use_case.dart';
import 'domain/usecases/get_unread_count_use_case.dart';
import 'domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'domain/usecases/mark_notification_as_read_use_case.dart';
import 'domain/usecases/notification_preferences_use_cases.dart';
import '../messaging/domain/usecases/get_conversation_meta_usecase.dart';
import '../messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';
import 'presentation/bloc/notification_preferences_bloc.dart';
import 'presentation/bloc/notifications_bloc.dart';

/// Call [registerNotificationsModule] from your root injection container
/// (e.g. injection_container.dart) after the core services are registered.
void registerNotificationsModule(GetIt sl) {
  if (sl.isRegistered<NotificationsRepository>() &&
      sl.isRegistered<NotificationsBloc>() &&
      sl.isRegistered<NotificationPreferencesBloc>()) {
    return;
  }

  final Stream<NotificationModel> realtimeStream = sl
          .isRegistered<Stream<NotificationModel>>(
              instanceName: 'notificationSocketStream')
      ? sl<Stream<NotificationModel>>(instanceName: 'notificationSocketStream')
      : const Stream<NotificationModel>.empty();

  // ── Data Sources ───────────────────────────────────────────────────────────
  if (!sl.isRegistered<NotificationsRemoteDataSource>()) {
    sl.registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(
        client: sl(),
        notificationStream: realtimeStream,
      ),
    );
  }

  // ── Repository ─────────────────────────────────────────────────────────────
  if (!sl.isRegistered<NotificationsRepository>()) {
    sl.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(sl()),
    );
  }

  // ── Use Cases ──────────────────────────────────────────────────────────────
  if (!sl.isRegistered<GetNotificationsUseCase>()) {
    sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  }
  if (!sl.isRegistered<GetUnreadCountUseCase>()) {
    sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
  }
  if (!sl.isRegistered<MarkNotificationAsReadUseCase>()) {
    sl.registerLazySingleton(() => MarkNotificationAsReadUseCase(sl()));
  }
  if (!sl.isRegistered<MarkAllNotificationsAsReadUseCase>()) {
    sl.registerLazySingleton(() => MarkAllNotificationsAsReadUseCase(sl()));
  }
  if (!sl.isRegistered<DeleteNotificationUseCase>()) {
    sl.registerLazySingleton(() => DeleteNotificationUseCase(sl()));
  }
  if (!sl.isRegistered<GetNotificationPreferencesUseCase>()) {
    sl.registerLazySingleton(() => GetNotificationPreferencesUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateNotificationPreferencesUseCase>()) {
    sl.registerLazySingleton(() => UpdateNotificationPreferencesUseCase(sl()));
  }
  if (!sl.isRegistered<RegisterDeviceUseCase>()) {
    sl.registerLazySingleton(() => RegisterDeviceUseCase(sl()));
  }
  if (!sl.isRegistered<RemoveDeviceUseCase>()) {
    sl.registerLazySingleton(() => RemoveDeviceUseCase(sl()));
  }
  if (!sl.isRegistered<GetConversationMetaUseCase>()) {
    sl.registerLazySingleton(() => GetConversationMetaUseCase(sl()));
  }
  if (!sl.isRegistered<GetOrCreateDirectConversationUseCase>()) {
    sl.registerLazySingleton(
      () => GetOrCreateDirectConversationUseCase(sl()),
    );
  }

  if (!sl.isRegistered<FcmRegistrationService>()) {
    sl.registerLazySingleton<FcmRegistrationService>(
      () => FcmRegistrationService(
        sl<RegisterDeviceUseCase>(),
        sl<GetConversationMetaUseCase>(),
        sl<GetOrCreateDirectConversationUseCase>(),
      ),
    );
  }

  // ── BLoCs ──────────────────────────────────────────────────────────────────
  if (!sl.isRegistered<NotificationsBloc>()) {
    sl.registerLazySingleton(
      () => NotificationsBloc(
        getNotifications: sl(),
        getUnreadCount: sl(),
        markAsRead: sl(),
        markAllAsRead: sl(),
        delete: sl(),
        repository: sl(),
      ),
    );
  }

  if (!sl.isRegistered<NotificationPreferencesBloc>()) {
    sl.registerLazySingleton(
      () => NotificationPreferencesBloc(
        getPreferences: sl(),
        updatePreferences: sl(),
      ),
    );
  }
}
