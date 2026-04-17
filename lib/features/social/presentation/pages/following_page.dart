import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
          child: const _FollowingView(),
        );
      },
    );
  }
}

class _FollowingView extends StatefulWidget {
  const _FollowingView();

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

          if (state.users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_outlined, color: Colors.grey, size: 56),
                  SizedBox(height: 16),
                  Text(
                    'Not following anyone yet',
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
                return _FollowingTile(user: user);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FollowingTile extends StatelessWidget {
  final User user;

  const _FollowingTile({required this.user});

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // زرار Unfollow
        GestureDetector(
          onTap: () => context.read<FollowCubit>().unfollowUser(user),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Following',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // زرار Block (3 نقاط)
        GestureDetector(
          onTap: () => _showBlockConfirmation(context, user),
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
  }
}
