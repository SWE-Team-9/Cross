// coverage:ignore-file
// ─────────────────────────────────────────────────────────────────────────────
//  feed_card.dart
//
//  Right side (top→bottom): volume | like+count | comment+count | add
//  Top right: ⋮ (3 dots vertical)
//  Play button: bottom right with orange progress ring
//  All tracks playable via PlayerCubit.playFromContext (resolves URL lazily)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_options_sheet.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/pages/track_comments_page.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/add_to_playlist_sheet.dart';

import '../../data/dto/feed_item_model.dart' show formatCount;
import '../../domain/entities/feed_item.dart';

// ─────────────────────────────────────────────────────────────────────────────

class FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onLike;
  final VoidCallback onRepost;
  final VoidCallback onPlay;

  const FeedCard({
    super.key,
    required this.item,
    required this.onLike,
    required this.onRepost,
    required this.onPlay,
  });

  Track _toTrack() => Track(
        id: item.track.trackId,
        title: item.track.title,
        artist: item.track.artist.displayName,
        audioUrl: item.track.audioUrl ?? '',
        artworkUrl: item.track.coverArtUrl,
        handle: item.track.artist.handle,
        artistId: item.track.artist.userId,
        likesCount: item.track.stats.likesCount,
        repostsCount: item.track.stats.repostsCount,
        durationMs: item.track.durationMs,
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Feed response already has liked/reposted/counts — zero network calls
      create: (_) => getIt<TrackInteractionCubit>()
        ..loadWithKnownState(
          trackId: item.track.trackId,
          likesCount: item.track.stats.likesCount,
          repostsCount: item.track.stats.repostsCount,
          isLiked: item.track.userState.liked,
          isReposted: item.track.userState.reposted,
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: _ActorRow(item: item, toTrack: _toTrack),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _TrackCard(item: item, onPlay: onPlay, toTrack: _toTrack),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF111111), thickness: 1, height: 1),
        ],
      ),
    );
  }
}

// ─── Actor Row ────────────────────────────────────────────────────────────────

class _ActorRow extends StatelessWidget {
  final FeedItem item;
  final Track Function() toTrack;
  const _ActorRow({required this.item, required this.toTrack});

  String _actionLabel(String action) {
    switch (action.toUpperCase()) {
      case 'REPOST':
        return 'reposted a track';
      default:
        return 'posted a track';
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = item.actor;
    return Row(
      children: [
        _Avatar(
            displayName: actor.displayName,
            avatarUrl: actor.avatarUrl,
            size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(fontSize: 13),
              children: [
                TextSpan(
                  text: actor.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white),
                ),
                if (actor.verified)
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: _VerifiedBadge(),
                    ),
                  ),
                TextSpan(
                  text: '  ${_actionLabel(item.action)}  ·  ${item.timeAgo}',
                  style: const TextStyle(color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        // ⋮ vertical 3-dot menu
        GestureDetector(
          onTap: () => TrackOptionsSheet.show(context, track: toTrack()),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.more_vert, color: Color(0xFF666666), size: 20),
          ),
        ),
      ],
    );
  }
}

// ─── Track Card ───────────────────────────────────────────────────────────────

