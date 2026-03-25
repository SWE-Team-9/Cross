import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/domain/enums/user_action_type.dart';
import 'package:soundcloud_clone/features/social/presentation/bloc/user_action_bloc/user_action_cubit.dart';

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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Following',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: BlocProvider(
        create: (_) => UserActionCubit(repo),
        child: PaginatedUserList<User>(
          fetcher: (page) async {
            final resolvedUserId = await _resolveTargetUserId(context, repo);

            if (resolvedUserId == null || resolvedUserId.isEmpty) {
              return const <User>[];
            }

            return repo.getFollowing(resolvedUserId, page);
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
              trailing: BlocConsumer<UserActionCubit, UserActionState>(
                listener: (context, state) {
                  if (state is UserActionSuccess && state.userId == user.id) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.action.toString()),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: state is UserActionLoading
                            ? null
                            : () {
                                context.read<UserActionCubit>().performAction(
                                      userId: user.id,
                                      action: UserActionType.unfollow,
                                    );
                              },
                        child: const Text('Unfollow'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: state is UserActionLoading
                            ? null
                            : () {
                                context.read<UserActionCubit>().performAction(
                                      userId: user.id,
                                      action: UserActionType.block,
                                    );
                              },
                        child: const Text('Block'),
                      ),
                    ],
                  );
                },
              ),
            );
          },
          emptyMessage: 'Not following anyone yet',
          emptyIcon: Icons.person_add_outlined,
        ),
      ),
    );
  }
}
