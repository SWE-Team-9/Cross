import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/domain/enums/user_action_type.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/presentation/bloc/user_action_bloc/user_action_cubit.dart';

class FollowersPage extends StatelessWidget {
  final String? userId;
  final String? handle;

  const FollowersPage({
    super.key,
    this.userId,
    this.handle,
  });

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
            final resolvedUserId = userId ??
                (handle != null ? await repo.getUserIdByHandle(handle!) : '');

            if (resolvedUserId.isEmpty) {
              return [];
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
                      user.isFollowing ? "Unfollow" : "Follow",
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
