import 'package:flutter/material.dart';

// Third-party
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Project
import '../../../../core/di/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';
import '../routes/profile_routes.dart';

class ProfilePage extends StatelessWidget {
  final String handle;

  /// Only used in tests to bypass GetIt.
  /// Production always leaves this null — getIt<ProfileCubit>() is used instead.
  final ProfileCubit? cubit;

  const ProfilePage({
    super.key,
    required this.handle,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => cubit ?? (getIt<ProfileCubit>()..loadProfile(handle)),
      child: _ProfilePageBody(handle: handle),
    );
  }
}

class _ProfilePageBody extends StatefulWidget {
  final String handle;

  const _ProfilePageBody({required this.handle});

  @override
  State<_ProfilePageBody> createState() => _ProfilePageBodyState();
}

class _ProfilePageBodyState extends State<_ProfilePageBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isFollowing = false;

  bool get _isOwnProfile {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.handle == widget.handle;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white54, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
          );
        }

        final ProfileEntity? profile = switch (state) {
          ProfileLoaded s => s.profile,
          ProfileUpdating s => s.currentProfile,
          ProfileUpdateSuccess s => s.updatedProfile,
          ProfileUpdateError s => s.currentProfile,
          ProfileImageUploading s => s.currentProfile,
          _ => null,
        };

        if (profile == null) {
          return const Scaffold(backgroundColor: Colors.black);
        }

        return _buildBody(context, profile);
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileEntity profile) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  _buildAvatar(profile),
                  _buildUserInfo(context, profile),
                  _buildActionRow(context, profile),
                  _buildTabBar(),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildEmptyTab(Icons.favorite_border, 'No liked tracks yet'),
              _buildEmptyTab(Icons.music_note_outlined, 'No tracks yet'),
              _buildEmptyTab(Icons.queue_music_outlined, 'No playlists yet'),
              _buildEmptyTab(Icons.repeat, 'No reposts yet'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleIconBtn(Icons.arrow_back, () => context.pop()),
          Row(children: [
            _circleIconBtn(Icons.cast, () {}),
            const SizedBox(width: 8),
            _circleIconBtn(Icons.more_vert, () {}),
          ]),
        ],
      ),
    );
  }

  Widget _circleIconBtn(IconData icon, VoidCallback onTap) {
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

  Widget _buildAvatar(ProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: const Color(0xFF5B7BBB),
        backgroundImage: profile.avatarUrl != null
            ? CachedNetworkImageProvider(profile.avatarUrl!)
            : null,
        child: profile.avatarUrl == null
            ? const Icon(Icons.person, size: 56, color: Color(0xFF7B9FD4))
            : null,
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, ProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.displayName,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    ProfileRoutes.goToFollowers(context, profile.handle),
                child: const Text(
                  '0 Followers',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                ),
              ),
              const Text(' · ',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
              GestureDetector(
                onTap: () =>
                    ProfileRoutes.goToFollowing(context, profile.handle),
                child: const Text(
                  '0 Following',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                ),
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.bio!,
              style: const TextStyle(
                  color: Color(0xFF999999), fontSize: 13, height: 1.5),
            ),
          ],
          if (profile.location != null && profile.location!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  color: Color(0xFF888888), size: 14),
              const SizedBox(width: 3),
              Text(profile.location!,
                  style:
                      const TextStyle(color: Color(0xFF888888), fontSize: 12)),
            ]),
          ],
          if (profile.favoriteGenres.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: profile.favoriteGenres.map((genre) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF444444)),
                  ),
                  child: Text(genre,
                      style: const TextStyle(
                          color: Color(0xFFCCCCCC), fontSize: 11)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, ProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          if (_isOwnProfile)
            GestureDetector(
              onTap: () => ProfileRoutes.goToEditProfile(context),
              child: const Row(children: [
                Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('Edit',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ]),
            )
          else
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isFollowing = !_isFollowing),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _isFollowing
                        ? const Color(0xFFFF5500)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isFollowing
                          ? const Color(0xFFFF5500)
                          : const Color(0xFF555555),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.shuffle,
                  color: Colors.white.withValues(alpha: 0.8), size: 22),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.play_arrow, color: Colors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: TabBar(
        controller: _tabController,
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

  Widget _buildEmptyTab(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF444444)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 14)),
        ],
      ),
    );
  }
}
