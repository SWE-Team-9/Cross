import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/core/widgets/app_network_image.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/home/domain/entities/home_content.dart';
import 'package:soundcloud_clone/features/home/presentation/bloc/home_cubit.dart';
import 'package:soundcloud_clone/features/home/presentation/bloc/home_state.dart';
import 'package:soundcloud_clone/features/home/presentation/widgets/genre_chips.dart';
import 'package:soundcloud_clone/features/home/presentation/widgets/your_likes_section.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/unread_count_cubit.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/unread_count_state.dart';
import 'package:soundcloud_clone/features/messaging/presentation/routes/messaging_routes.dart';
import 'package:soundcloud_clone/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';
import 'package:soundcloud_clone/features/premium/presentation/widgets/premium_aware_ad_banner.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/features/home/presentation/widgets/trending_tracks_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>(
          create: (_) => GetIt.I<HomeCubit>()..load(),
        ),
      ],
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go('/welcome');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, authState) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: RefreshIndicator(
                color: const Color(0xFFFF5500),
                backgroundColor: const Color(0xFF161616),
                onRefresh: context.read<HomeCubit>().refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HomeTopBar(authState: authState),
                    ),
                    BlocBuilder<HomeCubit, HomeState>(
                      builder: (context, state) {
                        if (state.isLoading && !state.hasContent) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _HomeLoadingView(),
                          );
                        }

                        if (state.errorMessage != null && !state.hasContent) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _HomeErrorView(
                              message: state.errorMessage!,
                              onRetry: context.read<HomeCubit>().load,
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildListDelegate([
                            const PremiumAwareAdBanner(
                              title: 'Ad-free listening is one tap away',
                              subtitle:
                                  'Go Premium to remove sponsored cards, save music offline, and unlock more uploads.',
                              actionLabel: 'Upgrade',
                            ),

                            // ── YOUR LIKES ──────────────────────────────────
                            if (authState is AuthAuthenticated)
                              YourLikesSection(
                                userId: authState.user.id,
                                handle: authState.user.handle,
                              ),

                            // ── TOP PLAYLISTS ───────────────────────────────
                            if (state.topPlaylists.isNotEmpty) ...[
                              const _SectionHeader(
                                title: 'Top playlists',
                                subtitle: 'Switch by your favorite genres',
                              ),
                              GenreChips(
                                genres: state.playlistGenreOptions,
                                selected: state.selectedPlaylistGenre,
                                onSelect: context
                                    .read<HomeCubit>()
                                    .selectPlaylistGenre,
                              ),
                              _TopPlaylists(
                                playlists: state.selectedTopPlaylists,
                                selectedGenre: state.selectedPlaylistGenre,
                              ),
                            ],

                            // ── TRENDING NOW ────────────────────────────────
                            const _SectionHeader(
                              title: 'Trending now',
                              subtitle: 'Switch by your favorite genres',
                            ),
                            GenreChips(
                              genres: state.favoriteGenres,
                              selected: state.selectedGenre,
                              onSelect:
                                  context.read<HomeCubit>().selectGenre,
                            ),
                            TrendingTracksSection(
                              loading: state.isLoadingTrending,
                              error: state.trendingErrorMessage,
                              tracks: state.trendingTracks,
                              selectedGenre: state.selectedGenre,
                            ),

                            const SizedBox(height: 96),
                          ]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── TOP BAR ───────────────────────────────────────────────────────────────────
class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.authState});
  final AuthState authState;

  String get _currentHandle =>
      authState is AuthAuthenticated
          ? (authState as AuthAuthenticated).user.handle
          : '';

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Log out of Iqa3?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5500),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.read<AuthCubit>().logout();
                },
                child: const Text(
                  'Log out',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToProfile(BuildContext context) {
    if (_currentHandle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view profile')),
      );
      return;
    }
    ProfileRoutes.goToProfile(context, _currentHandle);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 6),
      child: Row(
        children: [
          const Text(
            'Home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          const _SubscriptionBadge(),
          const Spacer(),
          if (authState is AuthAuthenticated)
            _HomeIconButton(
              icon: Icons.logout_rounded,
              onTap: () => _showLogoutSheet(context),
            ),
          _AvatarButton(
            authState: authState,
            onTap: () => _goToProfile(context),
          ),
          _NotificationButton(
            onTap: () => context.push('/notifications'),
          ),
          BlocBuilder<UnreadCountCubit, UnreadCountState>(
            builder: (context, unreadState) => _BadgeIconButton(
              icon: Icons.forum_outlined,
              count: unreadState.count,
              onTap: () => MessagingRoutes.goToInbox(context),
            ),
          ),
          _HomeIconButton(
            icon: Icons.upload_outlined,
            onTap: () => context.push('/upload-picker'),
          ),
        ],
      ),
    );
  }
}

