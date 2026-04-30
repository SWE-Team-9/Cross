import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/start_direct_conversation_cubit.dart';
import '../bloc/start_direct_conversation_state.dart';
import '../routes/messaging_routes.dart';

class MessageUserButton extends StatelessWidget {
  final String receiverId;
  final bool enabled;

  const MessageUserButton({
    super.key,
    required this.receiverId,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<StartDirectConversationCubit>(),
      child: BlocConsumer<StartDirectConversationCubit,
          StartDirectConversationState>(
        listener: (context, state) {
          final conversation = state.conversation;

          if (conversation != null) {
            MessagingRoutes.goToConversation(
              context,
              conversation,
            );
          }

          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF2B2B2B),
                content: Text(state.errorMessage!),
              ),
            );
          }
        },
        builder: (context, state) {
          return GestureDetector(
            onTap: !enabled || state.isLoading
                ? null
                : () {
                    context.read<StartDirectConversationCubit>().start(
                          receiverId: receiverId,
                        );
                  },
            child: Opacity(
              opacity: enabled ? 1 : 0.45,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF555555)),
                ),
                alignment: Alignment.center,
                child: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF5500),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            color: Colors.white,
                            size: 17,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Message',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
