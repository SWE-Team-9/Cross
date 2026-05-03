// coverage:ignore-file
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/models/track.dart';
import '../../../../core/di/injector.dart';
import '../bloc/feed_cubit.dart';
import '../bloc/feed_state.dart';
import '../widgets/feed_card.dart';
import '../widgets/feed_skeleton.dart';
import '../../domain/entities/feed_item.dart';
import '../../../playback/presentation/bloc/player_cubit.dart';
import '../../../social/domain/events/social_events.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FeedCubit>()..initialize(),
      child: const _FeedView(),
    );
  }
}

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
        child: BlocBuilder<FeedCubit, FeedState>(
          builder: (context, state) {
            if (state is FeedLoading) return const FeedSkeleton();
            if (state is FeedEmpty) return const _EmptyState();
            if (state is FeedError) {
              return _ErrorState(
                message: state.message,
                onRetry: () => context.read<FeedCubit>().initialize(),
              );
            }
            if (state is FeedLoaded) return _LoadedFeed(state: state);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _LoadedFeed extends StatelessWidget {
  final FeedLoaded state;
  const _LoadedFeed({required this.state});

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

    final access = await cubit.handlePlay(
      tappedItem.track.trackId,
      feedAudioUrl: tappedItem.track.audioUrl,
    );

    if (!access.canPlay || access.streamUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track is not available for playback')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (access.isPreview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preview mode — limited playback')),
      );
    }

    final tracks = currentState.items.map((item) {
      final isTapped = item.track.trackId == tappedItem.track.trackId;
      return _toTrack(item, audioUrl: isTapped ? access.streamUrl! : '');
    }).toList();

    final startIndex =
        tracks.indexWhere((t) => t.id == tappedItem.track.trackId);

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
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: cubit.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Pinned Toggle ────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                height: 64,
                child: const _PinnedToggle(),
              ),
            ),

            // ── Feed cards ───────────────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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
                childCount: state.items.length + 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pinned Header Delegate ───────────────────────────────────────────────────

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  const _PinnedHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_PinnedHeaderDelegate old) =>
      old.height != height || old.child != child;
}

// ─── Pinned Toggle ────────────────────────────────────────────────────────────

class _PinnedToggle extends StatelessWidget {
  const _PinnedToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Discover — ينقل لـ /discover
            _TabPill(
              label: 'Discover',
              active: false,
              onTap: () => context.go('/discover'),
            ),
            // Following — active
            _TabPill(
              label: 'Following',
              active: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabPill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? Colors.black : const Color(0xFF888888),
          ),
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
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
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
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text("You're all caught up ✓",
              style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
        ),
      );
    }
    return const SizedBox(height: 20);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note_outlined, size: 56, color: Color(0xFF333333)),
          SizedBox(height: 14),
          Text('No activity yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          SizedBox(height: 6),
          Text('Follow artists to see their tracks here',
              style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

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
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: Color(0xFF444444)),
            const SizedBox(height: 14),
            Text(message,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 18),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1C1C1C),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
