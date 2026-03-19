import 'package:flutter/material.dart';
import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';

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
      body: PaginatedUserList<String>(
        // TODO: Ahmed Reda — replace with real repository call
        fetcher: (_) async => [],
        itemBuilder: (context, user) => ListTile(
          title: Text(user, style: const TextStyle(color: Colors.white)),
        ),
        emptyMessage: 'Not following anyone yet',
        emptyIcon: Icons.person_add_outlined,
      ),
    );
  }
}
