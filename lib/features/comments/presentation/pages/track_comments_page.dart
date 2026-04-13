import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/comments_cubit.dart';
import '../bloc/comments_state.dart';
import '../widgets/comment_input_field.dart';
import '../widgets/comments_list.dart';

class TrackCommentsPage extends StatefulWidget {
  final String trackId;
  final int Function()? getCurrentPositionSeconds;
  final ValueChanged<int>? onSeekToTimestamp;

  const TrackCommentsPage({
    super.key,
    required this.trackId,
    this.getCurrentPositionSeconds,
    this.onSeekToTimestamp,
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

  Future<bool> _handleBack() async {
    final count = context.read<CommentsCubit>().state.comments.length;
    Navigator.pop(context, count);
    return false;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentTimestamp = widget.getCurrentPositionSeconds?.call() ?? 0;

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              final count = context.read<CommentsCubit>().state.comments.length;
              Navigator.pop(context, count);
            },
          ),
          titleSpacing: 0,
          title: const Text(
            'Comments',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFFFF5500),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Commenting at ${_formatTime(currentTimestamp)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<CommentsCubit, CommentsState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5500),
                      ),
                    );
                  }

                  if (state.errorMessage != null && state.comments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 34,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Failed to load comments',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => context
                                  .read<CommentsCubit>()
                                  .load(widget.trackId),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state.comments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mode_comment_outlined,
                                color: Colors.white38,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No comments yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Drop the first timestamped comment for this track.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return CommentsList(
                    comments: state.comments,
                    trackId: widget.trackId,
                    onSeekToTimestamp: widget.onSeekToTimestamp,
                  );
                },
              ),
            ),
            BlocBuilder<CommentsCubit, CommentsState>(
              builder: (context, state) {
                return CommentInputField(
                  isSubmitting: state.isSubmitting,
                  currentTimestampLabel: _formatTime(currentTimestamp),
                  onSubmit: (text) {
                    context.read<CommentsCubit>().addComment(
                          trackId: widget.trackId,
                          content: text,
                          timestampSeconds: currentTimestamp,
                        );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}