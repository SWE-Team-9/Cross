// ============================================================================
// T2.3 — Profile Screen
// File: lib/features/profile/presentation/pages/profile_page.dart
//
// WHAT CHANGES WHEN YOU INTEGRATE WITH BACKEND:
// Search for "// TODO(backend)" comments — every one of them is a swap point.
// Summary of all swaps at the bottom of this file.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/profile_routes.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {

  // TODO(backend): Replace with real auth service check
  // e.g. final isOwnProfile = getIt<AuthCubit>().state.user?.id == widget.userId;
  bool get isOwnProfile => widget.userId == 'user_eyad';

  // TODO(backend): Replace with ProfileCubit state
  // These will come from: ProfileCubit → ProfileRepository → ProfileRemoteDataSource
  late final _MockProfileData _profile;

  // Tab controller for Likes / Tracks / Playlists / Reposts
  late final TabController _tabController;

  // TODO(backend): Replace with follow state from SocialCubit (T2.9)
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // TODO(backend): Replace with:
    // context.read<ProfileCubit>().loadProfile(widget.userId);
    // Then read profile from BlocBuilder<ProfileCubit, ProfileState>
    _profile = _MockProfileData.forUser(widget.userId, isOwnProfile);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFollowTap() {
    setState(() => _isFollowing = !_isFollowing);
    // TODO(backend): Replace with:
    // if (_isFollowing) {
    //   context.read<SocialCubit>().follow(widget.userId);
    // } else {
    //   context.read<SocialCubit>().unfollow(widget.userId);
    // }
    // SocialCubit handles optimistic updates + rollback on failure (T2.9)
  }

  @override
  Widget build(BuildContext context) {
    // TODO(backend): Wrap with BlocBuilder<ProfileCubit, ProfileState>
    // and handle ProfileLoading / ProfileError states here
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(isOwnProfile: isOwnProfile),
                  _AvatarSection(avatarUrl: _profile.avatarUrl),
                  _UserInfo(
                    name: _profile.name,
                    followersCount: _profile.followersCount,
                    followingCount: _profile.followingCount,
                    tracksCount: _profile.tracksCount,
                    bio: _profile.bio,
                    location: _profile.location,
                    isOwnProfile: isOwnProfile,
                  ),
                  _ActionRow(
                    isOwnProfile: isOwnProfile,
                    isFollowing: _isFollowing,
                    onEditTap: () => ProfileRoutes.goToEditProfile(context),
                    onFollowTap: _onFollowTap,
                    onShuffleTap: () {
                      // TODO(backend): Trigger shuffle play from PlaybackCubit (Sprint 3)
                    },
                    onPlayTap: () {
                      // TODO(backend): Trigger play all from PlaybackCubit (Sprint 3)
                    },
                  ),
                  _ProfileTabBar(controller: _tabController),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _LikesTab(tracks: _profile.likedTracks),
              _TracksTab(tracks: _profile.ownedTracks),
              _PlaylistsTab(playlists: _profile.playlists),
              _RepostsTab(tracks: _profile.repostedTracks),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isOwnProfile;
  const _TopBar({required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _CircleIconBtn(
            icon: Icons.arrow_back,
            onTap: () => context.pop(),
          ),
          Row(
            children: [
              _CircleIconBtn(icon: Icons.cast, onTap: () {}),
              const SizedBox(width: 8),
              _CircleIconBtn(
                icon: Icons.more_vert,
                onTap: () {
                  // TODO(backend): Show block/report options for other users
                  // For own profile: show settings
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final String? avatarUrl;
  const _AvatarSection({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: const Color(0xFF5B7BBB),
        // TODO(backend): Replace with CachedNetworkImage(url: avatarUrl)
        // when avatarUrl is non-null. Use package:cached_network_image.
        child: avatarUrl == null
            ? const Icon(Icons.person, size: 56, color: Color(0xFF7B9FD4))
            : null,
        // backgroundImage: avatarUrl != null
        //     ? CachedNetworkImageProvider(avatarUrl!)
        //     : null,
      ),
    );
  }
}

// ── User info ─────────────────────────────────────────────────────────────────

class _UserInfo extends StatelessWidget {
  final String name;
  final int followersCount;
  final int followingCount;
  final int tracksCount;
  final String? bio;
  final String? location;
  final bool isOwnProfile;

  const _UserInfo({
    required this.name,
    required this.followersCount,
    required this.followingCount,
    required this.tracksCount,
    required this.bio,
    required this.location,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            name,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),

          // Followers · Following · (Tracks for other users)
          Row(
            children: [
              GestureDetector(
                // TODO(backend): Navigate to followers list (T2.10)
                onTap: () {},
                child: Text(
                  '${_formatCount(followersCount)} Followers',
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                ),
              ),
              const Text(' · ',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
              GestureDetector(
                // TODO(backend): Navigate to following list (T2.10)
                onTap: () {},
                child: Text(
                  '${_formatCount(followingCount)} Following',
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                ),
              ),
              if (!isOwnProfile && tracksCount > 0) ...[
                const Text(' · ',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                Text(
                  '$tracksCount Tracks',
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                ),
              ],
            ],
          ),

          // Bio (shown when not empty)
          if (bio != null && bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio!,
              style: const TextStyle(
                  color: Color(0xFF999999), fontSize: 13, height: 1.5),
            ),
          ],

          // Location
          if (location != null && location!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Color(0xFF888888), size: 14),
                const SizedBox(width: 3),
                Text(location!,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final bool isOwnProfile;
  final bool isFollowing;
  final VoidCallback onEditTap;
  final VoidCallback onFollowTap;
  final VoidCallback onShuffleTap;
  final VoidCallback onPlayTap;

  const _ActionRow({
    required this.isOwnProfile,
    required this.isFollowing,
    required this.onEditTap,
    required this.onFollowTap,
    required this.onShuffleTap,
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          // Own profile → pencil edit icon
          // Other user  → Follow / Following button
          if (isOwnProfile)
            GestureDetector(
              onTap: onEditTap,
              child: Row(
                children: const [
                  Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Edit',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            )
          else
            Expanded(
              child: GestureDetector(
                onTap: onFollowTap,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isFollowing
                        ? const Color(0xFFFF5500)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isFollowing
                          ? const Color(0xFFFF5500)
                          : const Color(0xFF555555),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

          const Spacer(),

          // Shuffle
          GestureDetector(
            onTap: onShuffleTap,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.shuffle,
                  color: Colors.white.withOpacity(0.8), size: 22),
            ),
          ),
          const SizedBox(width: 8),

          // Play all
          GestureDetector(
            onTap: onPlayTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _ProfileTabBar extends StatelessWidget {
  final TabController controller;
  const _ProfileTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: TabBar(
        controller: controller,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF666666),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        indicatorColor: const Color(0xFFFF5500),
        indicatorWeight: 2,
        tabs: const [
          Tab(text: 'Likes'),
          Tab(text: 'Tracks'),
          Tab(text: 'Playlists'),
          Tab(text: 'Reposts'),
        ],
      ),
    );
  }
}

// ── Tab contents ──────────────────────────────────────────────────────────────

class _LikesTab extends StatelessWidget {
  final List<_MockTrack> tracks;
  const _LikesTab({required this.tracks});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const _EmptyTab(
        icon: Icons.favorite_border,
        message: 'No liked tracks yet',
      );
    }
    return _TrackList(
      sectionLabel: 'Likes',
      tracks: tracks,
      showHeart: true,
    );
  }
}

class _TracksTab extends StatelessWidget {
  final List<_MockTrack> tracks;
  const _TracksTab({required this.tracks});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const _EmptyTab(
        icon: Icons.music_note_outlined,
        message: 'No tracks uploaded yet',
      );
    }
    return _TrackList(
      sectionLabel: 'Tracks',
      tracks: tracks,
      showHeart: false,
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  final List<_MockPlaylist> playlists;
  const _PlaylistsTab({required this.playlists});

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const _EmptyTab(
        icon: Icons.queue_music_outlined,
        message: 'No playlists yet',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: playlists.length,
      separatorBuilder: (_, __) => const Divider(
          color: Color(0xFF1A1A1A), height: 1, indent: 14, endIndent: 14),
      itemBuilder: (context, i) => _PlaylistRow(playlist: playlists[i]),
    );
  }
}

class _RepostsTab extends StatelessWidget {
  final List<_MockTrack> tracks;
  const _RepostsTab({required this.tracks});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const _EmptyTab(
        icon: Icons.repeat,
        message: 'No reposts yet',
      );
    }
    return _TrackList(
      sectionLabel: 'Reposts',
      tracks: tracks,
      showHeart: false,
    );
  }
}

// ── Shared track list ─────────────────────────────────────────────────────────

class _TrackList extends StatelessWidget {
  final String sectionLabel;
  final List<_MockTrack> tracks;
  final bool showHeart;

  const _TrackList({
    required this.sectionLabel,
    required this.tracks,
    required this.showHeart,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: tracks.length + 1, // +1 for section header
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sectionLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('See All',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          );
        }
        final track = tracks[i - 1];
        return Column(
          children: [
            _TrackRow(track: track, showHeart: showHeart),
            if (i < tracks.length)
              const Divider(
                  color: Color(0xFF1A1A1A),
                  height: 1,
                  indent: 14,
                  endIndent: 14),
          ],
        );
      },
    );
  }
}

class _TrackRow extends StatelessWidget {
  final _MockTrack track;
  final bool showHeart;
  const _TrackRow({required this.track, required this.showHeart});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO(backend): context.read<PlaybackCubit>().play(track.id)
        // Sprint 3 — T3.5 Full Player Screen
      },
      splashColor: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            // Artwork
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: track.artColor,
              ),
              child: const Icon(Icons.person,
                  color: Colors.white54, size: 28),
              // TODO(backend): Replace with CachedNetworkImage(url: track.artworkUrl)
            ),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.play_arrow,
                          color: Color(0xFF888888), size: 14),
                      const SizedBox(width: 2),
                      Text(track.plays,
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 11)),
                      const Text(' · ',
                          style: TextStyle(
                              color: Color(0xFF888888), fontSize: 11)),
                      Text(track.duration,
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 11)),
                      if (showHeart) ...[
                        const Text(' · ',
                            style: TextStyle(
                                color: Color(0xFF888888), fontSize: 11)),
                        const Icon(Icons.favorite,
                            color: Color(0xFFFF5500), size: 12),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // More options
            IconButton(
              onPressed: () {
                // TODO(backend): Show track options bottom sheet
              },
              icon: const Icon(Icons.more_vert,
                  color: Color(0xFF555555), size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  final _MockPlaylist playlist;
  const _PlaylistRow({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO(backend): Navigate to playlist detail page (Sprint 4 — T4.9)
      },
      splashColor: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: playlist.artColor,
              ),
              child: const Icon(Icons.queue_music,
                  color: Colors.white54, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${playlist.trackCount} tracks',
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.more_vert,
                color: Color(0xFF555555), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Empty tab state ───────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyTab({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF444444)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: Color(0xFF666666), fontSize: 14)),
        ],
      ),
    );
  }
}

