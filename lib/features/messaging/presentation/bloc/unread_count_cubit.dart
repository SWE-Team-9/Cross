import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/realtime_message_event_entity.dart';
import '../../domain/usecases/connect_messaging_socket_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import 'unread_count_state.dart';

class UnreadCountCubit extends Cubit<UnreadCountState> {
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final ConnectMessagingSocketUseCase connectMessagingSocketUseCase;

  StreamSubscription<RealtimeMessageEventEntity>? _socketSub;

  UnreadCountCubit({
    required this.getUnreadCountUseCase,
    required this.connectMessagingSocketUseCase,
  }) : super(UnreadCountState.initial());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final result = await getUnreadCountUseCase();

      emit(
        state.copyWith(
          isLoading: false,
          count: result.count,
          clearError: true,
        ),
      );

      await _connectSocket();
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final result = await getUnreadCountUseCase();

      emit(
        state.copyWith(
          count: result.count,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void setCount(int count) {
    emit(
      state.copyWith(
        count: count < 0 ? 0 : count,
        clearError: true,
      ),
    );
  }

  Future<void> _connectSocket() async {
    try {
      await connectMessagingSocketUseCase();

      await _socketSub?.cancel();
      _socketSub = connectMessagingSocketUseCase.eventsStream.listen(
        (event) {
          final count = event.currentUnreadCount;
          if (count != null) {
            setCount(count);
            return;
          }

          switch (event.type) {
            case RealtimeMessageEventType.newMessage:
            case RealtimeMessageEventType.messageDeleted:
            case RealtimeMessageEventType.conversationRead:
            case RealtimeMessageEventType.conversationUpdated:
            case RealtimeMessageEventType.unreadCountUpdated:
              refresh();
              break;

            case RealtimeMessageEventType.userBlocked:
            case RealtimeMessageEventType.userUnblocked:
            case RealtimeMessageEventType.unknown:
              break;
          }
        },
        onError: (_) {},
      );
    } catch (_) {
      // Do not block the UI if socket fails.
    }
  }

  @override
  Future<void> close() async {
    await _socketSub?.cancel();
    return super.close();
  }
}
