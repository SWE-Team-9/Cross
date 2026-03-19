import 'package:flutter/material.dart';
import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';

/// Followers list page stub.
/// Route: /followers/:userId
///
/// TODO (Ahmed Reda — T2.10):
///   1. Replace `String` with your real UserEntity type.
///   2. Inject the social repository and call getFollowers(userId, page: page).
///   3. Replace ListTile with your UserListTile widget from social/widgets/.
class FollowersPage extends StatelessWidget {
  final String userId;

  const FollowersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Followers', style: TextStyle(color: Colors.white)),
      ),
      body: PaginatedUserList<String>(
        // TODO: Ahmed Reda — replace with real repository call
        fetcher: (_) async => [],
        itemBuilder: (context, user) => ListTile(
          title: Text(user, style: const TextStyle(color: Colors.white)),
        ),
        emptyMessage: 'No followers yet',
        emptyIcon: Icons.people_outline,
      ),
    );
  }
}