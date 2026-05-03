import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_message_mapper.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notifications_result.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/delete_notification_use_case.dart';
import '../../domain/usecases/get_notifications_use_case.dart';
import '../../domain/usecases/get_unread_count_use_case.dart';
import '../../domain/usecases/mark_all_notifications_as_read_use_case.dart';
import '../../domain/usecases/mark_notification_as_read_use_case.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase _getNotifications;
  final GetUnreadCountUseCase _getUnreadCount;
  final MarkNotificationAsReadUseCase _markAsRead;
  final MarkAllNotificationsAsReadUseCase _markAllAsRead;
  final DeleteNotificationUseCase _delete;
  final NotificationsRepository _repository;

  StreamSubscription<NotificationEntity>? _socketSubscription;

  static const int _pageSize = 20;

  NotificationsBloc({
    required GetNotificationsUseCase getNotifications,
    required GetUnreadCountUseCase getUnreadCount,
    required MarkNotificationAsReadUseCase markAsRead,
    required MarkAllNotificationsAsReadUseCase markAllAsRead,
    required DeleteNotificationUseCase delete,
    required NotificationsRepository repository,
  })  : _getNotifications = getNotifications,
        _getUnreadCount = getUnreadCount,
        _markAsRead = markAsRead,
        _markAllAsRead = markAllAsRead,
        _delete = delete,
        _repository = repository,
        super(const NotificationsInitial()) {
    on<LoadNotifications>(_onLoad);
    on<LoadMoreNotifications>(_onLoadMore);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<DeleteNotification>(_onDelete);
    on<RealtimeNotificationReceived>(_onRealtime);
    on<RefreshUnreadCount>(_onRefreshUnreadCount);

    _socketSubscription = _repository.notificationStream.listen(
      (notification) => add(RealtimeNotificationReceived(notification)),
    );
  }

  // ── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());

    final notificationsResult =
        await _getNotifications(page: 1, limit: _pageSize);
    final countResult = await _getUnreadCount();

    switch (notificationsResult) {
      case NotificationsSuccess(value: final notifications):
        final count = switch (countResult) {
          NotificationsSuccess(value: final count) => count,
          NotificationsFailure() => 0,
        };

        emit(
          NotificationsLoaded(
            notifications: notifications,
            unreadCount: count,
            hasMore: notifications.length == _pageSize,
            currentPage: 1,
          ),
        );

      case NotificationsFailure(failure: final failure):
        emit(
          NotificationsError(
            FailureMessageMapper.toUserMessage(
              failure,
              fallback:
                  'Unable to load notifications right now. Please try again.',
            ),
          ),
        );
    }
  }

  Future<void> _onLoadMore(
    LoadMoreNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded || !current.hasMore) return;

    emit(
      NotificationsLoadingMore(
        notifications: current.notifications,
        unreadCount: current.unreadCount,
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      ),
    );

    final nextPage = current.currentPage + 1;
    final result = await _getNotifications(page: nextPage, limit: _pageSize);

    switch (result) {
      case NotificationsSuccess(value: final newItems):
        final merged = [...current.notifications, ...newItems];

        emit(
          current.copyWith(
            notifications: merged,
            hasMore: newItems.length == _pageSize,
            currentPage: nextPage,
          ),
        );

      case NotificationsFailure(failure: final failure):
        emit(
          NotificationsError(
            FailureMessageMapper.toUserMessage(
              failure,
              fallback:
                  'Unable to load notifications right now. Please try again.',
            ),
          ),
        );
    }
  }

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;

    final wasUnread = current.notifications.any(
      (notification) =>
          notification.id == event.notificationId && !notification.isRead,
    );

    final updated = current.notifications
        .map(
          (notification) => notification.id == event.notificationId
              ? notification.copyWith(isRead: true)
              : notification,
        )
        .toList();

    emit(
      current.copyWith(
        notifications: updated,
        unreadCount: wasUnread
            ? (current.unreadCount - 1).clamp(0, 999999)
            : current.unreadCount,
      ),
    );

    final result = await _markAsRead(event.notificationId);
    if (result is NotificationsFailure) {
      add(const LoadNotifications());
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;

    final updated = current.notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();

    emit(
      current.copyWith(
        notifications: updated,
        unreadCount: 0,
      ),
    );

    final result = await _markAllAsRead();
    if (result is NotificationsFailure) {
      add(const LoadNotifications());
    }
  }

  Future<void> _onDelete(
    DeleteNotification event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;

    final updated = current.notifications
        .where((notification) => notification.id != event.notificationId)
        .toList();

    emit(current.copyWith(notifications: updated));

    final result = await _delete(event.notificationId);
    if (result is NotificationsFailure) {
      add(const LoadNotifications());
    }
  }

  void _onRealtime(
    RealtimeNotificationReceived event,
    Emitter<NotificationsState> emit,
  ) {
    final current = state;
    if (current is! NotificationsLoaded) return;

    final alreadyPresent = current.notifications.any(
      (notification) => notification.id == event.notification.id,
    );

    if (alreadyPresent) return;

    emit(
      current.copyWith(
        notifications: [event.notification, ...current.notifications],
        unreadCount: current.unreadCount + 1,
      ),
    );
  }

  Future<void> _onRefreshUnreadCount(
    RefreshUnreadCount event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;

    final result = await _getUnreadCount();

    if (result is NotificationsSuccess<int>) {
      emit(current.copyWith(unreadCount: result.value));
    }
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