// ============================================================================
// MOCK DATA — DELETE EVERYTHING BELOW WHEN INTEGRATING WITH BACKEND
// Replace _MockProfileData.forUser(...) with a BlocBuilder that reads from
// ProfileCubit, which in turn calls ProfileRepository → ProfileRemoteDataSource
// ============================================================================

class _MockTrack {
  final String id;
  final String title;
  final String artist;
  final String plays;
  final String duration;
  final Color artColor;

  const _MockTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.plays,
    required this.duration,
    required this.artColor,
  });
}

class _MockPlaylist {
  final String id;
  final String title;
  final int trackCount;
  final Color artColor;

  const _MockPlaylist({
    required this.id,
    required this.title,
    required this.trackCount,
    required this.artColor,
  });
}

class _MockProfileData {
  final String name;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final int followersCount;
  final int followingCount;
  final int tracksCount;
  final List<_MockTrack> likedTracks;
  final List<_MockTrack> ownedTracks;
  final List<_MockPlaylist> playlists;
  final List<_MockTrack> repostedTracks;

  const _MockProfileData({
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.location,
    required this.followersCount,
    required this.followingCount,
    required this.tracksCount,
    required this.likedTracks,
    required this.ownedTracks,
    required this.playlists,
    required this.repostedTracks,
  });

