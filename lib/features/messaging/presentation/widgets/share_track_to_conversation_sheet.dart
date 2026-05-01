import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/conversation_entity.dart';
import '../bloc/share_track_to_conversation_cubit.dart';
import 'conversation_picker_sheet.dart';

Future<void> showShareTrackToConversationSheet({
  required BuildContext context,
  required String trackId,
  String? text,
}) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return BlocProvider(
        create: (_) => GetIt.I<ShareTrackToConversationCubit>(),
        child: Builder(
          builder: (innerContext) {
            return ConversationPickerSheet(
              title: 'Send track to',
              actionLabel: 'Send',
              onConversationSelected: (ConversationEntity conversation) {
                return innerContext
                    .read<ShareTrackToConversationCubit>()
                    .shareTrack(
                      conversation: conversation,
                      trackId: trackId,
                      text: text,
                    );
              },
            );
          },
        ),
      );
    },
  );
}

Future<void> showSharePlaylistToConversationSheet({
  required BuildContext context,
  required String playlistId,
  String? text,
}) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return BlocProvider(
        create: (_) => GetIt.I<ShareTrackToConversationCubit>(),
        child: Builder(
          builder: (innerContext) {
            return ConversationPickerSheet(
              title: 'Send playlist to',
              actionLabel: 'Send',
              onConversationSelected: (ConversationEntity conversation) {
                return innerContext
                    .read<ShareTrackToConversationCubit>()
                    .sharePlaylist(
                      conversation: conversation,
                      playlistId: playlistId,
                      text: text,
                    );
              },
            );
          },
        ),
      );
    },
  );
}
