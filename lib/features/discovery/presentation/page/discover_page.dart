// lib/features/discovery/presentation/pages/discover_page.dart

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart' show AppRoutes;
import '../../../../core/di/injector.dart';
import '../../../../core/models/track.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/widgets/track_options_sheet.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../comments/presentation/bloc/comments_cubit.dart';
import '../../../comments/presentation/pages/track_comments_page.dart';
import '../../../interactions/presentation/bloc/track_interaction_cubit.dart';
import '../../../interactions/presentation/bloc/track_interaction_state.dart';
import '../../../playback/domain/usecases/get_track_detail_use_case.dart';
import '../../../playback/presentation/bloc/player_cubit.dart';
import '../../../playback/presentation/bloc/player_ui_state.dart';
import '../../../playback/presentation/widgets/add_to_playlist_sheet.dart';
import '../../../social/domain/events/social_events.dart';
import '../../../social/data/repositories/social_repo.dart';
import '../../domain/entities/trending_track.dart';
import '../bloc/trending_cubit.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrendingCubit>(
      create: (_) => getIt<TrendingCubit>()
        ..loadTrending(
          limit: 20,
          windowDays: 7,
        ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            BlocBuilder<TrendingCubit, TrendingState>(
              builder: (context, state) {
                return switch (state) {
                  TrendingInitial() || TrendingLoading() => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5500),
                      ),
                    ),
                  TrendingError(:final message) => _ErrorState(
                      message: message,
                      onRetry: () => context
                          .read<TrendingCubit>()
                          .loadTrending(limit: 20, windowDays: 7),
                    ),
                  TrendingLoaded(:final tracks) when tracks.isEmpty =>
                    const _EmptyState(),
                  TrendingLoaded(:final tracks) => _ReelsPager(tracks: tracks),
                };
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: _DiscoverHeader(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reels Pager ─────────────────────────────────────────────────────────────

class _ReelsPager extends StatefulWidget {
  final List<TrendingTrack> tracks;

  const _ReelsPager({required this.tracks});

  @override
  State<_ReelsPager> createState() => _ReelsPagerState();
}

class _ReelsPagerState extends State<_ReelsPager> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 1.0,
      initialPage: 0,
    );
    
    // Auto-play the first reel immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tryAutoPlayCurrentReel();
      }
    });
  }

  void _tryAutoPlayCurrentReel() {
    // This will be called to auto-play when reel is visible
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight =
        BottomNavBar.minHeight + MediaQuery.of(context).padding.bottom;

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        // Trigger auto-play for the new reel
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _tryAutoPlayCurrentReel();
          }
        });
      },
      itemCount: widget.tracks.length,
      itemBuilder: (context, index) {
        final track = widget.tracks[index];
        final isCurrentReel = index == _currentIndex;

        return BlocProvider(
          create: (_) => getIt<TrackInteractionCubit>()
            ..load(
              trackId: track.id,
              likesCount: track.likesCount,
              repostsCount: track.repostsCount,
            ),
          child: _ReelCard(
            track: track,
            index: index,
            allTracks: widget.tracks,
            bottomNavHeight: bottomNavHeight,
            isCurrentReel: isCurrentReel,
          ),
        );
      },
    );
  }
}
// ─── Reel Card ────────────────────────────────────────────────────────────────

class _ReelCard extends StatefulWidget {
  final TrendingTrack track;
  final int index;
  final List<TrendingTrack> allTracks;
  final double bottomNavHeight;
  final bool isCurrentReel;

  const _ReelCard({
    required this.track,
    required this.index,
    required this.allTracks,
    required this.bottomNavHeight,
    required this.isCurrentReel,
  });

