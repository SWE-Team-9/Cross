import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommentTile(
              comment: comment,
              onDelete: () {
                context.read<CommentsCubit>().deleteComment(comment.id);
              },
              onReplySubmitted: null,
              onTapTimestamp: comment.timestampSeconds != null
                  ? () => onSeekToTimestamp?.call(comment.timestampSeconds!)
                  : null,
            ),
            ...comment.replies.map(
              (reply) => CommentTile(
                comment: reply,
                onDelete: () {
                  context.read<CommentsCubit>().deleteComment(reply.id);
                },
                onReplySubmitted: null,
                onTapTimestamp: reply.timestampSeconds != null
                    ? () => onSeekToTimestamp?.call(reply.timestampSeconds!)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}