// ── SUBSCRIPTION BADGE ────────────────────────────────────────────────────────
class _SubscriptionBadge extends StatelessWidget {
  const _SubscriptionBadge();

  SubscriptionCubit? _cubitOf(BuildContext context) {
    try {
      return context.read<SubscriptionCubit>();
    } catch (_) {
      return GetIt.I.isRegistered<SubscriptionCubit>()
          ? GetIt.I<SubscriptionCubit>()
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubitOf(context);
    if (cubit == null) {
      return _badge(context, planCode: 'FREE', isPremium: false);
    }
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      bloc: cubit,
      builder: (context, state) => _badge(
        context,
        planCode: state.subscription.normalizedPlanCode,
        isPremium: state.subscription.isPremium,
      ),
    );
  }

  Widget _badge(
    BuildContext context, {
    required String planCode,
    required bool isPremium,
  }) {
    final n = planCode.trim().toUpperCase();
    final color = switch (n) {
      'GO_PLUS' => const Color(0xFF4B9EFF),
      'PRO'     => const Color(0xFF1DB954),
      _         => const Color(0xFFFF5500),
    };
    final label = switch (n) {
      'GO_PLUS' => 'GO+',
      'PRO'     => 'PRO',
      _         => 'GET PRO',
    };

    return GestureDetector(
      onTap: isPremium ? null : () => context.go('/upgrade'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// ── AVATAR BUTTON ─────────────────────────────────────────────────────────────
class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.authState, required this.onTap});
  final AuthState authState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String? avatarUrl;
    String fallback = '?';

    if (authState is AuthAuthenticated) {
      final user = (authState as AuthAuthenticated).user;
      avatarUrl = user.avatarUrl;
      fallback = user.handle.isNotEmpty
          ? user.handle.substring(0, 1).toUpperCase()
          : '?';
    }

    final url = PlatformUrlUtils.normalizeBackendUrl(avatarUrl);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFFFF5500),
          backgroundImage: url == null ? null : NetworkImage(url),
          child: url == null
              ? Text(fallback,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ))
              : null,
        ),
      ),
    );
  }
}

// ── NOTIFICATION BUTTON ───────────────────────────────────────────────────────
class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(6),
        child: NotificationBadge(
          child: Icon(
            Icons.notifications_outlined,
            color: Colors.white70,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── PLAIN ICON BUTTON ─────────────────────────────────────────────────────────
class _HomeIconButton extends StatelessWidget {
  const _HomeIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }
}

// ── BADGE ICON BUTTON ─────────────────────────────────────────────────────────
class _BadgeIconButton extends StatelessWidget {
  const _BadgeIconButton({
    required this.icon,
    required this.count,
    required this.onTap,
  });
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            if (count > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5500),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── SECTION HEADER ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

// ── TOP PLAYLISTS ─────────────────────────────────────────────────────────────
class _TopPlaylists extends StatelessWidget {
  const _TopPlaylists({
    required this.playlists,
    required this.selectedGenre,
  });
  final List<PlaylistEntity> playlists;
  final String selectedGenre;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
        child: Text(
          selectedGenre == HomeTopPlaylists.overall
              ? 'No top playlists available yet'
              : 'No playlists found for this genre',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    final visible = playlists.take(10).toList(growable: false);

    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _TopPlaylistCard(playlist: visible[index], rank: index + 1),
      ),
    );
  }
}

class _TopPlaylistCard extends StatelessWidget {
  const _TopPlaylistCard({required this.playlist, required this.rank});
  final PlaylistEntity playlist;
  final int rank;

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl =
        PlatformUrlUtils.normalizeBackendUrl(playlist.coverImageUrl);
    final ownerName = playlist.owner?.displayName.trim() ?? '';
    final genre = playlist.genre?.trim();
    final subtitle = <String>[
      if (ownerName.isNotEmpty) ownerName,
      if (genre != null && genre.isNotEmpty) genre,
      '${playlist.tracksCount} tracks',
    ].join(' - ');

    return GestureDetector(
      onTap: () => context.push('/playlist/${playlist.playlistId}'),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 150,
                    height: 126,
                    color: const Color(0xFF1E1E1E),
                    child: coverUrl == null
                        ? const Icon(Icons.queue_music_rounded,
                            color: Colors.white38, size: 36)
                        : AppNetworkImage(
                            imageUrl: coverUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_) => const Icon(
                                Icons.queue_music_rounded,
                                color: Colors.white38,
                                size: 36),
                          ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(playlist.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF999999), fontSize: 11)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.favorite_rounded,
                  color: Color(0xFFFF5500), size: 13),
              const SizedBox(width: 3),
              Text(_fmt(playlist.likesCount),
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  )),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── LOADING / ERROR ───────────────────────────────────────────────────────────
class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5500)),
      );
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: Colors.white38, size: 48),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFFF5500),
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}