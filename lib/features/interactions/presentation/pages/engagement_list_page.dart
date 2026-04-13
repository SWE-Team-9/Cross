import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/engagement_user.dart';
import '../bloc/engagement_list_cubit.dart';
import '../bloc/engagement_list_state.dart';

class EngagementListPage extends StatefulWidget {
  final String trackId;
  final EngagementListType type;

  const EngagementListPage({
    super.key,
    required this.trackId,
    required this.type,
  });

  @override
  State<EngagementListPage> createState() => _EngagementListPageState();
}

class _EngagementListPageState extends State<EngagementListPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    context.read<EngagementListCubit>().load(
          trackId: widget.trackId,
          type: widget.type,
        );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      context.read<EngagementListCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: BlocBuilder<EngagementListCubit, EngagementListState>(
          builder: (context, state) => Text(state.title),
        ),
        backgroundColor: Colors.black,
      ),
      body: BlocBuilder<EngagementListCubit, EngagementListState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          if (state.items.isEmpty) {
            return Center(
              child: Text(
                widget.type == EngagementListType.likers
                    ? 'No likes yet'
                    : 'No reposts yet',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            controller: _scrollController,
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Colors.white12,
            ),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final user = state.items[index];
              return _EngagementUserTile(user: user);
            },
          );
        },
      ),
    );
  }
}

class _EngagementUserTile extends StatelessWidget {
  final EngagementUser user;

  const _EngagementUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white12,
        backgroundImage:
            user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? const Icon(Icons.person, color: Colors.white70)
            : null,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: user.interactedAt != null
          ? Text(
              _formatDate(user.interactedAt!),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            )
          : null,
      onTap: () {},
    );
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
