import 'package:flutter/material.dart';

class PlayerActions extends StatefulWidget {
  final VoidCallback? onQueueTap;

  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onPlaylistTap;
  final VoidCallback? onMoreTap;

  final bool isLiked;
  final bool isSubmittingLike;
  final int likesCount;
  final int commentsCount;

  const PlayerActions({
    super.key, this.onQueueTap,
    this.onLikeTap,
    this.onCommentTap,
    this.onShareTap,
    this.onPlaylistTap,
    this.onMoreTap,
    this.isLiked = false,
    this.isSubmittingLike = false,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  @override
  State<PlayerActions> createState() => _PlayerActionsState();
}

class _PlayerActionsState extends State<PlayerActions> {
  bool _liked = false;
  int _likes = 203;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AnimatedActionButton(
              onTap: isSubmittingLike ? null : onLikeTap,
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              label: '$likesCount',
              active: isLiked,
              activeColor: Colors.red,
            ),
            _AnimatedActionButton(
              onTap: onCommentTap,
              icon: Icons.chat_bubble_outline,
              label: '$commentsCount',
              active: false,
              activeColor: Colors.white70,
            ),
            IconButton(
              onPressed: onShareTap,
              icon: const Icon(Icons.share, color: Colors.white70),
            ),
            IconButton(
              onPressed: onPlaylistTap,
              icon: const Icon(Icons.playlist_play, color: Colors.white70),
            ),
            IconButton(
              onPressed: onMoreTap,
              icon: const Icon(Icons.more_vert, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;

  const _AnimatedActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : Colors.white70;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            AnimatedScale(
              scale: active ? 1.12 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: TextStyle(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
              child: Text(label),
            ),
          ],
        ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Like
          GestureDetector(
            onTap: () {
              setState(() {
                _liked = !_liked;
                _likes += _liked ? 1 : -1;
              });
            },
            child: Row(
              children: [
                Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? const Color(0xFFFF5500) : Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 5),
                Text(
                  '$_likes',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Comment
          GestureDetector(
            onTap: () {},
            child: Row(
              children: const [
                Icon(Icons.chat_bubble_outline,
                    color: Colors.white70, size: 20),
                SizedBox(width: 5),
                Text(
                  '7',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Share
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.share_outlined,
                color: Colors.white70, size: 22),
          ),

          // Queue
          GestureDetector(
            onTap: widget.onQueueTap,
            child:
                const Icon(Icons.queue_music, color: Colors.white70, size: 22),
          ),

          // More
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.more_vert, color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }
}