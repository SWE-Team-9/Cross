// coverage:ignore-file
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';

import '../../data/repositories/social_repo.dart';
import '../../domain/entities/user.dart';
import '../bloc/suggested_users_cubit.dart';

class SuggestedUsersPage extends StatelessWidget {
  const SuggestedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuggestedUsersCubit(context.read<SocialRepo>()),
      child: const _SuggestedUsersView(),
    );
  }
}

class _SuggestedUsersView extends StatefulWidget {
  const _SuggestedUsersView();

  @override
  State<_SuggestedUsersView> createState() => _SuggestedUsersViewState();
}

class _SuggestedUsersViewState extends State<_SuggestedUsersView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SuggestedUsersCubit>().loadInitial();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SuggestedUsersCubit>().loadMore();
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
          'Suggested users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<SuggestedUsersCubit, SuggestedUsersState>(
        builder: (context, state) {
          if (state.isLoading && state.users.isEmpty) {
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
                  const SizedBox(height: 12),
                  Text('Something went wrong',
                      style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        context.read<SuggestedUsersCubit>().loadInitial(),
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
            );
          }

          if (state.users.isEmpty) {
            return const Center(
              child: Text(
                'No suggested users right now',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.orange,
            backgroundColor: Colors.grey[900],
            onRefresh: () => context.read<SuggestedUsersCubit>().loadInitial(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: state.users.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.users.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Colors.orange, strokeWidth: 2),
                    ),
                  );
                }

                final user = state.users[index];
                return _SuggestedUserTile(user: user);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SuggestedUserTile extends StatelessWidget {
  const _SuggestedUserTile({required this.user});

  final User user;

  // ✅ فيتشر 6: helper لـ navigation ذكي
  Future<void> _navigateToProfile(BuildContext context) async {
    if (user.username.trim().isEmpty) return;
    ProfileRoutes.goToProfile(context, user.username.trim());
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = PlatformUrlUtils.normalizeBackendUrl(user.avatarUrl);
    final isDefaultAvatar = avatarUrl == null ||
        avatarUrl.isEmpty ||
        avatarUrl.contains('default-avatar');

    return BlocBuilder<SuggestedUsersCubit, SuggestedUsersState>(
      // ✅ فيتشر 2: نبني بس لما الـ loadingIds أو الـ user اتغير
      buildWhen: (prev, curr) =>
          prev.loadingIds != curr.loadingIds || prev.users != curr.users,
      builder: (context, state) {
        final isButtonLoading = state.loadingIds.contains(user.id);

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () => _navigateToProfile(context),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[800],
            // ✅ فيتشر 1: CachedNetworkImage
            child: isDefaultAvatar
                ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ),
          title: Text(
            user.username,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          // ✅ فيتشر 4: icon جنب عدد الـ followers
          subtitle: Row(
            children: [
              const Icon(Icons.person, color: Colors.grey, size: 14),
              const SizedBox(width: 4),
              Text(
                '${user.followersCount} followers',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          trailing: SizedBox(
            height: 36,
            width: 110,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: user.isFollowing ? Colors.grey : Colors.orange,
                  width: 1.2,
                ),
                foregroundColor:
                    user.isFollowing ? Colors.grey[300] : Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              // ✅ فيتشر 2: disable الزرار لو loading
              onPressed: isButtonLoading
                  ? null
                  : () =>
                      context.read<SuggestedUsersCubit>().toggleFollow(user),
              // ✅ فيتشر 2: spinner على الزرار نفسه
              child: isButtonLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: user.isFollowing ? Colors.grey : Colors.orange,
                      ),
                    )
                  : Text(user.isFollowing ? 'Following' : 'Follow'),
            ),
          ),
        );
      },
    );
  }
}
