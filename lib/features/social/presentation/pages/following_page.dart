import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/presentation/bloc/follow_bloc/cubit/follow_cubit.dart';

class FollowingPage extends StatelessWidget {
  final String handle;

  const FollowingPage({
    super.key,
    required this.handle,
  });

  Future<String?> _resolveTargetUserId(
    BuildContext context,
    SocialRepo repo,
  ) async {
    final authState = context.read<AuthCubit>().state;

    if (authState is AuthAuthenticated &&
        authState.user.handle == handle.trim()) {
      return authState.user.id;
    }

    try {
      return await repo.getUserIdByHandle(handle.trim());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SocialRepo>();
    final authState = context.read<AuthCubit>().state;
    final viewerUserId =
        authState is AuthAuthenticated ? authState.user.id : null;

    return FutureBuilder<String?>(
      future: _resolveTargetUserId(context, repo),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body:
                Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
        }

        final resolvedId = snapshot.data;

        if (resolvedId == null || resolvedId.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'User not found',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return BlocProvider(
          create: (_) => FollowCubit(
            repo: repo,
            userId: resolvedId,
            mode: FollowListMode.following,
            viewerUserId: viewerUserId,
          )..loadInitial(),
          child: _FollowingView(
            isOwnProfile: viewerUserId == resolvedId,
            repo: repo,
            viewerUserId: viewerUserId,
          ),
        );
      },
    );
  }
}

class _FollowingView extends StatefulWidget {
  final bool isOwnProfile;
  final SocialRepo repo;
  final String? viewerUserId;

  const _FollowingView({
    required this.isOwnProfile,
    required this.repo,
    required this.viewerUserId,
  });

  @override
  State<_FollowingView> createState() => _FollowingViewState();
}

