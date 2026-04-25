// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

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
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/events/social_events.dart';

import '../widgets/player_actions.dart';
import '../widgets/player_waveform.dart';
import '../widgets/repeat_mode_button.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key});

  static const String playerHeroTag = 'player_shell_hero';

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> {
  late PlayerCubit _playerCubit;
  String? _loadedTrackId;
  int _commentsCount = 0;
  List<CommentEntity> _timelineComments = const [];
  final Set<String> _followedArtistIds = <String>{};
  Set<String>? _viewerFollowingIds;
  String? _loadedArtistFollowTrackId;
  bool _isAddingEmojiComment = false;
  bool _isFollowingArtist = false;
  int _emojiBurstId = 0;
  String? _emojiBurst;

  @override
  void initState() {
    super.initState();
    _playerCubit = context.read<PlayerCubit>();
    _playerCubit.openFullPlayer();
  }

  @override
  void dispose() {
    _playerCubit.closeFullPlayer();
    super.dispose();
  }

  Future<void> _loadCommentsCount(String trackId) async {
    try {
      final comments = await getIt<GetTrackCommentsUseCase>()(trackId);
      if (!mounted) return;

      setState(() {
        _commentsCount = comments.length;
        _timelineComments = comments
            .where((comment) => comment.timestampSeconds != null)
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

    try {
      final created = await getIt<CreateCommentUseCase>()(
        trackId: trackId,
        content: emoji,
        timestampSeconds: context.read<PlayerCubit>().state.position.inSeconds,
      );

      if (!mounted) return;
      setState(() {
        _commentsCount += 1;
        if (created.timestampSeconds != null) {
          _timelineComments = [created, ..._timelineComments];
        }
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Could not add reaction comment');
    } finally {
      if (mounted) {
        setState(() {
          _isAddingEmojiComment = false;
        });
      }
    }
  }

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

    try {
      final repo = getIt<SocialRepo>();
      final isFollowing = wasFollowing
          ? (await repo.unfollowUser(artistId)).isFollowing
          : (await repo.followUser(artistId)).isFollowing;

      if (!mounted) return;
      setState(() {
        _setArtistFollowState(
          track,
          artistId: artistId,
          isFollowing: isFollowing,
        );
      });
      SocialEvents.emitFollowChanged();
      _showSnackBar(
        isFollowing
            ? 'Added ${track.artist} as a friend'
            : 'Unfollowed ${track.artist}',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setArtistFollowState(
          track,
          artistId: artistId,
          isFollowing: wasFollowing,
        );
      });
      _showSnackBar(
        wasFollowing
            ? 'Could not unfollow artist'
            : 'Could not add artist as friend',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowingArtist = false;
        });
      }
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

  void _openBroadcastSheet(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.radio, color: Colors.white70),
                title: const Text(
                  'Start track station',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Broadcast ${track.title} from the current queue',
                  style: const TextStyle(color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startTrackStation(track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.white70),
                title: const Text(
                  'Copy track link',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: 'soundclone://track/${track.id}'),
                  );
                  if (!mounted) return;
                  Navigator.pop(sheetContext);
                  _showSnackBar('Track link copied');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startTrackStation(Track track) {
    final queue = context.read<PlayerCubit>().state.playerState.queue;
    final stationQueue = queue.isEmpty ? [track] : queue;
    final index = stationQueue.indexWhere((item) => item.id == track.id);

    context.read<PlayerCubit>().playFromContext(
          tracks: stationQueue,
          startIndex: index >= 0 ? index : 0,
          source: 'station',
        );

    _showSnackBar('Broadcast started from ${track.title}');
  }

  List<CommentEntity> _activeTimelineComments(Duration position) {
    final second = position.inSeconds;
    return _timelineComments
        .where((comment) => comment.timestampSeconds == second)
        .take(2)
        .toList(growable: false);
  }

  bool _isArtistFollowed(Track track) {
    final artistId = track.artistId?.trim();
    if (artistId != null &&
        artistId.isNotEmpty &&
        _followedArtistIds.contains(artistId)) {
      return true;
    }

    final handle = track.handle?.trim();
    return handle != null &&
        handle.isNotEmpty &&
        _followedArtistIds.contains('@$handle');
  }

  void _setArtistFollowState(
    Track track, {
    required String artistId,
    required bool isFollowing,
  }) {
    final handle = track.handle?.trim();

    if (isFollowing) {
      _followedArtistIds.add(artistId);
      _viewerFollowingIds?.add(artistId);
      if (handle != null && handle.isNotEmpty) {
        _followedArtistIds.add('@$handle');
      }
      return;
    }

    _followedArtistIds.remove(artistId);
    _viewerFollowingIds?.remove(artistId);
    if (handle != null && handle.isNotEmpty) {
      _followedArtistIds.remove('@$handle');
    }
  }

  bool _isOwnArtist(Track track) {
    final authState = _authStateOrNull();
    if (authState is! AuthAuthenticated) return false;

    final artistId = track.artistId?.trim();
    if (artistId != null &&
        artistId.isNotEmpty &&
        artistId == authState.user.id.trim()) {
      return true;
    }

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

      setState(() {
        _setArtistFollowState(
          track,
          artistId: artistId,
          isFollowing: followingIds.contains(artistId),
        );
      });
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
          if (user.id.trim().isNotEmpty) {
            resolved.add(user.id.trim());
          }
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Text(message),
      ),
    );
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
      setState(() {
        _commentsCount = result;
      });
    }

    await _loadCommentsCount(trackId);
  }

  void _openEngagementList(
    BuildContext context, {
    required String trackId,
    required EngagementListType type,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<EngagementListCubit>()
            ..load(
              trackId: trackId,
              type: type,
            ),
          child: EngagementListPage(
            trackId: trackId,
            type: type,
          ),
        ),
      ),
    );
  }

  void _showQueue(BuildContext context) {
    final playerCubit = context.read<PlayerCubit>();
    final queue = playerCubit.state.playerState.queue;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        if (queue.isEmpty) {
          return const SizedBox(
            height: 260,
            child: Center(
              child: Text(
                'Queue is empty',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Up Next',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final track = queue[index];
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                        image: track.artworkUrl != null
                            ? DecorationImage(
                                image: NetworkImage(track.artworkUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: track.artworkUrl == null
                          ? const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                              size: 20,
                            )
                          : null,
                    ),
                    title: Text(
                      track.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artist,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      playerCubit.playFromContext(
                        tracks: queue,
                        startIndex: index,
                        source: 'queue',
                      );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _ensureTrackDataLoaded(
    BuildContext context, {
    required String trackId,
    required int likesCount,
    required int repostsCount,
  }) {
    if (_loadedTrackId == trackId) return;

    _loadedTrackId = trackId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedTrackId != trackId) return;

      context.read<TrackInteractionCubit>().load(
            trackId: trackId,
            likesCount: likesCount,
            repostsCount: repostsCount,
          );

      _loadCommentsCount(trackId);
    });
  }

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
                  child: Text(
                    'No track selected',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              _ensureTrackDataLoaded(
                context,
                trackId: track.id,
                likesCount: track.likesCount,
                repostsCount: track.repostsCount,
              );
              _ensureArtistFollowStateLoaded(track);

              return BlocBuilder<TrackInteractionCubit, TrackInteractionState>(
                builder: (context, interactionState) {
                  final activeComments = _activeTimelineComments(
                    state.position,
                  );
                  final isArtistFollowed = _isArtistFollowed(track);
                  final isOwnArtist = _isOwnArtist(track);

                  return Stack(
                    children: [
                      if (track.artworkUrl != null)
                        Positioned.fill(
                          child: Image.network(
                            track.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.black),
                            loadingBuilder: (_, child, loading) =>
                                loading == null
                                    ? child
                                    : Container(color: Colors.black),
                          ),
                        ),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Color(0xCC000000),
                                Colors.black,
                              ],
                              stops: [0.0, 0.35, 0.65, 0.85],
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black54,
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          track.artist,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      _CircleBtn(
                                        icon: Icons.keyboard_arrow_down,
                                        onTap: () {
                                          context
                                              .read<PlayerCubit>()
                                              .closeFullPlayer();
                                          Navigator.pop(context);
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _CircleBtn(
                                        icon: isOwnArtist
                                            ? Icons.person
                                            : isArtistFollowed
                                                ? Icons.person_remove_outlined
                                                : Icons.person_add_outlined,
                                        isActive: isArtistFollowed,
                                        isBusy: _isFollowingArtist,
                                        onTap: isOwnArtist
                                            ? () => _showSnackBar(
                                                  'This is your artist profile',
                                                )
                                            : () => _toggleArtistFollow(track),
                                      ),
                                      const SizedBox(height: 12),
                                      _CircleBtn(
                                        icon: Icons.cast,
                                        onTap: () =>
                                            _openBroadcastSheet(context, track),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: activeComments.isEmpty
                                        ? const SizedBox(height: 0)
                                        : _TimelineCommentBubble(
                                            key: ValueKey(
                                              '${activeComments.first.id}-${state.position.inSeconds}',
                                            ),
                                            comment: activeComments.first,
                                          ),
                                  ),
                                  PlayerWaveform(
                                    position: state.position,
                                    duration: state.duration,
                                    waveformData: state.waveform,
                                    commentTimestampsSeconds: _timelineComments
                                        .map(
                                          (comment) =>
                                              comment.timestampSeconds!,
                                        )
                                        .toSet()
                                        .toList(growable: false),
                                    onSeek: (pos) =>
                                        context.read<PlayerCubit>().seek(pos),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_format(state.position)} | ${_format(state.duration ?? Duration.zero)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.volume_up,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: state.volume,
                                      activeColor: const Color(0xFFFF5500),
                                      onChanged: (value) => context
                                          .read<PlayerCubit>()
                                          .setVolume(value),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            onTap: () => _openComments(
                                                context, track.id),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                              child: Text(
                                                'Comment...',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        _QuickEmojiButton(
                                          emoji: '🔥',
                                          enabled: !_isAddingEmojiComment,
                                          onTap: () =>
                                              _addEmojiComment('🔥', track.id),
                                        ),
                                        const SizedBox(width: 10),
                                        _QuickEmojiButton(
                                          emoji: '👏',
                                          enabled: !_isAddingEmojiComment,
                                          onTap: () =>
                                              _addEmojiComment('👏', track.id),
                                        ),
                                        const SizedBox(width: 10),
                                        _QuickEmojiButton(
                                          emoji: '🥰',
                                          enabled: !_isAddingEmojiComment,
                                          onTap: () =>
                                              _addEmojiComment('🥰', track.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_emojiBurst != null)
                                    Positioned(
                                      right: 70,
                                      top: -18,
                                      child: _EmojiBurst(
                                        key: ValueKey(_emojiBurstId),
                                        emoji: _emojiBurst!,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RepeatModeButton(
                                  mode: state.repeatMode,
                                  iconSize: 30,
                                  onChanged: (mode) => context
                                      .read<PlayerCubit>()
                                      .setRepeatMode(mode),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  onPressed: () => context
                                      .read<PlayerCubit>()
                                      .playPrevious(),
                                ),
                                const SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () => context
                                      .read<PlayerCubit>()
                                      .togglePlayPause(),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF5500),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      state.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 34,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_next,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  onPressed: () =>
                                      context.read<PlayerCubit>().playNext(),
                                ),
                                const SizedBox(width: 54),
                              ],
                            ),
                            const SizedBox(height: 12),
                            PlayerActions(
                              onQueueTap: () => _showQueue(context),
                              onCommentsTap: () =>
                                  _openComments(context, track.id),
                              onLikesTap: () => _openEngagementList(
                                context,
                                trackId: track.id,
                                type: EngagementListType.likers,
                              ),
                              onRepostsTap: () => _openEngagementList(
                                context,
                                trackId: track.id,
                                type: EngagementListType.reposters,
                              ),
                              onLikeToggle: () => context
                                  .read<TrackInteractionCubit>()
                                  .toggleLike(track.id),
                              onRepostToggle: () => context
                                  .read<TrackInteractionCubit>()
                                  .toggleRepost(track.id),
                              onShareTap: () =>
                                  _openBroadcastSheet(context, track),
                              onMoreTap: () =>
                                  TrackOptionsSheet.show(context, track: track),
                              likesCount: interactionState.likesCount,
                              repostsCount: interactionState.repostsCount,
                              commentsCount: _commentsCount,
                              isLiked: interactionState.isLiked,
                              isReposted: interactionState.isReposted,
                              isSubmittingLike:
                                  interactionState.isSubmittingLike,
                              isSubmittingRepost:
                                  interactionState.isSubmittingRepost,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isBusy;
  final bool isActive;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.isBusy = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF5500) : Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? const Color(0xFFFFB27A) : Colors.white12,
          ),
        ),
        child: isBusy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _QuickEmojiButton extends StatefulWidget {
  final String emoji;
  final bool enabled;
  final VoidCallback onTap;

  const _QuickEmojiButton({
    required this.emoji,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_QuickEmojiButton> createState() => _QuickEmojiButtonState();
}

class _QuickEmojiButtonState extends State<_QuickEmojiButton> {
  bool _pressed = false;

  void _handleTap() {
    if (!widget.enabled) return;

    setState(() {
      _pressed = true;
    });
    widget.onTap();

    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      setState(() {
        _pressed = false;
      });
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
        child: Text(
          widget.emoji,
          style: TextStyle(
            fontSize: 20,
            color: widget.enabled ? null : Colors.white38,
          ),
        ),
      ),
    );
  }
}

class _EmojiBurst extends StatelessWidget {
  final String emoji;

  const _EmojiBurst({
    super.key,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: (1 - value).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -34 * value),
            child: Transform.scale(
              scale: 1 + value * 0.7,
              child: child,
            ),
          ),
        );
      },
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 30),
      ),
    );
  }
}

class _TimelineCommentBubble extends StatelessWidget {
  final CommentEntity comment;

  const _TimelineCommentBubble({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD166), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mode_comment_outlined,
            color: Color(0xFFFFD166),
            size: 15,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              comment.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