  @override
  State<_ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<_ReelCard> {
  // follow state
  bool _isFollowing = false;
  bool _followLoading = false;
  String? _currentUserId;
  Set<String>? _viewerFollowingIds;
  bool _initialized = false;
  bool _autoplayAttempted = false;
  StreamSubscription<void>? _followRefreshSubscription;

  @override
  @override
  void initState() {
    super.initState();
    // Batch initialization to avoid redundant calls
    _initializeReelData();

    _followRefreshSubscription = SocialEvents.followRefreshStream.listen((_) {
      if (mounted) {
        _refreshFollowState(force: true);
      }
    });
    
    // Attempt auto-play if this is the current reel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isCurrentReel && !_autoplayAttempted) {
        _autoplayAttempted = true;
        _startPlayback();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ReelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If this reel just became visible, auto-play it
    if (!oldWidget.isCurrentReel && widget.isCurrentReel && !_autoplayAttempted) {
      _autoplayAttempted = true;
      _startPlayback();
    }
    // If this reel is no longer visible, pause it
    else if (oldWidget.isCurrentReel && !widget.isCurrentReel) {
      final playerCubit = context.read<PlayerCubit>();
      final playerState = playerCubit.state;
      if (playerState.currentTrack?.id == widget.track.id && playerState.isPlaying) {
        playerCubit.pause();
      }
    }
  }

  @override
  void dispose() {
    _followRefreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeReelData() async {
    if (_initialized) return;
    
    try {
      // Run follow check and real counts in parallel
      await Future.wait([
        _refreshFollowState(force: true),
        _fetchRealCounts(),
      ]);

      _initialized = true;
    } catch (_) {}
  }

  // يجيب الـ total likes الحقيقي من getTrackDetail
  Future<void> _fetchRealCounts() async {
    try {
      final result = await getIt<GetTrackDetailUseCase>()(widget.track.id);
      final detail = result.detail;
      if (result.failure != null || detail == null || !mounted) return;
      context.read<TrackInteractionCubit>().load(
            trackId: widget.track.id,
            likesCount: detail.likesCount,
            repostsCount: detail.repostsCount,
          );
    } catch (_) {}
  }

  Future<void> _refreshFollowState({bool force = false}) async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthAuthenticated) return;

      final viewerId = authState.user.id.trim();
      final ownerId = widget.track.ownerId.trim();
      if (viewerId.isEmpty || ownerId.isEmpty) return;

      _currentUserId = viewerId;

      if (viewerId == ownerId) {
        if (mounted && _isFollowing) {
          setState(() => _isFollowing = false);
        }
        return;
      }

      final resolved = await _viewerFollowsUser(viewerId, ownerId);
      if (!mounted) return;
      if (force || _isFollowing != resolved) {
        setState(() => _isFollowing = resolved);
      }
    } catch (_) {}
  }

  Future<bool> _viewerFollowsUser(String viewerId, String userId) async {
    final followingIds = await _loadViewerFollowingIds(viewerId);
    return followingIds.contains(userId);
  }

  Future<Set<String>> _loadViewerFollowingIds(String viewerId) async {
    if (_viewerFollowingIds != null) return _viewerFollowingIds!;
    if (!getIt.isRegistered<SocialRepo>()) return const <String>{};

    final repo = getIt<SocialRepo>();
    final resolved = <String>{};
    var page = 1;
    const limit = 100;

    try {
      while (true) {
        final users = await repo.getFollowing(viewerId, page, limit: limit);
        for (final user in users) {
          final id = user.id.trim();
          if (id.isNotEmpty) {
            resolved.add(id);
          }
        }

        if (users.length < limit) break;
        page++;
      }
    } catch (_) {}

    _viewerFollowingIds = resolved;
    return _viewerFollowingIds!;
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    final repo = getIt<SocialRepo>();
    final wasFollowing = _isFollowing;
    setState(() {
      _followLoading = true;
    });
    try {
      final result = wasFollowing
          ? await repo.unfollowUser(widget.track.ownerId)
          : await repo.followUser(widget.track.ownerId);

      if (!mounted) return;
      setState(() {
        _isFollowing = result.isFollowing;
        _viewerFollowingIds = null;
      });
      SocialEvents.emitFollowChanged();
    } catch (_) {
      if (mounted) setState(() => _isFollowing = wasFollowing);
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  Future<void> _handleScreenTap() async {
    final playerCubit = context.read<PlayerCubit>();
    final playerState = playerCubit.state;
    final isSameTrack = playerState.currentTrack?.id == widget.track.id;
    final isCurrentlyPlaying = isSameTrack && playerState.isPlaying;

    if (isCurrentlyPlaying) {
      await playerCubit.pause();
    } else if (isSameTrack) {
      await playerCubit.resume();
    } else {
      await _startPlayback();
    }
  }

  Future<void> _handleIconTap() async {
    final playerCubit = context.read<PlayerCubit>();
    final playerState = playerCubit.state;
    final isSameTrack = playerState.currentTrack?.id == widget.track.id;
    final isCurrentlyPlaying = isSameTrack && playerState.isPlaying;

    if (isCurrentlyPlaying) {
      await playerCubit.pause();
    } else if (isSameTrack) {
      await playerCubit.resume();
    } else {
      await _startPlayback();
    }

    if (mounted) {
      playerCubit.openFullPlayer();
      context.push(AppRoutes.player);
    }
  }

  Future<void> _startPlayback() async {
    final queue = widget.allTracks
        .map(
          (t) => Track(
            id: t.id,
            title: t.title,
            artist: t.ownerDisplayName,
            audioUrl: t.audioUrl,
            artworkUrl: t.coverUrl.isNotEmpty ? t.coverUrl : null,
            handle: t.ownerHandle,
            artistId: t.ownerId,
            genre: t.genre,
            likesCount: t.likesCount,
            repostsCount: t.repostsCount,
          ),
        )
        .toList();
    
    // Play immediately without waiting for full initialization
    await context.read<PlayerCubit>().playFromContext(
          tracks: queue,
          startIndex: widget.index,
          source: 'discover',
        );
  }

  void _openComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<CommentsCubit>()..load(widget.track.id),
          child: TrackCommentsPage(trackId: widget.track.id),
        ),
      ),
    );
  }

  void _openOptions() {
    TrackOptionsSheet.show(
      context,
      track: Track(
        id: widget.track.id,
        title: widget.track.title,
        artist: widget.track.ownerDisplayName,
        audioUrl: widget.track.audioUrl,
        artworkUrl:
            widget.track.coverUrl.isNotEmpty ? widget.track.coverUrl : null,
        handle: widget.track.ownerHandle,
        artistId: widget.track.ownerId,
        genre: widget.track.genre,
        likesCount: widget.track.likesCount,
        repostsCount: widget.track.repostsCount,
      ),
    );
  }

  void _goToArtistProfile(String handle) {
    final trimmedHandle = handle.trim();
    if (trimmedHandle.isEmpty) return;
    context.push('/profile/$trimmedHandle');
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final size = MediaQuery.of(context).size;
    final bottomBarBottom = widget.bottomNavHeight + 12;

    // ── نستمع للـ PlayerCubit عشان التزامن التلقائي ────────────────────────
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current is AuthAuthenticated,
      listener: (_, __) {
        _refreshFollowState(force: true);
      },
      child: BlocBuilder<PlayerCubit, PlayerUIState>(
        buildWhen: (previous, current) {
          // Only rebuild if the playing state changed for THIS track or current track changed
          final prevIsSameTrack = previous.currentTrack?.id == track.id;
          final currIsSameTrack = current.currentTrack?.id == track.id;

          return prevIsSameTrack != currIsSameTrack ||
              (currIsSameTrack && previous.isPlaying != current.isPlaying) ||
              (currIsSameTrack && previous.position != current.position);
        },
        builder: (context, playerState) {
          final isSameTrack = playerState.currentTrack?.id == track.id;
          final isPlaying = isSameTrack && playerState.isPlaying;

          return BlocBuilder<TrackInteractionCubit, TrackInteractionState>(
            builder: (context, interactionState) {
              return GestureDetector(
                onTap: _handleScreenTap,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                    // ── Background ──────────────────────────────────────
                    _buildBackground(track),

                    // ── Blur لما مش بيشتغل ──────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: isPlaying
                          ? const SizedBox.shrink()
                          : BackdropFilter(
                              key: const ValueKey('blur'),
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.25),
                              ),
                            ),
                    ),

                    // ── Gradient ────────────────────────────────────────
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.3, 0.6, 1.0],
                          colors: [
                            Color(0x66000000),
                            Colors.transparent,
                            Color(0x44000000),
                            Color(0xCC000000),
                          ],
                        ),
                      ),
                    ),

                    // ── Tap to preview ──────────────────────────────────
                    if (!isPlaying)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              child: const Icon(Icons.volume_off,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tap to preview',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(blurRadius: 4)],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── 3 نقط (top right فوق الصورة) ────────────────────
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 60,
                      right: 12,
                      child: GestureDetector(
                        onTap: _openOptions,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_vert,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),

                    // ── Right action buttons ────────────────────────────
                    Positioned(
                      right: 12,
                      bottom: bottomBarBottom + 110,
                      child: Column(
                        children: [
                          _ActionButton(
                            icon: interactionState.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            iconColor: interactionState.isLiked
                                ? const Color(0xFFFF5500)
                                : Colors.white,
                            label: _fmt(interactionState.likesCount),
                            onTap: interactionState.isSubmittingLike
                                ? () {}
                                : () => context
                                    .read<TrackInteractionCubit>()
                                    .toggleLike(track.id),
                          ),
                          const SizedBox(height: 20),
                          _ActionButton(
                            icon: Icons.chat_bubble_outline,
                            // عدد الكومنتات من الـ API مباشرة
                            label: _fmt(track.commentsCount),
                            onTap: _openComments,
                          ),
                          const SizedBox(height: 20),
                          _ActionButton(
                            icon: Icons.playlist_add,
                            label: 'Add',
                            onTap: () {
                              AddToPlaylistSheet.show(context,
                                  track: Track(
                                    id: track.id,
                                    title: track.title,
                                    artist: track.ownerDisplayName,
                                    audioUrl: track.audioUrl,
                                    artworkUrl: track.coverUrl.isNotEmpty
                                        ? track.coverUrl
                                        : null,
                                    handle: track.ownerHandle,
                                    artistId: track.ownerId,
                                    genre: track.genre,
                                    likesCount: track.likesCount,
                                    repostsCount: track.repostsCount,
                                  ));
                            },
                          ),
                        ],
                      ),
                    ),

                    // ── Bottom bar ──────────────────────────────────────
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: bottomBarBottom,
                      child: _buildBottomBar(track, playerState, isPlaying),
                    ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBackground(TrendingTrack track) {
    if (track.coverUrl.isNotEmpty) {
      return AppNetworkImage(
        imageUrl: track.coverUrl,
        fit: BoxFit.cover,
        placeholder: (_) => _fallbackBg(track),
        errorWidget: (_) => _fallbackBg(track),
      );
    }
    return _fallbackBg(track);
  }

  Widget _fallbackBg(TrendingTrack track) {
    const colors = [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
      Color(0xFF1B1B2F),
      Color(0xFF2D132C),
      Color(0xFF1B262C),
    ];
    final idx = track.id.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return Container(color: colors[idx]);
  }

  Widget _buildBottomBar(
    TrendingTrack track,
    PlayerUIState playerState,
    bool isPlaying,
  ) {
    final isSameTrack = playerState.currentTrack?.id == track.id;
    final duration = playerState.duration;
    final double progress =
        isSameTrack && duration != null && duration.inMilliseconds > 0
            ? (playerState.position.inMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

    final isOwnTrack = _currentUserId == track.ownerId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ── Avatar → يفتح البروفايل ──────────────────────────────────
          GestureDetector(
            onTap: () => _goToArtistProfile(track.ownerHandle),
            child: _buildAvatar(track),
          ),
          const SizedBox(width: 12),

          // ── Track info ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => _goToArtistProfile(track.ownerHandle),
                        child: Text(
                          track.ownerDisplayName,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFFCCCCCC)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!isOwnTrack) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _toggleFollow,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isFollowing
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.transparent,
                            border: Border.all(
                              color: _isFollowing
                                  ? Colors.white38
                                  : Colors.white54,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _followLoading
                              ? const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isFollowing ? 'Following' : 'Follow',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _isFollowing
                                        ? Colors.white70
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Play/Pause مع progress ring ──────────────────────────────
          GestureDetector(
            onTap: _handleIconTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2.5,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF5500),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(TrendingTrack track) {
    const colors = [
      Color(0xFFFF5500),
      Color(0xFF1DA0F2),
      Color(0xFF1DB954),
      Color(0xFF9B59B6),
      Color(0xFFF39C12),
      Color(0xFFE74C3C),
    ];
    final idx =
        track.ownerId.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colors[idx], colors[(idx + 1) % colors.length]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        track.ownerDisplayName.isNotEmpty
            ? track.ownerDisplayName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  String _fmt(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.iconColor = Colors.white,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon,
              color: iconColor,
              size: 28,
              shadows: const [Shadow(blurRadius: 4)]),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(blurRadius: 4)],
              )),
        ],
      ),
    );
  }
}

// ─── Discover Header ──────────────────────────────────────────────────────────

class _DiscoverHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Discover',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 6, color: Colors.black)],
              )),
          const SizedBox(width: 28),
          GestureDetector(
            onTap: () => context.go('/feed'),
            child: const Text('Following',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xAAFFFFFF),
                  shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.trending_up, size: 56, color: Color(0xFF333333)),
        SizedBox(height: 14),
        Text('No trending tracks',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        SizedBox(height: 6),
        Text('Check back later',
            style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
            ),
            child: const Text('Retry',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}
