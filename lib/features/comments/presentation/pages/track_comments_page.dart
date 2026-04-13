import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/services/audio_player_service.dart';
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
  int _currentPositionSeconds = 0;
  StreamSubscription? _playerSub;

  @override
  void initState() {
    super.initState();

    context.read<CommentsCubit>().load(widget.trackId);

    final player = GetIt.I<AudioPlayerService>();

    final initial = widget.getCurrentPositionSeconds?.call() ?? 0;
    _currentPositionSeconds = initial;

    _playerSub = player.playerStateStream.listen((state) {
      final seconds = state.position.inSeconds;

      if (seconds != _currentPositionSeconds) {
        setState(() {
          _currentPositionSeconds = seconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    super.dispose();
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
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
            // 🔥 LIVE TIMESTAMP DISPLAY
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
                    'Commenting at ${_formatTime(_currentPositionSeconds)}',
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
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (state.comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No comments yet',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return CommentsList(
                    comments: state.comments,
                    trackId: widget.trackId,
                    onSeekToTimestamp: widget.onSeekToTimestamp,
                    currentPositionSeconds: _currentPositionSeconds, // 🔥 LIVE
                  );
                },
              ),
            ),

            BlocBuilder<CommentsCubit, CommentsState>(
              builder: (context, state) {
                return CommentInputField(
                  isSubmitting: state.isSubmitting,
                  currentTimestampLabel: _formatTime(_currentPositionSeconds),
                  onSubmit: (text) {
                    context.read<CommentsCubit>().addComment(
                          trackId: widget.trackId,
                          content: text,
                          timestampSeconds: _currentPositionSeconds,
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
