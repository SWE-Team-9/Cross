import 'package:flutter/material.dart';
import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/presentation/bloc/user_action_bloc/user_action_cubit.dart';
import 'package:soundcloud_clone/features/social/domain/enums/user_action_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Following list page stub.
/// Route: /following/:userId
///
/// TODO (Ahmed Reda — T2.10):
///   1. Replace `String` with your real UserEntity type.
///   2. Inject the social repository and call getFollowing(userId, page: page).
///   3. Replace ListTile with your UserListTile widget from social/widgets/.
class FollowingPage extends StatelessWidget {
  final String userId;

  const FollowingPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Following', style: TextStyle(color: Colors.white)),
      ),
      body: PaginatedUserList<User>(
        // TODO: Ahmed Reda — replace with real repository call
        //////wait for real repo
        fetcher: (page) async {
          final repo = SocialRepo();
          return await repo.getFollowers(userId, page);
        },
        itemBuilder: (context, user) {
          return ListTile(
            title: Text(
              user.username,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.read<UserActionCubit>().performAction(
                          userId: user.id,
                          action: UserActionType.unfollow,
                        );
                  },
                  child: const Text("Unfollow"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<UserActionCubit>().performAction(
                          userId: user.id,
                          action: UserActionType.block,
                        );
                  },
                  child: const Text("Block"),
                ),
              ],
            ),
          );
        },
        emptyMessage: 'Not following anyone yet',
        emptyIcon: Icons.person_add_outlined,
      ),
    );
  }
}
