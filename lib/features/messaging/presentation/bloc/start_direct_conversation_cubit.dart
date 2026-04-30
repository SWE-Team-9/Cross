import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_or_create_direct_conversation_usecase.dart';
import 'start_direct_conversation_state.dart';

class StartDirectConversationCubit extends Cubit<StartDirectConversationState> {
  final GetOrCreateDirectConversationUseCase
      getOrCreateDirectConversationUseCase;

  StartDirectConversationCubit({
    required this.getOrCreateDirectConversationUseCase,
  }) : super(StartDirectConversationState.initial());

  Future<void> start({
    required String receiverId,
  }) async {
    if (state.isLoading) return;

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearConversation: true,
      ),
    );

    try {
      final conversation = await getOrCreateDirectConversationUseCase(
        receiverId: receiverId,
      );

      emit(
        state.copyWith(
          isLoading: false,
          conversation: conversation,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
