// lib/features/search/presentation/widgets/search_results_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/search_entities.dart';
import '../bloc/search_cubit.dart';

class SearchResultsWidget extends StatefulWidget {
  final SearchState state;
  final ScrollController scrollController;

  const SearchResultsWidget({
    super.key,
    required this.state,
    required this.scrollController,
  });

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['All', 'Tracks', 'People', 'Playlists'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = switch (_tabController.index) {
      0 => SearchTab.all,
      1 => SearchTab.tracks,
      2 => SearchTab.people,
      _ => SearchTab.playlists,
    };
    context.read<SearchCubit>().onTabChanged(tab);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      children: [
        // ── Tab bar ──────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white12, width: 0.5),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Color(0xFFFF5500), width: 2.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: [
              const Tab(text: 'All'),
              Tab(
                text: state.tracks.isNotEmpty
                    ? 'Tracks (${state.tracks.length})'
                    : 'Tracks',
              ),
              Tab(
                text: state.users.isNotEmpty
                    ? 'People (${state.users.length})'
                    : 'People',
              ),
              Tab(
                text: state.playlists.isNotEmpty
                    ? 'Playlists (${state.playlists.length})'
                    : 'Playlists',
              ),
            ],
          ),
        ),

        // ── Tab views ────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AllTab(state: state, scrollController: widget.scrollController),
              _TracksTab(
                tracks: state.tracks,
                isLoadingMore: state.isLoadingMore,
                scrollController: widget.scrollController,
              ),
              _PeopleTab(users: state.users),
              _PlaylistsTab(playlists: state.playlists),
            ],
          ),
        ),
      ],
    );
  }
}

// ── All Tab ───────────────────────────────────────────────────────────────────

class _AllTab extends StatelessWidget {
  final SearchState state;
  final ScrollController scrollController;

  const _AllTab({required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Top Result
        if (state.tracks.isNotEmpty || state.users.isNotEmpty) ...[
          const _SectionTitle(title: 'Top Result'),
          if (state.users.isNotEmpty)
            _TopResultCard(user: state.users.first)
          else if (state.tracks.isNotEmpty)
            _TopResultCard(track: state.tracks.first),
        ],

        // Tracks (أول 3)
        if (state.tracks.isNotEmpty) ...[
          _SectionTitle(
            title: 'Tracks',
            onSeeAll: state.tracks.length > 3
                ? () => _jumpToTab(context, 1)
                : null,
          ),
          ...state.tracks.take(3).map((t) => _TrackTile(track: t)),
        ],

        // People (أول 3)
        if (state.users.isNotEmpty) ...[
          _SectionTitle(
            title: 'People',
            onSeeAll: state.users.length > 3
                ? () => _jumpToTab(context, 2)
                : null,
          ),
          ...state.users.take(3).map((u) => _UserTile(user: u)),
        ],

        // Playlists (أول 3)
        if (state.playlists.isNotEmpty) ...[
          _SectionTitle(
            title: 'Playlists',
            onSeeAll: state.playlists.length > 3
                ? () => _jumpToTab(context, 3)
                : null,
          ),
          ...state.playlists.take(3).map((p) => _PlaylistTile(playlist: p)),
        ],
      ],
    );
  }

  void _jumpToTab(BuildContext context, int index) {
    // نبعت event للـ parent عشان يغير الـ tab
    final cubit = context.read<SearchCubit>();
    final tab = switch (index) {
      1 => SearchTab.tracks,
      2 => SearchTab.people,
      _ => SearchTab.playlists,
    };
    cubit.onTabChanged(tab);
  }
}

// ── Top Result Card ───────────────────────────────────────────────────────────

class _TopResultCard extends StatelessWidget {
  final TrackEntity? track;
  final UserEntity? user;

  const _TopResultCard({this.track, this.user});

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      return _UserTopCard(user: user!);
    }
    return _TrackTopCard(track: track!);
  }
}

class _TrackTopCard extends StatelessWidget {
  final TrackEntity track;
  const _TrackTopCard({required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Artwork(url: track.artworkUrl, size: 64, radius: 8),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRACK',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  track.artistName,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.play_arrow,
                        color: Colors.white38, size: 13),
                    const SizedBox(width: 2),
                    Text(
                      _fmtCount(track.playbackCount),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      track.formattedDuration,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz, color: Colors.white38),
        ],
      ),
    );
  }
}

