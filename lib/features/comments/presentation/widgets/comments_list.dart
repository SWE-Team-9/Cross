import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/comment_entity.dart';
import '../bloc/comments_cubit.dart';
import 'comment_tile.dart';

class CommentsList extends StatelessWidget {
  final List<CommentEntity> comments;
  final String trackId;

  const CommentsList({
    super.key,
    required this.comments,
    required this.trackId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: comments.map((comment) {
        return Column(
          children: [
            CommentTile(
              comment: comment,
              onDelete: () =>
                  context.read<CommentsCubit>().deleteComment(comment.id),
              onReplySubmitted: (text) {
                context.read<CommentsCubit>().replyToComment(
                      trackId: trackId,
                      parentCommentId: comment.id,
                      content: text,
                    );
              },
            ),
            ...comment.replies.map(
              (reply) => CommentTile(
                comment: reply,
                onDelete: () =>
                    context.read<CommentsCubit>().deleteComment(reply.id),
              ),
            ),
          ],
        );
      }).toList(growable: false),
    );
  }
}
