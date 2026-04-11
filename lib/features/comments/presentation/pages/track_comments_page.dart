import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/comments_cubit.dart';
import '../bloc/comments_state.dart';
import '../widgets/comment_input_field.dart';
import '../widgets/comments_list.dart';

class TrackCommentsPage extends StatefulWidget {
  final String trackId;

  const TrackCommentsPage({
    super.key,
    required this.trackId,
  });

  @override
  State<TrackCommentsPage> createState() => _TrackCommentsPageState();
}

class _TrackCommentsPageState extends State<TrackCommentsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CommentsCubit>().load(widget.trackId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<CommentsCubit, CommentsState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.comments.isEmpty) {
                  return const Center(child: Text('No comments yet'));
                }

                return CommentsList(
                  comments: state.comments,
                  trackId: widget.trackId,
                );
              },
            ),
          ),
          CommentInputField(
            onSubmit: (text) {
              context.read<CommentsCubit>().addComment(
                    trackId: widget.trackId,
                    content: text,
                  );
            },
          ),
        ],
      ),
    );
  }
}