// lib/features/search/presentation/widgets/search_widgets.dart
// ملف واحد فيه كل الـ widgets — استبدل الـ 6 ملفات القديمة بيه

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/search_entities.dart';
import '../../../../core/errors/failure.dart';
import '../bloc/search_cubit.dart';

// ══════════════════════════════════════════════════════════════════════════════
// search_bar_widget.dart
// ══════════════════════════════════════════════════════════════════════════════

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.search, color: Colors.white54, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Search tracks, people, playlists…',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                isDense: true,
              ),
              cursorColor: const Color(0xFFFF5500),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox(width: 12);
              return GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.close, color: Colors.white54, size: 18),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// search_tabs_widget.dart
// ══════════════════════════════════════════════════════════════════════════════

class SearchTabsWidget extends StatelessWidget {
  final TabController controller;

  const SearchTabsWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Color(0xFFFF5500), width: 2.5),
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Tracks'),
          Tab(text: 'Profiles'),
          Tab(text: 'Playlists'),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// search_results_widget.dart
// ══════════════════════════════════════════════════════════════════════════════

class SearchResultsWidget extends StatelessWidget {
  final SearchState state;
  final TabController tabController;
  final ScrollController scrollController;

  const SearchResultsWidget({
    super.key,
    required this.state,
    required this.tabController,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        // All
        _AllTab(state: state, scrollController: scrollController),
        // Tracks
        _ListTab(
          isEmpty: state.tracks.isEmpty,
          emptyIcon: Icons.music_off_rounded,
          emptyMsg: 'No tracks for "${state.submittedQuery}"',
          itemCount: state.tracks.length,
          scrollController: scrollController,
          isLoadingMore: state.isLoadingMore,
          itemBuilder: (_, i) => _TrackTile(track: state.tracks[i]),
        ),
        // Profiles
        _ListTab(
          isEmpty: state.users.isEmpty,
          emptyIcon: Icons.person_off_rounded,
          emptyMsg: 'No profiles for "${state.submittedQuery}"',
          itemCount: state.users.length,
          scrollController: scrollController,
          isLoadingMore: state.isLoadingMore,
          itemBuilder: (_, i) => _UserTile(user: state.users[i]),
        ),
        // Playlists
        _ListTab(
          isEmpty: state.playlists.isEmpty,
          emptyIcon: Icons.playlist_remove_rounded,
          emptyMsg: 'No playlists for "${state.submittedQuery}"',
          itemCount: state.playlists.length,
          scrollController: scrollController,
          isLoadingMore: state.isLoadingMore,
          itemBuilder: (_, i) => _PlaylistTile(playlist: state.playlists[i]),
        ),
      ],
    );
  }
}

// ── All tab ───────────────────────────────────────────────────────────────────

class _AllTab extends StatelessWidget {
  final SearchState state;
  final ScrollController scrollController;
  const _AllTab({required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        if (state.tracks.isNotEmpty) ...[
          const _SliverHeader(title: 'Top Result'),
          SliverToBoxAdapter(
            child: _TopResultTile(track: state.tracks.first),
          ),
          const _SliverHeader(title: 'Tracks'),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _TrackTile(track: state.tracks[i]),
              childCount: state.tracks.length.clamp(0, 5),
            ),
          ),
        ],
        if (state.users.isNotEmpty) ...[
          const _SliverHeader(title: 'Profiles'),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _UserTile(user: state.users[i]),
              childCount: state.users.length.clamp(0, 3),
            ),
          ),
        ],
        if (state.playlists.isNotEmpty) ...[
          const _SliverHeader(title: 'Playlists'),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _PlaylistTile(playlist: state.playlists[i]),
              childCount: state.playlists.length.clamp(0, 3),
            ),
          ),
        ],
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFFF5500)),
                ),
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

// ── Generic list tab ──────────────────────────────────────────────────────────

class _ListTab extends StatelessWidget {
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyMsg;
  final int itemCount;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final Widget Function(BuildContext, int) itemBuilder;

  const _ListTab({
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyMsg,
    required this.itemCount,
    required this.scrollController,
    required this.isLoadingMore,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(emptyIcon, color: Colors.white24, size: 52),
          const SizedBox(height: 12),
          Text(emptyMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 14)),
        ]),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: itemCount + (isLoadingMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == itemCount) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFFF5500)),
              ),
            ),
          );
        }
        return itemBuilder(ctx, i);
      },
    );
  }
}

// ── Sliver header ─────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  final String title;
  const _SliverHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Top result tile ───────────────────────────────────────────────────────────

