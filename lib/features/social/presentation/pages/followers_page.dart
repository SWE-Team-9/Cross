import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/presentation/bloc/follow_bloc/cubit/follow_cubit.dart';

class FollowersPage extends StatelessWidget {
  final String? userId;
  final String? handle;

  const FollowersPage({
    super.key,
    this.userId,
    this.handle,
  });

  Future<String?> _resolveTargetUserId(
    BuildContext context,
    SocialRepo repo,
  ) async {
    if (userId != null && userId!.trim().isNotEmpty) {
      return userId!.trim();
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated &&
        handle != null &&
        handle!.trim().isNotEmpty &&
        authState.user.handle == handle!.trim()) {
      return authState.user.id;
    }

    if (handle == null || handle!.trim().isEmpty) return null;

    try {
      return await repo.getUserIdByHandle(handle!.trim());
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
            mode: FollowListMode.followers,
            viewerUserId: viewerUserId,
          )..loadInitial(),
          child: const _FollowersView(),
        );
      },
    );
  }
}

class _FollowersView extends StatefulWidget {
  const _FollowersView();

  @override
  State<_FollowersView> createState() => _FollowersViewState();
}

class _FollowersViewState extends State<_FollowersView> {
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
          'Followers',
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

          if (state.users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, color: Colors.grey, size: 56),
                  SizedBox(height: 16),
                  Text(
                    'No followers yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.orange,
            backgroundColor: Colors.grey[900],
            onRefresh: () => context.read<FollowCubit>().loadInitial(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: state.users.length + (state.hasMore ? 1 : 0),
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
                return _FollowerTile(user: user);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FollowerTile extends StatelessWidget {
  final User user;

  const _FollowerTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = PlatformUrlUtils.normalizeBackendUrl(user.avatarUrl);

    // ✅ فيتشر 3: Default Avatar Check المحسّن
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
        // ✅ فيتشر 1: CachedNetworkImage + فيتشر 3: Default Avatar Check
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
      trailing: _FollowButton(user: user),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final User user;

  const _FollowButton({required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FollowCubit, FollowState>(
      buildWhen: (prev, curr) {
        final prevUser = prev.users.firstWhere(
          (u) => u.id == user.id,
          orElse: () => user,
        );
        final currUser = curr.users.firstWhere(
          (u) => u.id == user.id,
          orElse: () => user,
        );
        return prevUser.isFollowing != currUser.isFollowing ||
            prev.loadingIds.contains(user.id) !=
                curr.loadingIds.contains(user.id);
      },
      builder: (context, state) {
        final currentUser = state.users.firstWhere(
          (u) => u.id == user.id,
          orElse: () => user,
        );

        final isFollowing = currentUser.isFollowing;

        // ✅ فيتشر 2: Loading state خاص بكل زرار لوحده
        final isLoading = state.loadingIds.contains(user.id);

        // ✅ فيتشر 5: ElevatedButton بدل AnimatedContainer
        return SizedBox(
          height: 36,
          width: 110,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey[800] : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: isLoading
                ? null
                : () => context.read<FollowCubit>().toggleFollow(currentUser),
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isFollowing ? Colors.white : Colors.black,
                    ),
                  )
                : Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      color: isFollowing ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
