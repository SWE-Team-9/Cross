import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/track_interaction_cubit.dart';
import '../bloc/track_interaction_state.dart';

class TrackInteractionBar extends StatelessWidget {
  final String trackId;
  final VoidCallback? onOpenComments;

  const TrackInteractionBar({
    super.key,
    required this.trackId,
    this.onOpenComments,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrackInteractionCubit, TrackInteractionState>(
      builder: (context, state) {
        return Row(
          children: [
            IconButton(
              onPressed: state.isSubmittingLike
                  ? null
                  : () => context.read<TrackInteractionCubit>().toggleLike(trackId),
              icon: Icon(
                state.isLiked ? Icons.favorite : Icons.favorite_border,
              ),
            ),
            Text('${state.likesCount}'),
            const SizedBox(width: 12),
            IconButton(
              onPressed: state.isSubmittingRepost
                  ? null
                  : () => context.read<TrackInteractionCubit>().toggleRepost(trackId),
              icon: Icon(
                state.isReposted ? Icons.repeat_one : Icons.repeat,
              ),
            ),
            Text('${state.repostsCount}'),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onOpenComments,
              icon: const Icon(Icons.mode_comment_outlined),
            ),
          ],
        );
      },
    );
  }
}