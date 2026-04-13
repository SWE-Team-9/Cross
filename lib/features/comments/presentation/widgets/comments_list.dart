import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/comment_entity.dart';
import '../bloc/comments_cubit.dart';
import 'comment_tile.dart';

class CommentsList extends StatelessWidget {
  final List<CommentEntity> comments;
  final String trackId;
  final ValueChanged<int>? onSeekToTimestamp;
  final int currentPositionSeconds; // 🔥 NEW

  const CommentsList({
    super.key,
    required this.comments,
    required this.trackId,
    this.onSeekToTimestamp,
    required this.currentPositionSeconds, // 🔥 NEW
  });

  bool _isActive(int? timestamp) {
    if (timestamp == null) return false;

    // 🔥 tolerance of 2 seconds
    return (currentPositionSeconds - timestamp).abs() <= 2;
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserId;
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final canDelete =
            currentUserId != null && comment.userId == currentUserId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommentTile(
              comment: comment,
              isActive: _isActive(comment.timestampSeconds), // 🔥
              onDelete: canDelete
                  ? () =>
                      context.read<CommentsCubit>().deleteComment(comment.id)
                  : null,
              onReplySubmitted: null,
              onTapTimestamp: comment.timestampSeconds != null
                  ? () => onSeekToTimestamp?.call(comment.timestampSeconds!)
                  : null,
            ),
            ...comment.replies.map((reply) {
              final canDeleteReply =
                  currentUserId != null && reply.userId == currentUserId;

              return CommentTile(
                comment: reply,
                isActive: _isActive(reply.timestampSeconds), // 🔥
                onDelete: canDeleteReply
                    ? () =>
                        context.read<CommentsCubit>().deleteComment(reply.id)
                    : null,
                onReplySubmitted: null,
                onTapTimestamp: reply.timestampSeconds != null
                    ? () => onSeekToTimestamp?.call(reply.timestampSeconds!)
                    : null,
              );
            }),
          ],
        );
      },
    );
  }
}
