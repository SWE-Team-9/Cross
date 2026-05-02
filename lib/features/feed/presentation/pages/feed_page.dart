// coverage:ignore-file
// ─────────────────────────────────────────────────────────────────────────────
//  feed_page.dart  —  Main Feed Screen
//
//  Features:
//    ✓ Discover / Following toggle
//    ✓ Infinite scroll  (NotificationListener → loadMore)
//    ✓ Pull-to-refresh  (RefreshIndicator)
//    ✓ Loading skeleton (full screen on initial load)
//    ✓ Empty state
//    ✓ Error state with retry
//    ✓ Load-more footer spinner
//    ✓ Playback via PlayerCubit + AudioPlayerService (queue-aware)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/models/track.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/feed_cubit.dart';
import '../bloc/feed_state.dart';
import '../widgets/feed_card.dart';
import '../widgets/feed_skeleton.dart';
import '../widgets/feed_toggle.dart';
import '../../data/datasources/feed_mock_data_source.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/usecases/get_feed.dart';
import '../../domain/usecases/toggle_like.dart';
import '../../domain/usecases/toggle_repost.dart';
import '../../../playback/presentation/bloc/player_cubit.dart';
import '../../../social/domain/events/social_events.dart';

// ─── DI helper (replace with your DI solution: get_it, riverpod, etc.) ───────

FeedCubit _buildCubit() {
  // ↓ Swap FeedMockDataSource → FeedRemoteDataSourceImpl when backend is ready
  final dataSource = FeedMockDataSource();
  final repo = FeedRepositoryImpl(dataSource: dataSource);
  return FeedCubit(
    getFeed: GetFeedUseCase(repo),
    toggleLike: ToggleLikeUseCase(repo),
    toggleRepost: ToggleRepostUseCase(repo),
    repository: repo,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _buildCubit()..initialize(),
      child: const _FeedView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FeedView extends StatefulWidget {
  const _FeedView();

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  StreamSubscription<void>? _followRefreshSubscription;

  @override
  void initState() {
    super.initState();
    _followRefreshSubscription = SocialEvents.followRefreshStream.listen((_) {
      if (!mounted) return;
      context.read<FeedCubit>().refresh();
    });
  }

  @override
  void dispose() {
    _followRefreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const BottomNavBar(selected: 1),
      body: SafeArea(
        child: Column(
          children: [
            // ── Toggle ───────────────────────────────────────────────────
            BlocBuilder<FeedCubit, FeedState>(
              buildWhen: (prev, curr) => prev.tab != curr.tab,
              builder: (context, state) => FeedToggle(
                selected: state.tab,
                onChanged: (tab) => context.read<FeedCubit>().setTab(tab),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<FeedCubit, FeedState>(
                builder: (context, state) {
                  if (state is FeedLoading) {
                    return const FeedSkeleton();
                  }
                  if (state is FeedEmpty) {
                    return const _EmptyState();
                  }
                  if (state is FeedError) {
                    return _ErrorState(
                      message: state.message,
                      onRetry: () => context.read<FeedCubit>().initialize(),
                    );
                  }
                  if (state is FeedLoaded) {
                    return _LoadedFeed(state: state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loaded Feed ─────────────────────────────────────────────────────────────

class _LoadedFeed extends StatelessWidget {
  final FeedLoaded state;
  const _LoadedFeed({required this.state});

  // ─── Converts FeedItem list → Track list (needs resolved streamUrl) ───────
  //
  // We build the full queue eagerly so playFromContext gets the whole list.
  // audioUrl is filled in after getStreamUrl resolves for the tapped item;
  // other items keep an empty placeholder — just_audio will skip unresolved
  // sources, and they'll be resolved when the user taps them individually.
  //
  // If you later want pre-resolved queues, call getStreamUrl for every item
  // before building the list (at the cost of N extra network calls).
  static Track _toTrack(FeedItem item, {String audioUrl = ''}) {
    return Track(
      id: item.track.trackId,
      title: item.track.title,
      artist: item.track.artist.displayName,
      audioUrl: audioUrl,
      artworkUrl: item.track.coverArtUrl,
      handle: item.track.artist.handle,
      artistId: item.track.artist.userId,
      likesCount: item.track.stats.likesCount,
      repostsCount: item.track.stats.repostsCount,
      durationMs: item.track.durationMs,
    );
  }

  Future<void> _handlePlay({
    required BuildContext context,
    required FeedLoaded currentState,
    required FeedItem tappedItem,
  }) async {
    final cubit = context.read<FeedCubit>();
    final playerCubit = context.read<PlayerCubit>();

    // 1. Resolve stream URL for tapped track + record play event
    final access = await cubit.handlePlay(tappedItem.track.trackId);

    if (!access.canPlay || access.streamUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track is blocked for playback')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (access.isPreview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preview mode: limited playback')),
      );
    }

    // 2. Build queue — tapped track gets the resolved URL, others get placeholder
    final tracks = currentState.items.map((item) {
      if (item.track.trackId == tappedItem.track.trackId) {
        return _toTrack(item, audioUrl: access.streamUrl!);
      }
      return _toTrack(item);
    }).toList();

    final startIndex = tracks.indexWhere(
      (t) => t.id == tappedItem.track.trackId,
    );

    // 3. Load queue into audio engine + update player UI state
    await playerCubit.playFromContext(
      tracks: tracks,
      startIndex: startIndex >= 0 ? startIndex : 0,
      source: 'feed',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeedCubit>();

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Trigger loadMore when 300px from bottom
        if (n is ScrollUpdateNotification) {
          final metrics = n.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 300) {
            cubit.loadMore();
          }
        }
        return false;
      },
      child: RefreshIndicator(
        color: const Color(0xFFFF5500),
        backgroundColor: const Color(0xFF1C1C1C),
        onRefresh: cubit.refresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length + 1, // +1 for footer
          itemBuilder: (context, index) {
            // Footer
            if (index == state.items.length) {
              return _Footer(state: state);
            }

            final item = state.items[index];

            return FeedCard(
              key: ValueKey(item.activityId),
              item: item,
              onLike: () => cubit.handleLike(item.track.trackId),
              onRepost: () => cubit.handleRepost(item.track.trackId),
              onPlay: () => _handlePlay(
                context: context,
                currentState: state,
                tappedItem: item,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final FeedLoaded state;
  const _Footer({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFFFF5500)),
            ),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "You're all caught up ✓",
            style: TextStyle(color: Color(0xFF555555), fontSize: 13),
          ),
        ),
      );
    }
    return const SizedBox(height: 20);
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, size: 56, color: Color(0xFF333333)),
          SizedBox(height: 12),
          Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Follow artists to see their tracks here',
            style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Error State ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Color(0xFF444444)),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1C1C1C),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