class _TrackCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onPlay;
  final Track Function() toTrack;

  const _TrackCard(
      {required this.item, required this.onPlay, required this.toTrack});

  void _openComments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<CommentsCubit>()..load(item.track.trackId),
          child: TrackCommentsPage(trackId: item.track.trackId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = item.track;

    return BlocBuilder<PlayerCubit, PlayerUIState>(
      builder: (context, playerState) {
        final isThisTrack = playerState.currentTrack?.id == track.trackId;
        final isPlaying = isThisTrack && playerState.isPlaying;

        final duration = playerState.duration;
        final double progress = isThisTrack &&
                duration != null &&
                duration.inMilliseconds > 0
            ? (playerState.position.inMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

        return AspectRatio(
          aspectRatio: 1 / 0.92,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Artwork ────────────────────────────────────────────────
              GestureDetector(
                onTap: () => _handleTap(context, isThisTrack),
                child: _Artwork(track: track),
              ),

              // ── Gradient ───────────────────────────────────────────────
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.35, 0.60, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.42),
                        Colors.black.withValues(alpha: 0.93),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Right action column ──────────────────────────────────────
              // Aligned with play button, moved slightly more right
              Positioned(
                right: 6,
                bottom: 68,
                width: 58,
                child:
                    BlocBuilder<TrackInteractionCubit, TrackInteractionState>(
                  builder: (context, inter) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Volume / Mute ─────────────────────────────────
                        GestureDetector(
                          onTap: () =>
                              _handleVolumeTap(context, isThisTrack, isPlaying),
                          child: Icon(
                            isPlaying
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ── Like ─────────────────────────────────────────
                        _SideAction(
                          icon: inter.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          count: formatCount(inter.likesCount),
                          active: inter.isLiked,
                          activeColor: const Color(0xFFFF5500),
                          onTap: () => context
                              .read<TrackInteractionCubit>()
                              .toggleLike(track.trackId),
                        ),
                        const SizedBox(height: 20),
                        // ── Comment ───────────────────────────────────────
                        _SideAction(
                          icon: Icons.chat_bubble_outline_rounded,
                          count: formatCount(track.stats.commentsCount),
                          onTap: () => _openComments(context),
                        ),
                        const SizedBox(height: 20),
                        // ── Add to queue ──────────────────────────────────
                        // ✅ بعد
                        _SideAction(
                          icon: Icons.playlist_add_rounded,
                          label: 'Add',
                          onTap: () => AddToPlaylistSheet.show(context,
                              track: toTrack()),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Bottom info ────────────────────────────────────────────
              Positioned(
                left: 12,
                bottom: 14,
                right: 62,
                child: GestureDetector(
                  onTap: () => _handleTap(context, isThisTrack),
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
                          shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _Avatar(
                            displayName: item.actor.displayName,
                            avatarUrl: item.actor.avatarUrl,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              item.actor.displayName,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFFCCCCCC)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (track.formattedDuration != '0:00') ...[
                            const Text('  ·  ',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF888888))),
                            Text(
                              track.formattedDuration,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF888888)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Play/Pause + orange progress ring ──────────────────────
              Positioned(
                right: 10,
                bottom: 10,
                child: GestureDetector(
                  onTap: () => _handleTap(context, isThisTrack),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(50, 50),
                          painter: _RingPainter(
                            progress: progress,
                            ringColor: const Color(0xFFFF5500),
                            trackColor: Colors.white24,
                            strokeWidth: 2.5,
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPlaying
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.black.withValues(alpha: 0.55),
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _handleTap(BuildContext context, bool isThisTrack) {
    if (isThisTrack) {
      context.read<PlayerCubit>().togglePlayPause();
    } else {
      onPlay();
    }
  }

  Future<void> _handleVolumeTap(
      BuildContext context, bool isThisTrack, bool isPlaying) async {
    final playerCubit = context.read<PlayerCubit>();
    if (!isThisTrack) {
      // Start playing this track
      onPlay();
    } else if (isPlaying) {
      await playerCubit.pause();
    } else {
      await playerCubit.resume();
    }
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor;
}

// ─── Artwork ─────────────────────────────────────────────────────────────────

class _Artwork extends StatelessWidget {
  final FeedTrack track;
  const _Artwork({required this.track});

  Color _fallbackColor() {
    const colors = [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
      Color(0xFF1B1B2F),
      Color(0xFF2D132C),
      Color(0xFF1B262C),
      Color(0xFF0D2137),
      Color(0xFF1C2833),
    ];
    final idx =
        track.trackId.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    if (track.coverArtUrl != null) {
      return Image.network(
        track.coverArtUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(color: _fallbackColor()),
      );
    }
    return Container(color: _fallbackColor());
  }
}

// ─── Side Action ─────────────────────────────────────────────────────────────

class _SideAction extends StatelessWidget {
  final IconData icon;
  final String? count;
  final String? label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _SideAction({
    required this.icon,
    this.count,
    this.label,
    this.active = false,
    this.activeColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : Colors.white.withValues(alpha: 0.88);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          if (count != null) ...[
            const SizedBox(height: 3),
            Text(
              count!,
              style: TextStyle(
                fontSize: 11,
                color:
                    active ? activeColor : Colors.white.withValues(alpha: 0.75),
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ] else if (label == null) ...[
            // Always show "0" when no count and no label
            const SizedBox(height: 3),
            Text(
              '0',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
          if (label != null) ...[
            const SizedBox(height: 3),
            Text(label!,
                style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
          ],
        ],
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final double size;
  const _Avatar(
      {required this.displayName, this.avatarUrl, required this.size});

  Color _color() {
    const colors = [
      Color(0xFFFF5500),
      Color(0xFF1DA0F2),
      Color(0xFF1DB954),
      Color(0xFF9B59B6),
      Color(0xFFF39C12),
      Color(0xFFE74C3C),
    ];
    final idx = displayName.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return ClipOval(
        child: Image.network(avatarUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initials()),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final letters = displayName.length >= 2
        ? displayName.substring(0, 2).toUpperCase()
        : displayName.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _color()),
      alignment: Alignment.center,
      child: Text(letters,
          style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }
}

// ─── Verified Badge ───────────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();
  @override
  Widget build(BuildContext context) => const CircleAvatar(
        radius: 7,
        backgroundColor: Color(0xFF1DA0F2),
        child: Icon(Icons.check, size: 8, color: Colors.white),
      );
}
