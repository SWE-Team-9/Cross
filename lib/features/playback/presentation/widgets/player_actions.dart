import 'package:flutter/material.dart';

class PlayerActions extends StatelessWidget {
  final VoidCallback? onQueueTap;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onLikesTap;
  final VoidCallback? onRepostsTap;
  final VoidCallback? onRepostToggle;
  final VoidCallback? onShareTap;
  final VoidCallback? onPlaylistTap;
  final VoidCallback? onMoreTap;

  final bool isLiked;
  final bool isReposted;
  final bool isSubmittingLike;
  final bool isSubmittingRepost;
  final int likesCount;
  final int repostsCount;
  final int commentsCount;

  const PlayerActions({
    super.key,
    this.onQueueTap,
    this.onLikeToggle,
    this.onCommentsTap,
    this.onLikesTap,
    this.onRepostsTap,
    this.onRepostToggle,
    this.onShareTap,
    this.onPlaylistTap,
    this.onMoreTap,
    this.isLiked = false,
    this.isReposted = false,
    this.isSubmittingLike = false,
    this.isSubmittingRepost = false,
    this.likesCount = 0,
    this.repostsCount = 0,
    this.commentsCount = 0,
  });

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
              onTap: isSubmittingLike ? null : onLikeToggle,
              onLabelTap: onLikesTap,
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              label: '$likesCount',
              active: isLiked,
              activeColor: const Color(0xFFFF5500),
            ),
            _AnimatedActionButton(
              onTap: onCommentsTap,
              onLabelTap: onCommentsTap,
              icon: Icons.chat_bubble_outline,
              label: '$commentsCount',
              active: false,
              activeColor: Colors.white70,
            ),
            _AnimatedActionButton(
              onTap: isSubmittingRepost ? null : onRepostToggle,
              onLabelTap: onRepostsTap,
              icon: Icons.repeat,
              label: '$repostsCount',
              active: isReposted,
              activeColor: const Color(0xFFFF5500),
            ),
            IconButton(
              onPressed: onShareTap,
              icon: const Icon(Icons.share, color: Colors.white70),
            ),
            IconButton(
              onPressed: onQueueTap,
              icon: const Icon(Icons.queue_music, color: Colors.white70),
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
  final VoidCallback? onLabelTap;
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;

  const _AnimatedActionButton({
    required this.onTap,
    required this.onLabelTap,
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : Colors.white70;

    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: AnimatedScale(
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
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onLabelTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: TextStyle(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
              child: Text(label),
            ),
          ),
        ),
      ],
    );
  }
}
