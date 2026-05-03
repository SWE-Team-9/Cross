import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/core/widgets/app_network_image.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';

/// The "Your Likes" card section shown at the top of the home feed.
/// Optimized for desktop/Windows with maximum width constraints and responsive grid layouts.
class YourLikesSection extends StatefulWidget {
  final String userId;
  final String handle;

  const YourLikesSection({
    super.key,
    required this.userId,
    required this.handle,
  });

  @override
  State<YourLikesSection> createState() => _YourLikesSectionState();
}

class _YourLikesSectionState extends State<YourLikesSection> {
  List<User> _followedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (GetIt.I.isRegistered<SocialRepo>()) {
        final repo = GetIt.I<SocialRepo>();
        final users = await repo.getFollowing(widget.userId, 1, limit: 4);
        if (mounted) {
          setState(() {
            _followedUsers = users;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFF5500),
            ),
          ),
        ),
      );
    }

    // Limit the maximum width on desktop so it doesn't stretch awkwardly
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100), // Standard desktop content boundary
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  const Text(
                    'Your likes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/profile/${widget.handle}'),
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'See All',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Card container ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive adaptation: If the screen is wide, use a 4-column grid.
                    // If it is narrow (mobile/tablet size), fallback to 2 columns.
                    final bool isWide = constraints.maxWidth > 650;
                    final int crossAxisCount = isWide ? 4 : 2;
                    final double aspectRatio = isWide ? 3.2 : 2.6;

                    return Column(
                      children: [
                        // Hero shuffle row
                        _YourLikesHeroCard(
                          onShuffle: () => context.push('/profile/${widget.handle}'),
                        ),

                        // Grid layout
                        if (_followedUsers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _followedUsers.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: aspectRatio,
                              ),
                              itemBuilder: (context, index) {
                                final user = _followedUsers[index];
                                final avatarUrl = PlatformUrlUtils.normalizeBackendUrl(
                                  user.avatarUrl,
                                );
                                return _LikesArtistCell(
                                  imageUrl: avatarUrl,
                                  label: user.username.isNotEmpty ? user.username : '?',
                                  onTap: user.username.trim().isNotEmpty
                                      ? () => ProfileRoutes.goToProfile(
                                            context,
                                            user.username.trim(),
                                          )
                                      : null,
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────
class _YourLikesHeroCard extends StatelessWidget {
  final VoidCallback onShuffle;
  const _YourLikesHeroCard({required this.onShuffle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF3D0000), Color(0xFF1A0000)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          // Heart with ambient glow
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black26,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5500).withValues(alpha: 0.45),
                  blurRadius: 18, 
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF5500),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your likes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          // Shuffle button
          GestureDetector(
            onTap: onShuffle,
            child: const MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    Icons.shuffle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Single artist chip cell ───────────────────────────────────────────────────
class _LikesArtistCell extends StatelessWidget {
  final String? imageUrl;
  final String label;
  final VoidCallback? onTap;

  const _LikesArtistCell({
    required this.imageUrl,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF282828), width: 0.5),
          ),
          child: Row(
            children: [
              // Circular avatar with explicit bounds
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: imageUrl != null
                        ? AppNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_) => _fallback(),
                          )
                        : _fallback(),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFF2A2A2A),
        child: const Icon(Icons.person, color: Colors.white38, size: 16),
      );
}