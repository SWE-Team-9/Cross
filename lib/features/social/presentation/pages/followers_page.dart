import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
              // +1 للـ loading indicator في الأسفل
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: user.username.trim().isEmpty
          ? null
          : () => ProfileRoutes.goToProfile(context, user.username.trim()),
      leading: CircleAvatar(
        backgroundColor: Colors.grey[800],
        child: Text(
          user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        user.username,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${user.followersCount} followers',
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
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
    // BlocBuilder هنا بيعمل rebuild للزرار ده بس لما الـ state تتغير
    return BlocBuilder<FollowCubit, FollowState>(
      // buildWhen: نبني بس لو اليوزر ده اتغير — أداء أحسن
      buildWhen: (prev, curr) {
        final prevUser = prev.users.firstWhere(
          (u) => u.id == user.id,
          orElse: () => user,
        );
        final currUser = curr.users.firstWhere(
          (u) => u.id == user.id,
          orElse: () => user,
        );
        return prevUser.isFollowing != currUser.isFollowing;
      },
      builder: (context, state) {
        // جيب آخر نسخة من اليوزر من الـ state
        final currentUser = state.users.firstWhere(
          (u) => u.id == user.id,
          orElse: () => user,
        );

        final isFollowing = currentUser.isFollowing;

        return GestureDetector(
          onTap: () => context.read<FollowCubit>().toggleFollow(currentUser),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: isFollowing ? Colors.transparent : Colors.orange,
              border: Border.all(
                color: isFollowing ? Colors.grey[600]! : Colors.orange,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: TextStyle(
                color: isFollowing ? Colors.grey[400] : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
