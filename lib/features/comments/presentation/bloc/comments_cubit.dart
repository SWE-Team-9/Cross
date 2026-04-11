import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/comment_entity.dart';
import '../../domain/usecases/create_comment_usecase.dart';
import '../../domain/usecases/delete_comment_usecase.dart';
import '../../domain/usecases/get_track_comments_usecase.dart';
import '../../domain/usecases/reply_to_comment_usecase.dart';
import 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  final GetTrackCommentsUseCase getTrackCommentsUseCase;
  final CreateCommentUseCase createCommentUseCase;
  final DeleteCommentUseCase deleteCommentUseCase;
  final ReplyToCommentUseCase replyToCommentUseCase;

  CommentsCubit({
    required this.getTrackCommentsUseCase,
    required this.createCommentUseCase,
    required this.deleteCommentUseCase,
    required this.replyToCommentUseCase,
  }) : super(CommentsState.initial());

  Future<void> load(String trackId) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final comments = await getTrackCommentsUseCase(trackId);
      emit(
        state.copyWith(
          isLoading: false,
          comments: comments,
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

  Future<void> addComment({
    required String trackId,
    required String content,
    int? timestampSeconds,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final created = await createCommentUseCase(
        trackId: trackId,
        content: content,
        timestampSeconds: timestampSeconds,
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          comments: [created, ...state.comments],
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> replyToComment({
    required String trackId,
    required String parentCommentId,
    required String content,
    int? timestampSeconds,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final reply = await replyToCommentUseCase(
        trackId: trackId,
        parentCommentId: parentCommentId,
        content: content,
        timestampSeconds: timestampSeconds,
      );

      final updated = _attachReply(
        comments: state.comments,
        parentCommentId: parentCommentId,
        reply: reply,
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          comments: updated,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await deleteCommentUseCase(commentId);

      final updated = _removeComment(
        comments: state.comments,
        commentId: commentId,
      );

      emit(
        state.copyWith(
          comments: updated,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  List<CommentEntity> _attachReply({
    required List<CommentEntity> comments,
    required String parentCommentId,
    required CommentEntity reply,
  }) {
    return comments.map((comment) {
      if (comment.id == parentCommentId) {
        return CommentEntity(
          id: comment.id,
          content: comment.content,
          userId: comment.userId,
          userDisplayName: comment.userDisplayName,
          userAvatarUrl: comment.userAvatarUrl,
          parentCommentId: comment.parentCommentId,
          timestampSeconds: comment.timestampSeconds,
          createdAt: comment.createdAt,
          replies: [...comment.replies, reply],
        );
      }
      return comment;
    }).toList(growable: false);
  }

  List<CommentEntity> _removeComment({
    required List<CommentEntity> comments,
    required String commentId,
  }) {
    return comments
        .where((comment) => comment.id != commentId)
        .map((comment) {
          return CommentEntity(
            id: comment.id,
            content: comment.content,
            userId: comment.userId,
            userDisplayName: comment.userDisplayName,
            userAvatarUrl: comment.userAvatarUrl,
            parentCommentId: comment.parentCommentId,
            timestampSeconds: comment.timestampSeconds,
            createdAt: comment.createdAt,
            replies: comment.replies
                .where((reply) => reply.id != commentId)
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }
}