class _FollowingViewState extends State<_FollowingView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FollowCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Following',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined, color: Colors.white70),
            onPressed: () => context.push('/suggested-users'),
          ),
        ],
      ),
      body: BlocBuilder<FollowCubit, FollowState>(
        builder: (context, state) {
          if (state.loading && state.users.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (state.error != null && state.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<FollowCubit>().loadInitial(),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.orange,
            backgroundColor: Colors.grey[900],
            onRefresh: () => context.read<FollowCubit>().loadInitial(),
            child: Column(
              children: [
                // ✅ فيتشر 6: True Friends Banner (للـ own profile بس)
                if (widget.isOwnProfile) ...[
                  const SizedBox(height: 12),
                  _TrueFriendsBanner(
                    repo: widget.repo,
                    viewerUserId: widget.viewerUserId,
                  ),
                  const SizedBox(height: 12),
                ],

                Expanded(
                  child: state.users.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add_outlined,
                                  color: Colors.grey, size: 56),
                              SizedBox(height: 16),
                              Text(
                                'Not following anyone yet',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              state.users.length + (state.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.users.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final user = state.users[index];
                            return _FollowingTile(user: user);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ✅ فيتشر 6: True Friends Banner Widget
class _TrueFriendsBanner extends StatelessWidget {
  final SocialRepo repo;
  final String? viewerUserId;

  const _TrueFriendsBanner({
    required this.repo,
    required this.viewerUserId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _TrueFriendsPage(
            repo: repo,
            viewerUserId: viewerUserId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 1.5),
              ),
              child: const Icon(Icons.people_outline,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'People who follow you back',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'see your true friends',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}

// ✅ فيتشر 6: True Friends Page
class _TrueFriendsPage extends StatefulWidget {
  final SocialRepo repo;
  final String? viewerUserId;

  const _TrueFriendsPage({
    required this.repo,
    required this.viewerUserId,
  });

  @override
  State<_TrueFriendsPage> createState() => _TrueFriendsPageState();
}

class _TrueFriendsPageState extends State<_TrueFriendsPage> {
  List<User> _mutuals = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchMutuals();
  }

  Future<void> _fetchMutuals() async {
    if (widget.viewerUserId == null) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        widget.repo.getFollowers(widget.viewerUserId!, 1, limit: 100),
        widget.repo.getFollowing(widget.viewerUserId!, 1, limit: 100),
      ]);

      final followers = results[0];
      final followingIds = results[1].map((u) => u.id).toSet();

      setState(() {
        _mutuals = followers.where((u) => followingIds.contains(u.id)).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Your true friends',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Couldn't load mutual followers",
                        style: TextStyle(color: Colors.grey[400], fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _fetchMutuals,
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                )
              : _mutuals.isEmpty
                  ? Center(
                      child: Text(
                        'No mutual followers yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _mutuals.length,
                      itemBuilder: (context, i) {
                        final user = _mutuals[i];
                        return _TrueFriendTile(user: user);
                      },
                    ),
    );
  }
}

class _TrueFriendTile extends StatelessWidget {
  final User user;

  const _TrueFriendTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = PlatformUrlUtils.normalizeBackendUrl(user.avatarUrl);

    // ✅ فيتشر 2: Default Avatar Check
    final isDefaultAvatar = avatarUrl == null ||
        avatarUrl.isEmpty ||
        avatarUrl.contains('default-avatar');

    final initial =
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: user.username.trim().isEmpty
          ? null
          : () => ProfileRoutes.goToProfile(context, user.username.trim()),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[800],
        child: isDefaultAvatar
            ? Text(initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18))
            : ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
              ),
      ),
      title: Text(user.username,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Row(
        children: [
          const Icon(Icons.people, color: Colors.grey, size: 16),
          const SizedBox(width: 4),
          Text('${user.followersCount} followers',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}

class _FollowingTile extends StatelessWidget {
  final User user;

  const _FollowingTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = PlatformUrlUtils.normalizeBackendUrl(user.avatarUrl);

    // ✅ فيتشر 2: Default Avatar Check المحسّن
    final isDefaultAvatar = avatarUrl == null ||
        avatarUrl.isEmpty ||
        avatarUrl.contains('default-avatar');

    final initial =
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: user.username.trim().isEmpty
          ? null
          : () => ProfileRoutes.goToProfile(context, user.username.trim()),
      // ✅ فيتشر 1: CachedNetworkImage + فيتشر 2: Default Avatar Check
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey[800],
        child: isDefaultAvatar
            ? Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
      ),
      title: Text(
        user.username,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: _FollowingActions(user: user),
    );
  }
}

class _FollowingActions extends StatelessWidget {
  final User user;

  const _FollowingActions({required this.user});

  void _showBlockConfirmation(BuildContext context, User currentUser) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Block ${currentUser.username}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'They won\'t be able to follow you or see your profile.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FollowCubit>().blockUser(currentUser);
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FollowCubit, FollowState>(
      buildWhen: (prev, curr) =>
          prev.loadingIds.contains(user.id) !=
              curr.loadingIds.contains(user.id) ||
          prev.users != curr.users,
      builder: (context, state) {
        final isLoading = state.loadingIds.contains(user.id);
        final currentUser = state.users.firstWhere(
          (u) => u.id == user.id,
          orElse: () => user,
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 34,
              width: 90,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // ✅ لو following رمادي، لو لأ برتقالي
                  backgroundColor: currentUser.isFollowing
                      ? Colors.grey[800]
                      : Colors.orange,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () => context.read<FollowCubit>().toggleFollow(
                        currentUser), // ✅ toggleFollow بدل unfollowUser
                child: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: currentUser.isFollowing
                              ? Colors.white
                              : Colors.black,
                        ),
                      )
                    : Text(
                        currentUser.isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          color: currentUser.isFollowing
                              ? Colors.grey[400]
                              : Colors.white,
                          fontSize: 12, // ✅ أصغر عشان ميزيدش
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showBlockConfirmation(context, currentUser),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[700]!, width: 1.5),
                ),
                child: Icon(
                  Icons.more_horiz,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
