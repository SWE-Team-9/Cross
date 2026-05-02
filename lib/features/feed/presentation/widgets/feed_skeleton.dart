// ─────────────────────────────────────────────────────────────────────────────
//  feed_skeleton.dart  —  Loading Skeleton Widget
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class FeedSkeleton extends StatefulWidget {
  const FeedSkeleton({super.key});

  @override
  State<FeedSkeleton> createState() => _FeedSkeletonState();
}

class _FeedSkeletonState extends State<FeedSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (_, __) => const _SkeletonCard(),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actor row
          Row(children: [
            _box(32, 32, circular: true),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(12, 120),
              const SizedBox(height: 4),
              _box(10, 80),
            ]),
          ]),
          const SizedBox(height: 10),
          // Artwork
          _box(double.infinity, 260, radius: 12),
          const SizedBox(height: 10),
          // Divider
          _box(double.infinity, 1),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _box(double w, double h, {bool circular = false, double radius = 6}) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: circular
            ? BorderRadius.circular(h / 2)
            : BorderRadius.circular(radius),
      ),
    );
  }
}
