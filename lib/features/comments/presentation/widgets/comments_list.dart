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

  const CommentsList({
    super.key,
    required this.comments,
    required this.trackId,
    this.onSeekToTimestamp,
  });

  Future<void> _confirmAndDelete(
    BuildContext context,
    String commentId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          title: const Text(
            'Delete comment?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      await context.read<CommentsCubit>().deleteComment(commentId);
    }
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
        final canDelete = currentUserId != null && comment.userId == currentUserId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommentTile(
              comment: comment,
              onDelete: canDelete
                  ? () => _confirmAndDelete(context, comment.id)
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
                onDelete: canDeleteReply
                    ? () => _confirmAndDelete(context, reply.id)
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