class _UserTopCard extends StatelessWidget {
  final UserEntity user;
  const _UserTopCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF2A2A2A),
            backgroundImage: user.avatarUrl.isNotEmpty
                ? NetworkImage(user.avatarUrl)
                : null,
            child: user.avatarUrl.isEmpty
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROFILE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFFFF5500), size: 15),
                    ],
                  ],
                ),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          _FollowButton(userId: user.id),
        ],
      ),
    );
  }
}

// ── Tracks Tab ────────────────────────────────────────────────────────────────

class _TracksTab extends StatelessWidget {
  final List<TrackEntity> tracks;
  final bool isLoadingMore;
  final ScrollController scrollController;

  const _TracksTab({
    required this.tracks,
    required this.isLoadingMore,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const _EmptyState(
        icon: Icons.music_off_rounded,
        message: 'No tracks found',
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: tracks.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == tracks.length) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF5500),
                ),
              ),
            ),
          );
        }
        return _TrackTile(track: tracks[i]);
      },
    );
  }
}

// ── People Tab ────────────────────────────────────────────────────────────────

class _PeopleTab extends StatelessWidget {
  final List<UserEntity> users;
  const _PeopleTab({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_off_rounded,
        message: 'No people found',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: users.length,
      itemBuilder: (_, i) => _UserTile(user: users[i]),
    );
  }
}

// ── Playlists Tab ─────────────────────────────────────────────────────────────

class _PlaylistsTab extends StatelessWidget {
  final List<PlaylistEntity> playlists;
  const _PlaylistsTab({required this.playlists});

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const _EmptyState(
        icon: Icons.playlist_remove_rounded,
        message: 'No playlists found',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: playlists.length,
      itemBuilder: (_, i) => _PlaylistTile(playlist: playlists[i]),
    );
  }
}

// ── Individual tiles ──────────────────────────────────────────────────────────

class _TrackTile extends StatelessWidget {
  final TrackEntity track;
  const _TrackTile({required this.track});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _Artwork(url: track.artworkUrl, size: 46, radius: 6),
      title: Text(
        track.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              track.artistName,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text(' · ',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          Text(
            track.formattedDuration,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          if (track.playbackCount > 0) ...[
            const Text(' · ',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            const Icon(Icons.play_arrow, color: Colors.white38, size: 11),
            Text(
              _fmtCount(track.playbackCount),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz, color: Colors.white38, size: 20),
        onPressed: () {
          // TODO: TrackOptionsSheet.show(context, track: ...)
        },
      ),
      onTap: () => context.push('/track/${track.id}'),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserEntity user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 23,
        backgroundColor: const Color(0xFF1C1C1C),
        backgroundImage: user.avatarUrl.isNotEmpty
            ? NetworkImage(user.avatarUrl)
            : null,
        child: user.avatarUrl.isEmpty
            ? Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.verified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified_rounded,
                color: Color(0xFFFF5500), size: 14),
          ],
        ],
      ),
      subtitle: Text(
        '@${user.username}',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: _FollowButton(userId: user.id),
      onTap: () => context.push('/profile/${user.username}'),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final PlaylistEntity playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _Artwork(
        url: playlist.artworkUrl,
        size: 46,
        radius: 6,
        fallbackIcon: Icons.queue_music_rounded,
      ),
      title: Text(
        playlist.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${playlist.ownerName} · ${playlist.trackCount} tracks',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing:
          const Icon(Icons.more_horiz, color: Colors.white38, size: 20),
      onTap: () => context.push('/playlist/${playlist.id}'),
    );
  }
}

// ── Follow Button ─────────────────────────────────────────────────────────────

class _FollowButton extends StatefulWidget {
  final String userId;
  const _FollowButton({required this.userId});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  // TODO: اربطه بالـ follow cubit لما يكون جاهز
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isFollowing = !_isFollowing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _isFollowing ? Colors.transparent : const Color(0xFFFF5500),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isFollowing
                ? Colors.white38
                : const Color(0xFFFF5500),
          ),
        ),
        child: Text(
          _isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: _isFollowing ? Colors.white38 : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionTitle({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFFFF5500),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _Artwork extends StatelessWidget {
  final String url;
  final double size;
  final double radius;
  final IconData fallbackIcon;

  const _Artwork({
    required this.url,
    required this.size,
    required this.radius,
    this.fallbackIcon = Icons.music_note_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  fallbackIcon,
                  color: Colors.white38,
                  size: size * 0.46,
                ),
              ),
            )
          : Icon(fallbackIcon, color: Colors.white38, size: size * 0.46),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white24, size: 52),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}