  factory _MockProfileData.forUser(String userId, bool isOwn) {
    if (isOwn) {
      return _MockProfileData(
        name: 'اياد عادل',
        avatarUrl: null,
        bio: null,
        location: null,
        followersCount: 0,
        followingCount: 1,
        tracksCount: 0,
        likedTracks: const [
          _MockTrack(
            id: 't1', title: 'Titanium Alone', artist: 'anh an',
            plays: '2.8K', duration: '2:53',
            artColor: Color(0xFF5B7BBB),
          ),
          _MockTrack(
            id: 't2',
            title: 'Marshmello & Anne Marie - FRIEN...',
            artist: 'Sikdope, Marshmello, Anne Marie',
            plays: '847K', duration: '2:43',
            artColor: Color(0xFF2a1a2e),
          ),
          _MockTrack(
            id: 't3', title: 'Blinding Lights (Remix)',
            artist: 'The Weeknd', plays: '1.2M', duration: '3:20',
            artColor: Color(0xFF1a2a1a),
          ),
        ],
        ownedTracks: const [],
        playlists: const [],
        repostedTracks: const [],
      );
    }

    // Generic other-user profile
    return _MockProfileData(
      name: 'Ali Mahmoud',
      avatarUrl: null,
      bio: 'Producer & DJ from Cairo',
      location: 'Cairo, Egypt',
      followersCount: 4200,
      followingCount: 318,
      tracksCount: 12,
      likedTracks: const [],
      ownedTracks: const [
        _MockTrack(
          id: 'o1', title: 'Midnight Drive', artist: 'Ali Mahmoud',
          plays: '12.4K', duration: '3:42',
          artColor: Color(0xFFE85D04),
        ),
        _MockTrack(
          id: 'o2', title: 'Neon Waves', artist: 'Ali Mahmoud',
          plays: '8.9K', duration: '4:17',
          artColor: Color(0xFF6C63FF),
        ),
      ],
      playlists: const [
        _MockPlaylist(
          id: 'p1', title: 'My Late Night Mix',
          trackCount: 18, artColor: Color(0xFF1a1a2e),
        ),
        _MockPlaylist(
          id: 'p2', title: 'Cairo Vibes',
          trackCount: 9, artColor: Color(0xFF1a2a1a),
        ),
      ],
      repostedTracks: const [],
    );
  }
}

