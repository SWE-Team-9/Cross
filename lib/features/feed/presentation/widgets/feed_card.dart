// ─────────────────────────────────────────────────────────────────────────────
//  feed_card.dart  —  Feed Track Card
//  Matches SoundCloud's card layout:
//    • Actor row (avatar + name + verified + action + time)
//    • Large artwork with gradient overlay
//    • Right-side action buttons (like, comment, add)
//    • Bottom overlay (title + duration + artist avatar)
//    • Play circle button
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../domain/entities/feed_item.dart';
import '../../data/dto/feed_item_model.dart' show formatCount;

class FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onLike;
  final VoidCallback onRepost;
  final VoidCallback onPlay;
  final VoidCallback? onComment;
  final VoidCallback? onAdd;

  const FeedCard({
    super.key,
    required this.item,
    required this.onLike,
    required this.onRepost,
    required this.onPlay,
    this.onComment,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActorRow(item: item),
          const SizedBox(height: 8),
          _TrackCard(
              item: item,
              onLike: onLike,
              onRepost: onRepost,
              onPlay: onPlay,
              onComment: onComment,
              onAdd: onAdd),
          const Divider(color: Color(0xFF111111), thickness: 1, height: 1),
        ],
      ),
    );
  }
}

// ─── Actor Row ────────────────────────────────────────────────────────────────

class _ActorRow extends StatelessWidget {
  final FeedItem item;
  const _ActorRow({required this.item});

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  actor.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actor.verified) ...[
                const SizedBox(width: 3),
                const _VerifiedBadge(),
              ],
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${item.action}  ·  ${item.timeAgo}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.more_vert, color: Color(0xFF666666), size: 18),
      ],
    );
  }
}

// ─── Track Card ───────────────────────────────────────────────────────────────

class _TrackCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onLike;
  final VoidCallback onRepost;
  final VoidCallback onPlay;
  final VoidCallback? onComment;
  final VoidCallback? onAdd;

  const _TrackCard({
    required this.item,
    required this.onLike,
    required this.onRepost,
    required this.onPlay,
    this.onComment,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final track = item.track;
    return GestureDetector(
      onTap: onPlay,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1 / 0.85,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Artwork ──────────────────────────────────────────────────
              _Artwork(track: track),

              // ── Gradient overlay ─────────────────────────────────────────
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.4, 0.7, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Color(0x66000000),
                      Color(0xE6000000),
                    ],
                  ),
                ),
              ),

              // ── Mute button (top right) ───────────────────────────────────
              Positioned(
                top: 10,
                right: 10,
                child: _IconBox(icon: Icons.volume_off, onTap: () {}),
              ),

              // ── Right action buttons ──────────────────────────────────────
              Positioned(
                right: 10,
                bottom: 52,
                child: Column(
                  children: [
                    _SideAction(
                      icon: Icons.favorite,
                      count: formatCount(track.stats.likesCount),
                      active: track.userState.liked,
                      activeColor: const Color(0xFFFF5500),
                      onTap: onLike,
                    ),
                    const SizedBox(height: 8),
                    _SideAction(
                      icon: Icons.comment_outlined,
                      count: formatCount(track.stats.commentsCount),
                      onTap: onComment ?? () {},
                    ),
                    const SizedBox(height: 8),
                    _SideAction(
                      icon: Icons.add_box_outlined,
                      label: 'Add',
                      onTap: onAdd ?? () {},
                    ),
                  ],
                ),
              ),

              // ── Bottom info ───────────────────────────────────────────────
              Positioned(
                left: 12,
                bottom: 12,
                right: 64,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Avatar(
                      displayName: item.actor.displayName,
                      avatarUrl: item.actor.avatarUrl,
                      size: 30,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${track.title}  ·  ${track.formattedDuration}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 4)],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.actor.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFCCCCCC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Play button ───────────────────────────────────────────────
              Positioned(
                right: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: onPlay,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 2),
                      color: Colors.black45,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Artwork ─────────────────────────────────────────────────────────────────

class _Artwork extends StatelessWidget {
  final FeedTrack track;
  const _Artwork({required this.track});

  // Deterministic color from trackId
  Color _fallbackColor() {
    const colors = [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
      Color(0xFF1B1B2F),
      Color(0xFF2D132C),
      Color(0xFF1B262C),
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
        errorBuilder: (_, __, ___) => _fallbackBox(),
      );
    }
    return _fallbackBox();
  }

  Widget _fallbackBox() {
    return Container(color: _fallbackColor());
  }
}

// ─── Side Action Button ───────────────────────────────────────────────────────

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
    final iconColor = active ? activeColor : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: active ? activeColor.withValues(alpha: 0.8) : Colors.white30,
                width: 1.5,
              ),
              color: Colors.black45,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          if (count != null) ...[
            const SizedBox(height: 2),
            Text(count!,
                style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
          ],
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(label!,
                style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
          ],
        ],
      ),
    );
  }
}

// ─── Icon Box ────────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBox({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
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
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _color()),
      alignment: Alignment.center,
      child: Text(
        displayName.length >= 2
            ? displayName.substring(0, 2).toUpperCase()
            : displayName.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Verified Badge ───────────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 7,
      backgroundColor: Color(0xFF1DA0F2),
      child: Icon(Icons.check, size: 8, color: Colors.white),
    );
  }
}
