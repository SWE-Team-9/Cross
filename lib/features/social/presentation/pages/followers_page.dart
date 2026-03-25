import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/domain/enums/user_action_type.dart';
import 'package:soundcloud_clone/features/social/presentation/bloc/user_action_bloc/user_action_cubit.dart';

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

    if (handle == null || handle!.trim().isEmpty) {
      return null;
    }

    try {
      return await repo.getUserIdByHandle(handle!.trim());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SocialRepo>();

    return BlocProvider(
      create: (_) => UserActionCubit(repo),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Followers',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: PaginatedUserList<User>(
          fetcher: (page) async {
            final resolvedUserId = await _resolveTargetUserId(context, repo);

            if (resolvedUserId == null || resolvedUserId.isEmpty) {
              return const <User>[];
            }

            return repo.getFollowers(resolvedUserId, page);
          },
          itemBuilder: (context, user) {
            return ListTile(
              title: Text(
                user.username,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${user.followersCount} followers',
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: BlocBuilder<UserActionCubit, UserActionState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is UserActionLoading
                        ? null
                        : () {
                            context.read<UserActionCubit>().performAction(
                                  userId: user.id,
                                  action: user.isFollowing
                                      ? UserActionType.unfollow
                                      : UserActionType.follow,
                                );
                          },
                    child: Text(
                      user.isFollowing ? 'Unfollow' : 'Follow',
                    ),
                  );
                },
              ),
            );
          },
          emptyMessage: 'No followers yet',
          emptyIcon: Icons.people_outline,
        ),
      ),
    );
  }
}