// ============================================================================
// BACKEND INTEGRATION GUIDE — what changes and where
// ============================================================================
//
// 1. REMOVE all _Mock* classes at the bottom of this file.
//
// 2. CREATE these files (follow existing auth feature pattern):
//
//    lib/features/profile/domain/entities/profile_entity.dart
//      - Fields: id, username, displayName, avatarUrl, bio, location,
//                followersCount, followingCount, tracksCount, isOwnProfile
//
//    lib/features/profile/domain/repositories/profile_repository.dart
//      - getProfile(String userId) → Either<Failure, ProfileEntity>
//
//    lib/features/profile/data/dto/profile_dto.dart
//      - fromJson(Map<String, dynamic>) → ProfileEntity
//
//    lib/features/profile/data/datasources/profile_remote_data_source.dart
//      - getProfile(String userId) → calls GET /profile/:userId
//
//    lib/features/profile/data/repositories/profile_repository_impl.dart
//      - implements ProfileRepository
//
//    lib/features/profile/domain/usecases/get_profile_usecase.dart
//
//    lib/features/profile/presentation/bloc/profile_cubit.dart
//      states: ProfileInitial | ProfileLoading | ProfileLoaded | ProfileError
//
// 3. IN ProfilePage.build():
//    Wrap body with BlocBuilder<ProfileCubit, ProfileState>:
//
//    BlocBuilder<ProfileCubit, ProfileState>(
//      builder: (context, state) {
//        if (state is ProfileLoading) return const Center(child: CircularProgressIndicator());
//        if (state is ProfileError)   return _ErrorView(message: state.message);
//        if (state is ProfileLoaded)  return _buildBody(state.profile);
//        return const SizedBox.shrink();
//      },
//    )
//
// 4. AVATAR: Replace the CircleAvatar placeholder with:
//    CachedNetworkImage(imageUrl: profile.avatarUrl, ...)
//    Add to pubspec.yaml: cached_network_image: ^3.x.x
//
// 5. FOLLOW state: Read from SocialCubit (T2.9, Ahmed Reda)
//    The SocialCubit handles optimistic updates and count changes.
//
// 6. TABS content: Each tab will call its own endpoint:
//    GET /users/:id/likes     → LikesTab
//    GET /users/:id/tracks    → TracksTab
//    GET /users/:id/playlists → PlaylistsTab
//    GET /users/:id/reposts   → RepostsTab
//    Wrap each tab with PaginatedUserList (Eyad's T2.2 scaffold)
//    or a similar PaginatedTrackList built the same way.
//
// 7. PLAYBACK: Track row taps will trigger PlaybackCubit (Sprint 3, Ali)