class _TopResultTile extends StatelessWidget {
  final TrackEntity track;
  const _TopResultTile({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: _Artwork(url: track.artworkUrl, size: 56, radius: 6),
          title: Text(track.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          subtitle: Row(children: [
            const Icon(Icons.play_arrow, color: Colors.white38, size: 12),
            const SizedBox(width: 2),
            Text(_fmt(track.playbackCount),
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const Text(' · ',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text(track.formattedDuration,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
          trailing:
              const Icon(Icons.more_horiz, color: Colors.white38, size: 20),
        ),
      ),
    );
  }
}

// ── Track tile ────────────────────────────────────────────────────────────────

class _TrackTile extends StatelessWidget {
  final TrackEntity track;
  const _TrackTile({required this.track});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _Artwork(url: track.artworkUrl, size: 46, radius: 6),
      title: Text(track.title,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Row(children: [
        Flexible(
          child: Text(track.artistName,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const Text(' · ',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
        Text(track.formattedDuration,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        if (track.playbackCount > 0) ...[
          const Text(' · ',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const Icon(Icons.play_arrow, color: Colors.white38, size: 11),
          Text(_fmt(track.playbackCount),
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ]),
      trailing: const Icon(Icons.more_horiz, color: Colors.white38, size: 20),
    );
  }
}

// ── User tile ─────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserEntity user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 23,
        backgroundColor: const Color(0xFF1C1C1C),
        backgroundImage:
            user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
        child: user.avatarUrl.isEmpty
            ? Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600))
            : null,
      ),
      title: Row(children: [
        Flexible(
          child: Text(user.displayName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        if (user.verified) ...[
          const SizedBox(width: 4),
          const Icon(Icons.verified_rounded,
              color: Color(0xFFFF5500), size: 14),
        ],
      ]),
      subtitle: Text('@${user.username}',
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }
}

// ── Playlist tile ─────────────────────────────────────────────────────────────

class _PlaylistTile extends StatelessWidget {
  final PlaylistEntity playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(children: [
        _Artwork(
            url: playlist.artworkUrl,
            size: 46,
            radius: 6,
            fallback: Icons.queue_music_rounded),
        if (playlist.isPrivate)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Colors.white54, size: 10),
            ),
          ),
      ]),
      title: Text(playlist.title,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Row(children: [
        Flexible(
          child: Text(playlist.ownerName,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const Text(' · ',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
        Text('${playlist.trackCount} tracks',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
      trailing: const Icon(Icons.more_horiz, color: Colors.white38, size: 20),
    );
  }
}

// ── Artwork ───────────────────────────────────────────────────────────────────

class _Artwork extends StatelessWidget {
  final String url;
  final double size;
  final double radius;
  final IconData fallback;

  const _Artwork({
    required this.url,
    required this.size,
    required this.radius,
    this.fallback = Icons.music_note_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.network(url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(fallback, color: Colors.white38, size: size * 0.46)),
            )
          : Icon(fallback, color: Colors.white38, size: size * 0.46),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// search_idle_widget.dart
// ══════════════════════════════════════════════════════════════════════════════

class SearchIdleWidget extends StatelessWidget {
  const SearchIdleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search, color: Colors.white12, size: 56),
        SizedBox(height: 12),
        Text('Search for tracks, people or playlists',
            style: TextStyle(color: Colors.white24, fontSize: 14)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// search_empty_widget.dart
// ══════════════════════════════════════════════════════════════════════════════

class SearchEmptyWidget extends StatelessWidget {
  final String query;
  const SearchEmptyWidget({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.search_off_rounded, color: Colors.white24, size: 52),
        const SizedBox(height: 12),
        Text('No results for "$query"',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Try different keywords',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// search_error_widget.dart
// ══════════════════════════════════════════════════════════════════════════════

class SearchErrorWidget extends StatelessWidget {
  final Failure? failure;
  const SearchErrorWidget({super.key, this.failure});

  bool get _isNetwork => failure is NetworkFailure;
  bool get _isAuth => failure is AuthFailure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            _isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            color: Colors.white24,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            _isNetwork
                ? 'No internet connection'
                : _isAuth
                    ? 'Session expired'
                    : 'Something went wrong',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _isNetwork
                ? 'Check your connection and try again'
                : _isAuth
                    ? 'Please log in again'
                    : 'Please try again',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              final q = context.read<SearchCubit>().state.submittedQuery;
              if (q.isNotEmpty) {
                context.read<SearchCubit>().submitSearch(q);
              }
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFFF5500)),
            child: const Text('Try again'),
          ),
        ]),
      ),
    );
  }
}

// ── Shared util ───────────────────────────────────────────────────────────────

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}
