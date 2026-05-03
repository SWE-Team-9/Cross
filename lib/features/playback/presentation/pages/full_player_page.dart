// coverage:ignore-file
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_options_sheet.dart';
import 'package:soundcloud_clone/features/comments/domain/entities/comment_entity.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/create_comment_usecase.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/get_track_comments_usecase.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/pages/track_comments_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/engagement_list_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/engagement_list_state.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';
import 'package:soundcloud_clone/features/interactions/presentation/pages/engagement_list_page.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/share_track_to_conversation_sheet.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/events/social_events.dart';

import '../widgets/repeat_mode_button.dart';
import '/core/widgets/scrolling_waveform.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key});

  static const String playerHeroTag = 'player_shell_hero';

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage>
    with TickerProviderStateMixin {
  late PlayerCubit _playerCubit;
  String? _loadedTrackId;

  // ── Track identity — used to detect auto-advance ──────────────────────────
  String? _lastKnownTrackId;

  int _commentsCount = 0;
  List<CommentEntity> _timelineComments = const [];

  final Set<String> _followedArtistIds = {};
  Set<String>? _viewerFollowingIds;
  String? _loadedArtistFollowTrackId;

  bool _isAddingEmojiComment = false;
  bool _isFollowingArtist = false;

  // ── Emoji burst ───────────────────────────────────────────────────────────
  int _emojiBurstId = 0;
  String? _emojiBurst;

  // ── Live counter animation controllers ────────────────────────────────────
  late final AnimationController _likePopController;
  late final AnimationController _repostPopController;
  late final AnimationController _commentPopController;

  int _prevLikes = 0;
  int _prevReposts = 0;
  int _prevComments = 0;
  bool _prevIsLiked = false;
  bool _prevIsReposted = false;

  _CounterBurstData? _likeCounterBurst;
  _CounterBurstData? _repostCounterBurst;
  _CounterBurstData? _commentCounterBurst;

  
  // ── Swipe transition state ────────────────────────────────────────────────
  double _swipeOffset = 0.0;
  Track? _peekTrack;
  // ignore: unused_field
  bool _swipingToNext = false;
  bool _isSwitching = false;
  String? _pendingSwitchTrackId;

  static const double _commitThreshold = 0.40;
  static const double _velocityThreshold = 800.0;

  // ── Interaction state snapshot — used to avoid setState inside build ──────
  //    We keep a local copy so _checkInteractionChanges can compare safely
  //    without going through addPostFrameCallback every frame.
  TrackInteractionState? _lastInteractionState;

  @override
  void initState() {
    super.initState();
    _playerCubit = context.read<PlayerCubit>();
    _playerCubit.openFullPlayer();

    _likePopController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _repostPopController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _commentPopController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _playerCubit.closeFullPlayer();
    _likePopController.dispose();
    _repostPopController.dispose();
    _commentPopController.dispose();
    super.dispose();
  }

  // ── Detect track change (auto-advance OR manual) ──────────────────────────

  void _onTrackChanged(String newTrackId) {
    if (_lastKnownTrackId == newTrackId) return;
    _lastKnownTrackId = newTrackId;

    // Swipe-initiated switch — cleanup handled by _animateSwipeAndSwitch.
    if (_isSwitching && _pendingSwitchTrackId == newTrackId) return;

    // Auto-advance or external change: reset swipe state next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _swipeOffset = 0;
        _peekTrack = null;
        _isSwitching = false;
        _pendingSwitchTrackId = null;
      });
    });
  }

  // ── Interaction change detection ──────────────────────────────────────────
  // FIX: Called from BlocListener (not inside BlocBuilder), so setState is safe.

  void _checkInteractionChanges(TrackInteractionState state) {
    if (_lastInteractionState == state) return;
    _lastInteractionState = state;

    if (state.likesCount != _prevLikes) {
      final delta = state.likesCount - _prevLikes;
      _likePopController.forward(from: 0);
      _likeCounterBurst = _CounterBurstData(id: UniqueKey(), delta: delta);
      _prevLikes = state.likesCount;
    }
    if (state.isLiked != _prevIsLiked) {
      if (state.isLiked) HapticFeedback.mediumImpact();
      _prevIsLiked = state.isLiked;
    }
    if (state.repostsCount != _prevReposts) {
      final delta = state.repostsCount - _prevReposts;
      _repostPopController.forward(from: 0);
      _repostCounterBurst = _CounterBurstData(id: UniqueKey(), delta: delta);
      _prevReposts = state.repostsCount;
    }
    if (state.isReposted != _prevIsReposted) {
      if (state.isReposted) HapticFeedback.lightImpact();
      _prevIsReposted = state.isReposted;
    }
  }

  void _checkCommentCountChange(int newCount) {
    if (newCount == _prevComments) return;
    final delta = newCount - _prevComments;
    _commentPopController.forward(from: 0);
    setState(() {
      _commentCounterBurst = _CounterBurstData(id: UniqueKey(), delta: delta);
      _prevComments = newCount;
    });
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  Future<void> _loadCommentsCount(String trackId) async {
    try {
      final comments = await getIt<GetTrackCommentsUseCase>()(trackId);
      if (!mounted) return;
      final newCount = comments.length;
      _checkCommentCountChange(newCount);
      setState(() {
        _commentsCount = newCount;
        _timelineComments = comments
            .where((c) => c.timestampSeconds != null)
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _commentsCount = 0;
        _timelineComments = const [];
      });
    }
  }

  Future<void> _addEmojiComment(String emoji, String trackId) async {
    if (_isAddingEmojiComment) return;
    setState(() {
      _isAddingEmojiComment = true;
      _emojiBurst = emoji;
      _emojiBurstId++;
    });
    HapticFeedback.selectionClick();
    try {
      final created = await getIt<CreateCommentUseCase>()(
        trackId: trackId,
        content: emoji,
        timestampSeconds:
            context.read<PlayerCubit>().state.position.inSeconds,
      );
      if (!mounted) return;
      final newCount = _commentsCount + 1;
      _checkCommentCountChange(newCount);
      setState(() {
        _commentsCount = newCount;
        if (created.timestampSeconds != null) {
          _timelineComments = [created, ..._timelineComments];
        }
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Could not add reaction comment');
    } finally {
      if (mounted) setState(() => _isAddingEmojiComment = false);
    }
  }

  // ── Artist follow ─────────────────────────────────────────────────────────

  Future<void> _toggleArtistFollow(Track track) async {
    if (_isFollowingArtist) return;
    final artistId = await _resolveArtistId(track);
    if (!mounted) return;
    if (artistId == null || artistId.isEmpty) {
      _showSnackBar('Artist profile is not available');
      return;
    }
    final authState = _authStateOrNull();
    if (authState is! AuthAuthenticated) {
      _showSnackBar('Please sign in to follow artists');
      return;
    }
    if (authState.user.id.trim() == artistId) {
      _showSnackBar('This is your artist profile');
      return;
    }
    final wasFollowing = _isArtistFollowed(track);
    setState(() {
      _isFollowingArtist = true;
      _setArtistFollowState(track,
          artistId: artistId, isFollowing: !wasFollowing);
    });
    HapticFeedback.selectionClick();
    try {
      final repo = getIt<SocialRepo>();
      final isFollowing = wasFollowing
          ? (await repo.unfollowUser(artistId)).isFollowing
          : (await repo.followUser(artistId)).isFollowing;
      if (!mounted) return;
      setState(() =>
          _setArtistFollowState(track, artistId: artistId, isFollowing: isFollowing));
      SocialEvents.emitFollowChanged();
      _showSnackBar(isFollowing
          ? 'Added ${track.artist} as a friend'
          : 'Unfollowed ${track.artist}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _setArtistFollowState(track,
          artistId: artistId, isFollowing: wasFollowing));
      _showSnackBar(wasFollowing
          ? 'Could not unfollow artist'
          : 'Could not add artist as friend');
    } finally {
      if (mounted) setState(() => _isFollowingArtist = false);
    }
  }

  Future<String?> _resolveArtistId(Track track) async {
    final artistId = track.artistId?.trim();
    if (artistId != null && artistId.isNotEmpty) return artistId;
    final handle = track.handle?.trim();
    if (handle == null || handle.isEmpty) return null;
    try {
      return await getIt<SocialRepo>().getUserIdByHandle(handle);
    } catch (_) {
      return null;
    }
  }

  bool _isArtistFollowed(Track track) {
    final artistId = track.artistId?.trim();
    if (artistId != null &&
        artistId.isNotEmpty &&
        _followedArtistIds.contains(artistId)) return true;
    final handle = track.handle?.trim();
    return handle != null &&
        handle.isNotEmpty &&
        _followedArtistIds.contains('@$handle');
  }

  void _setArtistFollowState(Track track,
      {required String artistId, required bool isFollowing}) {
    final handle = track.handle?.trim();
    if (isFollowing) {
      _followedArtistIds.add(artistId);
      _viewerFollowingIds?.add(artistId);
      if (handle != null && handle.isNotEmpty)
        _followedArtistIds.add('@$handle');
    } else {
      _followedArtistIds.remove(artistId);
      _viewerFollowingIds?.remove(artistId);
      if (handle != null && handle.isNotEmpty)
        _followedArtistIds.remove('@$handle');
    }
  }

  bool _isOwnArtist(Track track) {
    final authState = _authStateOrNull();
    if (authState is! AuthAuthenticated) return false;
    final artistId = track.artistId?.trim();
    if (artistId != null &&
        artistId.isNotEmpty &&
        artistId == authState.user.id.trim()) return true;
    final handle = track.handle?.trim();
    return handle != null &&
        handle.isNotEmpty &&
        handle == authState.user.handle.trim();
  }

  void _ensureArtistFollowStateLoaded(Track track) {
    if (_loadedArtistFollowTrackId == track.id) return;
    _loadedArtistFollowTrackId = track.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _loadedArtistFollowTrackId != track.id) return;
      final authState = _authStateOrNull();
      if (authState is! AuthAuthenticated) return;
      final artistId = await _resolveArtistId(track);
      if (!mounted || _loadedArtistFollowTrackId != track.id) return;
      if (artistId == null || artistId.isEmpty) return;
      if (artistId == authState.user.id.trim()) return;
      final followingIds = await _loadViewerFollowingIds(authState.user.id);
      if (!mounted || _loadedArtistFollowTrackId != track.id) return;
      setState(() => _setArtistFollowState(track,
          artistId: artistId, isFollowing: followingIds.contains(artistId)));
    });
  }

  Future<Set<String>> _loadViewerFollowingIds(String viewerId) async {
    if (_viewerFollowingIds != null) return _viewerFollowingIds!;
    final repo = getIt<SocialRepo>();
    final resolved = <String>{};
    var page = 1;
    const limit = 100;
    try {
      while (true) {
        final users = await repo.getFollowing(viewerId, page, limit: limit);
        for (final user in users) {
          if (user.id.trim().isNotEmpty) resolved.add(user.id.trim());
        }
        if (users.length < limit) break;
        page++;
      }
    } catch (_) {}
    _viewerFollowingIds = resolved;
    return resolved;
  }

  AuthState? _authStateOrNull() {
    try {
      return context.read<AuthCubit>().state;
    } catch (_) {
      return null;
    }
  }

  // ── Sheets ────────────────────────────────────────────────────────────────

  Future<void> _shareTrackToConversation(
      BuildContext context, Track track) async {
    await showShareTrackToConversationSheet(
        context: context, trackId: track.id, text: 'Check out this track');
  }

  List<CommentEntity> _activeTimelineComments(Duration position) {
    final second = position.inSeconds;
    return _timelineComments
        .where((c) => c.timestampSeconds == second)
        .take(2)
        .toList(growable: false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF333333),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      content: Text(message),
    ));
  }

  Future<void> _openComments(BuildContext context, String trackId) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<CommentsCubit>()..load(trackId),
          child: TrackCommentsPage(
            trackId: trackId,
            getCurrentPositionSeconds: () =>
                context.read<PlayerCubit>().state.position.inSeconds,
            onSeekToTimestamp: (seconds) {
              context.read<PlayerCubit>().seek(Duration(seconds: seconds));
            },
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      _checkCommentCountChange(result);
      setState(() => _commentsCount = result);
    }
    await _loadCommentsCount(trackId);
  }

  void _openEngagementList(BuildContext context,
      {required String trackId, required EngagementListType type}) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<EngagementListCubit>()
              ..load(trackId: trackId, type: type),
            child: EngagementListPage(trackId: trackId, type: type),
          ),
        ));
  }

  void _showQueue(BuildContext context) {
    final playerCubit = context.read<PlayerCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocBuilder<PlayerCubit, PlayerUIState>(
        bloc: playerCubit,
        builder: (ctx, playerState) =>
            _QueueSheet(playerCubit: playerCubit, playerState: playerState),
      ),
    );
  }

  void _ensureTrackDataLoaded(BuildContext context, {
  required String trackId,
  required int likesCount,
  required int repostsCount,
}) {
  if (_loadedTrackId == trackId) return;
  _loadedTrackId = trackId;

  // ← خد الـ counts من الـ cubit لو موجود للـ track ده
  final interactionCubit = context.read<TrackInteractionCubit>();
  final currentCount = interactionCubit.state;
  
  _prevLikes = likesCount;
  _prevReposts = repostsCount;
  _prevComments = 0;
  _lastInteractionState = null;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || _loadedTrackId != trackId) return;
    context.read<TrackInteractionCubit>().load(
      trackId: trackId,
      // ← لو الـ cubit عنده state محدث للـ track ده، خد منه
      likesCount: currentCount.likesCount > 0 
          ? currentCount.likesCount 
          : likesCount,
      repostsCount: currentCount.repostsCount > 0 
          ? currentCount.repostsCount 
          : repostsCount,
    );
    _loadCommentsCount(trackId);
  });
}

  // ── Swipe gesture handlers ────────────────────────────────────────────────

  void _onDragStart(DragStartDetails details, PlayerUIState state) {
    if (_isSwitching) return;
    _swipeOffset = 0.0;
    _peekTrack = null;
  }

  void _onDragUpdate(DragUpdateDetails details, PlayerUIState state) {
    if (_isSwitching) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final delta = details.delta.dx / screenWidth;
    final newOffset = (_swipeOffset + delta).clamp(-1.0, 1.0);

    if (newOffset < 0) {
      final nextIndex = state.currentIndex + 1;
      if (nextIndex < state.queue.length) {
        _peekTrack = state.queue[nextIndex];
        _swipingToNext = true;
      } else {
        if (mounted) setState(() => _swipeOffset = 0);
        return;
      }
    } else if (newOffset > 0) {
      final prevIndex = state.currentIndex - 1;
      if (prevIndex >= 0) {
        _peekTrack = state.queue[prevIndex];
        _swipingToNext = false;
      } else {
        if (mounted) setState(() => _swipeOffset = 0);
        return;
      }
    } else {
      _peekTrack = null;
    }

    // Auto-commit at 50%
    if (newOffset.abs() >= 0.50 && _peekTrack != null && !_isSwitching) {
      HapticFeedback.mediumImpact();
      final targetOffset = newOffset < 0 ? -1.0 : 1.0;
      final playerCubit = context.read<PlayerCubit>();
      _animateSwipeAndSwitch(targetOffset, playerCubit, state);
      return;
    }

    if (mounted) setState(() => _swipeOffset = newOffset);
  }

  void _onDragEnd(DragEndDetails details, PlayerCubit playerCubit,
      PlayerUIState state) {
    if (_isSwitching) return;
    final velocity = details.primaryVelocity ?? 0;
    final absVelocity = velocity.abs();
    final committed = _swipeOffset.abs() >= _commitThreshold ||
        absVelocity >= _velocityThreshold;

    if (committed && _peekTrack != null) {
      HapticFeedback.mediumImpact();
      final targetOffset = _swipeOffset < 0 ? -1.0 : 1.0;
      _animateSwipeAndSwitch(targetOffset, playerCubit, state);
    } else {
      _animateSwipeBack();
    }
  }

  void _animateSwipeAndSwitch(
      double target, PlayerCubit playerCubit, PlayerUIState state) {
    if (_isSwitching) return;
    _isSwitching = true;

    if (target < 0) {
      final nextIndex = state.currentIndex + 1;
      if (nextIndex < state.queue.length) {
        _pendingSwitchTrackId = state.queue[nextIndex].id;
      }
    } else {
      final prevIndex = state.currentIndex - 1;
      if (prevIndex >= 0) {
        _pendingSwitchTrackId = state.queue[prevIndex].id;
      }
    }

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    final anim = Tween<double>(begin: _swipeOffset, end: target).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut));

    anim.addListener(() {
      if (mounted) setState(() => _swipeOffset = anim.value);
    });

    controller.forward().then((_) {
      controller.dispose();
      if (!mounted) {
        _isSwitching = false;
        _pendingSwitchTrackId = null;
        return;
      }

      // Trigger the actual track switch.
      if (target < 0) {
        playerCubit.playNext();
      } else {
        playerCubit.playPrevious();
      }

      // Wait one frame for BLoC to emit the new track, then clear overlay.
      // This prevents the old artwork flashing back momentarily.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _swipeOffset = 0;
            _peekTrack = null;
            _isSwitching = false;
            _pendingSwitchTrackId = null;
          });
        } else {
          _isSwitching = false;
          _pendingSwitchTrackId = null;
        }
      });
    });
  }

  void _animateSwipeBack() {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final anim = Tween<double>(begin: _swipeOffset, end: 0.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut));

    anim.addListener(() {
      if (mounted) setState(() => _swipeOffset = anim.value);
    });

    controller.forward().then((_) {
      controller.dispose();
      if (mounted) {
        setState(() {
          _swipeOffset = 0;
          _peekTrack = null;
        });
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: FullPlayerPage.playerHeroTag,
      transitionOnUserGestures: true,
      createRectTween: (begin, end) =>
          MaterialRectCenterArcTween(begin: begin, end: end),
      child: Material(
        color: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: BlocBuilder<PlayerCubit, PlayerUIState>(
            builder: (context, state) {
              final track = state.currentTrack;
              if (track == null) {
                return const Center(
                    child: Text('No track selected',
                        style: TextStyle(color: Colors.white)));
              }

              _onTrackChanged(track.id);
              _ensureTrackDataLoaded(context,
                  trackId: track.id,
                  likesCount: track.likesCount,
                  repostsCount: track.repostsCount);
              _ensureArtistFollowStateLoaded(track);

              return BlocConsumer<TrackInteractionCubit, TrackInteractionState>(
                // FIX: Use listener (not builder) for side-effects that call
                // setState. This runs outside the build phase — no more
                // addPostFrameCallback hack that caused screen freezes.
                listener: (context, interactionState) {
                  _checkInteractionChanges(interactionState);
                },
                builder: (context, interactionState) {
                  final activeComments =
                      _activeTimelineComments(state.position);
                  final isArtistFollowed = _isArtistFollowed(track);
                  final isOwnArtist = _isOwnArtist(track);
                  final playerCubit = context.read<PlayerCubit>();
                  final screenWidth = MediaQuery.of(context).size.width;

                  return GestureDetector(
                    onHorizontalDragStart: (d) => _onDragStart(d, state),
                    onHorizontalDragUpdate: (d) => _onDragUpdate(d, state),
                    onHorizontalDragEnd: (d) =>
                        _onDragEnd(d, playerCubit, state),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          // ── Peek track artwork ──────────────────────────
                          if (_peekTrack != null)
                            Positioned.fill(
                              child: Transform.translate(
                                offset: Offset(
                                  _swipeOffset < 0
                                      ? screenWidth +
                                          (_swipeOffset * screenWidth)
                                      : -screenWidth +
                                          (_swipeOffset * screenWidth),
                                  0,
                                ),
                                child: _TrackBackground(
                                    track: _peekTrack!,
                                    isPlaying: true,
                                    progress: 0),
                              ),
                            ),

                          // ── Current track — keyed on track.id so Flutter
                          //    rebuilds the whole subtree when track changes.
                          //    This fixes old-artwork-stuck on auto-advance.
                          Transform.translate(
                            key: ValueKey('track_${track.id}'),
                            offset: Offset(_swipeOffset * screenWidth, 0),
                            child: _buildCurrentTrack(
                              context: context,
                              state: state,
                              track: track,
                              interactionState: interactionState,
                              activeComments: activeComments,
                              isArtistFollowed: isArtistFollowed,
                              isOwnArtist: isOwnArtist,
                              playerCubit: playerCubit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTrack({
    required BuildContext context,
    required PlayerUIState state,
    required Track track,
    required TrackInteractionState interactionState,
    required List<CommentEntity> activeComments,
    required bool isArtistFollowed,
    required bool isOwnArtist,
    required PlayerCubit playerCubit,
  }) {
    final total = state.duration?.inSeconds ?? 1;
    final current = state.position.inSeconds;
    final artworkProgress =
        total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Stack(
      children: [
        // ── Background artwork ──────────────────────────────────────────
        Positioned.fill(
          child: _TrackBackground(
            track: track,
            isPlaying: state.isPlaying,
            progress: artworkProgress,
          ),
        ),

        // ── Gradient overlay ────────────────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xAA000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xDD000000),
                  Colors.black,
                ],
                stops: [0.0, 0.20, 0.55, 0.78, 1.0],
              ),
            ),
          ),
        ),

        // ── Main Content ────────────────────────────────────────────────
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 6)
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 4)
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.equalizer,
                                    color: Colors.white70, size: 14),
                                SizedBox(width: 5),
                                Text('Behind this track',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _SoundCloudCircleBtn(
                          icon: Icons.keyboard_arrow_down,
                          onTap: () {
                            context.read<PlayerCubit>().closeFullPlayer();
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 10),
                        _SoundCloudCircleBtn(
                          icon: isOwnArtist
                              ? Icons.person
                              : isArtistFollowed
                                  ? Icons.person_remove_outlined
                                  : Icons.person_add_outlined,
                          isBusy: _isFollowingArtist,
                          onTap: isOwnArtist
                              ? () =>
                                  _showSnackBar('This is your artist profile')
                              : () => _toggleArtistFollow(track),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Spacer — tap to play/pause ──────────────────────────
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => playerCubit.togglePlayPause(),
                  child: const SizedBox.expand(),
                ),
              ),

              // ── Timeline comment bubble ─────────────────────────────
              if (activeComments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _TimelineCommentBubble(
                      key: ValueKey(
                          '${activeComments.first.id}-${state.position.inSeconds}'),
                      comment: activeComments.first,
                    ),
                  ),
                ),

              // ── Waveform — wrapped in its own GestureDetector so
              //    horizontal drags here do NOT propagate to the swipe
              //    gesture detector above and cause track skipping.
              GestureDetector(
                onHorizontalDragStart: (_) {},
                onHorizontalDragUpdate: (_) {},
                onHorizontalDragEnd: (_) {},
                behavior: HitTestBehavior.opaque,
                child: ScrollingWaveform(
                  position: state.position,
                  duration: state.duration,
                  waveformData: state.waveform,
                  isPlaying: state.isPlaying,
                  commentTimestampsSeconds: _timelineComments
                      .map((c) => c.timestampSeconds!)
                      .toSet()
                      .toList(growable: false),
                  onSeek: (pos) => context.read<PlayerCubit>().seek(pos),
                ),
              ),

              // ── Comment / emoji bar ─────────────────────────────────
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openComments(context, track.id),
                              child: const Text('Comment...',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 14)),
                            ),
                          ),
                          _QuickEmojiButton(
                              emoji: '🔥',
                              enabled: !_isAddingEmojiComment,
                              onTap: () => _addEmojiComment('🔥', track.id)),
                          const SizedBox(width: 12),
                          _QuickEmojiButton(
                              emoji: '👏',
                              enabled: !_isAddingEmojiComment,
                              onTap: () => _addEmojiComment('👏', track.id)),
                          const SizedBox(width: 12),
                          _QuickEmojiButton(
                              emoji: '🥰',
                              enabled: !_isAddingEmojiComment,
                              onTap: () => _addEmojiComment('🥰', track.id)),
                        ],
                      ),
                    ),
                    if (_emojiBurst != null)
                      Positioned(
                        right: 60,
                        top: -24,
                        child: _EmojiBurst(
                            key: ValueKey(_emojiBurstId),
                            emoji: _emojiBurst!),
                      ),
                  ],
                ),
              ),

              // ── Bottom interactions bar ─────────────────────────────
              const SizedBox(height: 14),
              _BottomInteractionsBar(
                likePopController: _likePopController,
                repostPopController: _repostPopController,
                commentPopController: _commentPopController,
                likeCounterBurst: _likeCounterBurst,
                repostCounterBurst: _repostCounterBurst,
                commentCounterBurst: _commentCounterBurst,
                likesCount: interactionState.likesCount,
                repostsCount: interactionState.repostsCount,
                commentsCount: _commentsCount,
                isLiked: interactionState.isLiked,
                isReposted: interactionState.isReposted,
                isSubmittingLike: interactionState.isSubmittingLike,
                isSubmittingRepost: interactionState.isSubmittingRepost,
                onLikeToggle: () =>
                    context.read<TrackInteractionCubit>().toggleLike(track.id),
                onLikesTap: () => _openEngagementList(context,
                    trackId: track.id, type: EngagementListType.likers),
                onCommentsTap: () => _openComments(context, track.id),
                onRepostToggle: () => context
                    .read<TrackInteractionCubit>()
                    .toggleRepost(track.id),
                onRepostsTap: () => _openEngagementList(context,
                    trackId: track.id, type: EngagementListType.reposters),
                onShareTap: () => _shareTrackToConversation(context, track),
                onQueueTap: () => _showQueue(context),
                onMoreTap: () => TrackOptionsSheet.show(context, track: track),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        // ── Paused overlay ──────────────────────────────────────────────
        // FIX: Only render when actually paused — avoids lingering overlay
        // after play resumes (was caused by stale setState timing).
        if (!state.isPlaying)
          Positioned.fill(
            child: _PausedControls(
              canPlayPrevious: state.currentIndex > 0,
              onPlay: () => playerCubit.togglePlayPause(),
              onSkipNext: () => playerCubit.playNext(),
              onSkipPrevious: () => playerCubit.playPrevious(),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Track background — animated artwork
// FIX: Key on artworkUrl forces real image rebuild when track changes,
//      preventing old artwork from showing after auto-advance.
// ════════════════════════════════════════════════════════════════════════════

class _TrackBackground extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final double progress;

  const _TrackBackground({
    required this.track,
    required this.isPlaying,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (track.artworkUrl == null) return Container(color: Colors.black);

    final scale = 1.0 + progress * 0.08;
    final translateY = progress * -12.0;

    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(scale, scale)
              ..translate(0.0, translateY),
            child: Image.network(
              track.artworkUrl!,
              fit: BoxFit.cover,
              // Key on URL forces a real rebuild when track changes.
              // This is the primary fix for "old artwork stuck on auto-advance".
              key: ValueKey(track.artworkUrl),
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
              loadingBuilder: (_, child, loading) =>
                  loading == null ? child : Container(color: Colors.black),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: isPlaying
                ? const SizedBox.shrink()
                : BackdropFilter(
                    key: const ValueKey('blur'),
                    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.30),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Paused controls overlay
// ════════════════════════════════════════════════════════════════════════════

class _PausedControls extends StatelessWidget {
  final bool canPlayPrevious;
  final VoidCallback onPlay;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;

  const _PausedControls({
    required this.canPlayPrevious,
    required this.onPlay,
    required this.onSkipNext,
    required this.onSkipPrevious,
  });

  @override
  Widget build(BuildContext context) {
    const double sideSize = 56;
    const double playSize = 72;
    const double gap = 28;

    return IgnorePointer(
      ignoring: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 160),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: sideSize,
                height: sideSize,
                child: canPlayPrevious
                    ? _ControlBtn(
                        size: sideSize,
                        icon: Icons.skip_previous,
                        iconSize: 30,
                        onTap: onSkipPrevious)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: gap),
              _ControlBtn(
                  size: playSize,
                  icon: Icons.play_arrow,
                  iconSize: 40,
                  onTap: onPlay),
              const SizedBox(width: gap),
              _ControlBtn(
                  size: sideSize,
                  icon: Icons.skip_next,
                  iconSize: 30,
                  onTap: onSkipNext),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final double size;
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.size,
    required this.icon,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Bottom Interactions Bar
// ════════════════════════════════════════════════════════════════════════════

class _CounterBurstData {
  final Key id;
  final int delta;
  const _CounterBurstData({required this.id, required this.delta});
}

class _BottomInteractionsBar extends StatelessWidget {
  final AnimationController likePopController;
  final AnimationController repostPopController;
  final AnimationController commentPopController;
  final _CounterBurstData? likeCounterBurst;
  final _CounterBurstData? repostCounterBurst;
  final _CounterBurstData? commentCounterBurst;
  final int likesCount, repostsCount, commentsCount;
  final bool isLiked, isReposted, isSubmittingLike, isSubmittingRepost;
  final VoidCallback onLikeToggle, onLikesTap, onCommentsTap;
  final VoidCallback onRepostToggle, onRepostsTap;
  final VoidCallback onShareTap, onQueueTap, onMoreTap;

  const _BottomInteractionsBar({
    required this.likePopController,
    required this.repostPopController,
    required this.commentPopController,
    required this.likeCounterBurst,
    required this.repostCounterBurst,
    required this.commentCounterBurst,
    required this.likesCount,
    required this.repostsCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isReposted,
    required this.isSubmittingLike,
    required this.isSubmittingRepost,
    required this.onLikeToggle,
    required this.onLikesTap,
    required this.onCommentsTap,
    required this.onRepostToggle,
    required this.onRepostsTap,
    required this.onShareTap,
    required this.onQueueTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _LiveCounterBtn(
            controller: likePopController,
            counterBurst: likeCounterBurst,
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            count: likesCount,
            isActive: isLiked,
            activeColor: Colors.white,
            isBusy: isSubmittingLike,
            onIconTap: onLikeToggle,
            onCountTap: onLikesTap,
          ),
          _LiveCounterBtn(
            controller: commentPopController,
            counterBurst: commentCounterBurst,
            icon: Icons.mode_comment_outlined,
            count: commentsCount,
            isActive: false,
            activeColor: Colors.white,
            isBusy: false,
            onIconTap: onCommentsTap,
            onCountTap: onCommentsTap,
          ),
          _SimpleIconBtn(icon: Icons.share_outlined, onTap: onShareTap),
          _SimpleIconBtn(icon: Icons.queue_music_outlined, onTap: onQueueTap),
          _SimpleIconBtn(icon: Icons.more_vert, onTap: onMoreTap),
        ],
      ),
    );
  }
}

class _LiveCounterBtn extends StatefulWidget {
  final AnimationController controller;
  final _CounterBurstData? counterBurst;
  final IconData icon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final bool isBusy;
  final VoidCallback onIconTap;
  final VoidCallback onCountTap;

  const _LiveCounterBtn({
    required this.controller,
    required this.counterBurst,
    required this.icon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.isBusy,
    required this.onIconTap,
    required this.onCountTap,
  });

  @override
  State<_LiveCounterBtn> createState() => _LiveCounterBtnState();
}

class _LiveCounterBtnState extends State<_LiveCounterBtn> {
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.85), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.08), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 20),
    ]).animate(
        CurvedAnimation(parent: widget.controller, curve: Curves.easeInOut));
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.isBusy ? null : widget.onIconTap,
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (_, child) =>
                Transform.scale(scale: _iconScale.value, child: child),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(key: ValueKey(widget.isActive), widget.icon,
                  color: Colors.white, size: 26),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: widget.onCountTap,
          child: SizedBox(
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.6), end: Offset.zero)
                        .animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Text(
                    key: ValueKey(_fmt(widget.count)),
                    _fmt(widget.count),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                if (widget.counterBurst != null)
                  Positioned(
                    top: -22,
                    child: _CounterBurst(
                        key: widget.counterBurst!.id,
                        delta: widget.counterBurst!.delta),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SimpleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SimpleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _CounterBurst extends StatelessWidget {
  final int delta;
  const _CounterBurst({super.key, required this.delta});

  @override
  Widget build(BuildContext context) {
    final label = delta > 0 ? '+$delta' : '$delta';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: (1 - value).clamp(0.0, 1.0),
        child: Transform.translate(
            offset: Offset(0, -18 * value), child: child),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SoundCloud circle button
// ════════════════════════════════════════════════════════════════════════════

class _SoundCloudCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isBusy;

  const _SoundCloudCircleBtn(
      {required this.icon, required this.onTap, this.isBusy = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: isBusy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Queue Sheet
// ════════════════════════════════════════════════════════════════════════════

class _QueueSheet extends StatefulWidget {
  final PlayerCubit playerCubit;
  final PlayerUIState playerState;
  const _QueueSheet({required this.playerCubit, required this.playerState});

  @override
  State<_QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<_QueueSheet> {
  late List<Track> _queue;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _queue = List<Track>.from(widget.playerState.queue);
    _currentIndex = widget.playerState.currentIndex;
  }

  @override
  void didUpdateWidget(covariant _QueueSheet old) {
    super.didUpdateWidget(old);
    if (!_same(old.playerState.queue, widget.playerState.queue)) {
      setState(() {
        _queue = List<Track>.from(widget.playerState.queue);
        _currentIndex = widget.playerState.currentIndex;
      });
    }
  }

  bool _same(List<Track> a, List<Track> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final t = _queue.removeAt(oldIndex);
      _queue.insert(newIndex, t);
      final id = widget.playerState.currentTrack?.id;
      if (id != null) _currentIndex = _queue.indexWhere((t) => t.id == id);
    });
    widget.playerCubit.reorderQueue(List<Track>.from(_queue));
  }

  String _fmtSource(String s) => switch (s) {
        'home_trending' => 'a recent play queue',
        'profile_likes' => 'your liked tracks',
        'profile_reposts' => 'your reposts',
        'station' => 'station',
        _ => 'a recent play queue',
      };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
              child: Row(
                children: [
                  const Text('Next up',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.shuffle,
                          color: Colors.white38, size: 22),
                      onPressed: null),
                  RepeatModeButton(
                    mode: widget.playerState.repeatMode,
                    iconSize: 22,
                    showOptions: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    onChanged: (m) => widget.playerCubit.setRepeatMode(m),
                  ),
                ],
              ),
            ),
            if (widget.playerState.playerState.source != null)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      'From ${_fmtSource(widget.playerState.playerState.source!)}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ),
              ),
            Expanded(
              child: _queue.isEmpty
                  ? const Center(
                      child: Text('Queue is empty',
                          style: TextStyle(color: Colors.white38)))
                  : ReorderableListView.builder(
                      scrollController: sc,
                      onReorder: _onReorder,
                      buildDefaultDragHandles: false,
                      itemCount: _queue.length,
                      itemBuilder: (context, i) {
                        final t = _queue[i];
                        final isPlaying =
                            t.id == widget.playerState.currentTrack?.id;
                        final isPlayed = i < _currentIndex;
                        final isPaused =
                            isPlaying && !widget.playerState.isPlaying;
                        return _QueueTile(
                          key: ValueKey(t.id),
                          track: t,
                          index: i,
                          isPlaying: isPlaying,
                          isPaused: isPaused,
                          isPlayed: isPlayed,
                          onTap: () {
                            widget.playerCubit.playFromContext(
                                tracks: _queue,
                                startIndex: i,
                                source:
                                    widget.playerState.playerState.source ??
                                        'queue');
                            Navigator.pop(context);
                          },
                          onOptions: () =>
                              TrackOptionsSheet.show(context, track: t),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final Track track;
  final int index;
  final bool isPlaying, isPaused, isPlayed;
  final VoidCallback onTap, onOptions;

  const _QueueTile(
      {super.key,
      required this.track,
      required this.index,
      required this.isPlaying,
      required this.isPaused,
      required this.isPlayed,
      required this.onTap,
      required this.onOptions});

  @override
  Widget build(BuildContext context) {
    final titleColor = isPlaying
        ? const Color(0xFFFF5500)
        : isPlayed
            ? Colors.white30
            : Colors.white;
    final artistColor = isPlaying
        ? const Color(0xFFFF5500).withValues(alpha: 0.7)
        : isPlayed
            ? Colors.white24
            : Colors.white54;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(4),
                    image: track.artworkUrl != null
                        ? DecorationImage(
                            image: NetworkImage(track.artworkUrl!),
                            fit: BoxFit.cover,
                            colorFilter: isPlayed && !isPlaying
                                ? ColorFilter.mode(
                                    Colors.black.withValues(alpha: 0.5),
                                    BlendMode.darken)
                                : null)
                        : null,
                  ),
                  child: track.artworkUrl == null
                      ? Icon(Icons.music_note,
                          color: isPlayed ? Colors.white24 : Colors.white54,
                          size: 20)
                      : null,
                ),
                if (isPlaying)
                  Positioned.fill(
                      child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(4)),
                    child: Icon(
                        isPaused ? Icons.pause : Icons.equalizer,
                        color: const Color(0xFFFF5500),
                        size: 20),
                  )),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(track.title,
                      style: TextStyle(
                          color: titleColor,
                          fontSize: 14,
                          fontWeight: isPlaying
                              ? FontWeight.w600
                              : FontWeight.normal),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  const SizedBox(height: 2),
                  Text(
                      isPlaying
                          ? (isPaused ? '⏸  Paused' : '▶  Now Playing')
                          : track.artist,
                      style: TextStyle(
                          color: artistColor,
                          fontSize: 12,
                          fontWeight: isPlaying
                              ? FontWeight.w600
                              : FontWeight.normal),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (isPlaying || isPlayed)
              GestureDetector(
                  onTap: onOptions,
                  child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      child: Icon(Icons.more_vert,
                          color: Colors.white54, size: 22)))
            else
              ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      child: Icon(Icons.drag_indicator,
                          color: Colors.white38, size: 22))),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Small shared widgets
// ════════════════════════════════════════════════════════════════════════════

class _QuickEmojiButton extends StatefulWidget {
  final String emoji;
  final bool enabled;
  final VoidCallback onTap;
  const _QuickEmojiButton(
      {required this.emoji, required this.enabled, required this.onTap});

  @override
  State<_QuickEmojiButton> createState() => _QuickEmojiButtonState();
}

class _QuickEmojiButtonState extends State<_QuickEmojiButton> {
  bool _pressed = false;

  void _handleTap() {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    widget.onTap();
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed ? 1.45 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: Text(widget.emoji,
            style: TextStyle(
                fontSize: 22,
                color: widget.enabled ? null : Colors.white38)),
      ),
    );
  }
}

class _EmojiBurst extends StatelessWidget {
  final String emoji;
  const _EmojiBurst({super.key, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: (1 - v).clamp(0.0, 1.0),
        child: Transform.translate(
            offset: Offset(0, -34 * v),
            child: Transform.scale(scale: 1 + v * 0.7, child: child)),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 30)),
    );
  }
}

class _TimelineCommentBubble extends StatelessWidget {
  final CommentEntity comment;
  const _TimelineCommentBubble({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
                color: Colors.white24, shape: BoxShape.circle),
            child:
                const Icon(Icons.person, color: Colors.white54, size: 14),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(comment.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}