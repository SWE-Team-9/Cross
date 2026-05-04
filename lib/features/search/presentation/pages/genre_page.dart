// lib/features/search/presentation/pages/genre_page.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/models/track.dart';
import '../../../search/domain/entities/search_entities.dart';
import '../bloc/genre_cubit.dart';
import '../../domain/entities/genre_entities.dart';
import 'package:soundcloud_clone/core/widgets/track_options_sheet.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ENTRY POINT
// ══════════════════════════════════════════════════════════════════════════════

class GenrePage extends StatelessWidget {
  final String genreLabel;
  final String genreQuery;
  final Color genreColor;

  const GenrePage({
    super.key,
    required this.genreLabel,
    required this.genreQuery,
    required this.genreColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GenreCubit>()..load(genreQuery),
      child: _GenreView(genreLabel: genreLabel, genreColor: genreColor),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN VIEW
// ══════════════════════════════════════════════════════════════════════════════

class _GenreView extends StatefulWidget {
  final String genreLabel;
  final Color genreColor;
  const _GenreView({required this.genreLabel, required this.genreColor});

  @override
  State<_GenreView> createState() => _GenreViewState();
}

class _GenreViewState extends State<_GenreView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _GenreAppBar(
            label: widget.genreLabel,
            color: widget.genreColor,
            forceElevated: innerBoxIsScrolled,
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              color: widget.genreColor,
              tabBar: TabBar(
                controller: _tabs,
                isScrollable: false,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: widget.genreColor, width: 2.5),
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Trending'),
                  Tab(text: 'Playlists'),
                  Tab(text: 'Albums'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _AllTab(
              genreColor: widget.genreColor,
              onSeeAllTrending: () => _tabs.animateTo(1),
              onSeeAllPlaylists: () => _tabs.animateTo(2),
            ),
            const _TrendingTab(),
            const _PlaylistsTab(),
            const _AlbumsTab(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// APP BAR
// ══════════════════════════════════════════════════════════════════════════════

class _GenreAppBar extends StatelessWidget {
  final String label;
  final Color color;
  final bool forceElevated;
  const _GenreAppBar(
      {required this.label, required this.color, required this.forceElevated});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.black,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
              color: Colors.black45, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: BlocBuilder<GenreCubit, GenreState>(
          builder: (context, state) {
            return Stack(
              fit: StackFit.expand,
              children: [
                if (state.headerImageUrl.isNotEmpty)
                  Image.network(state.headerImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _ColorHeader(color: color, label: label))
                else
                  _ColorHeader(color: color, label: label),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ColorHeader extends StatelessWidget {
  final Color color;
  final String label;
  const _ColorHeader({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.5), Colors.black],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB BAR DELEGATE
// ══════════════════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  const _TabBarDelegate({required this.tabBar, required this.color});

  @override
  double get minExtent => tabBar.preferredSize.height + 0.5;
  @override
  double get maxExtent => tabBar.preferredSize.height + 0.5;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: Column(children: [
        tabBar,
        const Divider(color: Colors.white12, height: 0.5, thickness: 0.5),
      ]),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => tabBar != old.tabBar;
}

// ══════════════════════════════════════════════════════════════════════════════
// ALL TAB
// ══════════════════════════════════════════════════════════════════════════════

class _AllTab extends StatelessWidget {
  final Color genreColor;
  final VoidCallback onSeeAllTrending;
  final VoidCallback onSeeAllPlaylists;

  const _AllTab({
    required this.genreColor,
    required this.onSeeAllTrending,
    required this.onSeeAllPlaylists,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenreCubit, GenreState>(
      builder: (context, state) {
        if (state.isLoading) return const _LoadingView();
        if (state.hasError)
          return _ErrorView(onRetry: () => context.read<GenreCubit>().retry());

        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // A) Trending — horizontal, 3 at a time, peek next
            if (state.trending.isNotEmpty) ...[
              _SectionHeader(
                  title: 'Trending',
                  actionLabel: 'See all',
                  onAction: onSeeAllTrending),
              _HorizontalTrendingList(tracks: state.trending),
            ],

            // B) Introducing
            if (state.introducing != null)
              _IntroducingSection(
                featured: state.introducing!,
                extras: state.introducingExtras,
                genreColor: genreColor,
              ),

            // C) Playlists
            if (state.playlists.isNotEmpty) ...[
              _SectionHeader(
                  title: 'Playlists',
                  actionLabel: 'See all',
                  onAction: onSeeAllPlaylists),
              _PlaylistGrid(playlists: state.playlists.take(4).toList()),
            ],

            // D) Profiles
            if (state.profiles.isNotEmpty) ...[
              const _SectionHeader(title: 'Profiles'),
              _HorizontalProfileList(profiles: state.profiles),
            ],

            // E) Discover more
            if (state.discoverMore.isNotEmpty) ...[
              const _SectionHeader(title: 'Discover more tracks'),
              ...state.discoverMore.map((t) => _TrackTile(track: t)),
            ],
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// A) Horizontal Trending  (3 visible + peek)
// ══════════════════════════════════════════════════════════════════════════════

class _HorizontalTrendingList extends StatelessWidget {
  final List<Track> tracks;
  const _HorizontalTrendingList({required this.tracks});

  @override
  Widget build(BuildContext context) {
    final pages = <List<Track>>[];
    for (var i = 0; i < tracks.length; i += 3) {
      pages.add(tracks.sublist(i, (i + 3).clamp(0, tracks.length)));
    }

    final screenW = MediaQuery.of(context).size.width;
    const leftPad = 16.0;
    const peek = 40.0;
    final pageW = screenW - leftPad - peek;

    return SizedBox(
      height: 3 * 72.0 + 8,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: pages.length,
        itemBuilder: (_, i) => SizedBox(
          width: pageW,
          child: Column(
            children: pages[i].map((t) => _CompactTrackTile(track: t)).toList(),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// B) Introducing Section
// ══════════════════════════════════════════════════════════════════════════════

class _IntroducingSection extends StatelessWidget {
  final Track featured;
  final List<Track> extras;
  final Color genreColor;
  const _IntroducingSection(
      {required this.featured, required this.extras, required this.genreColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Introducing'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.hardEdge,
            child: Column(children: [
              _FeaturedCard(track: featured, color: genreColor),
              const Divider(color: Colors.white12, height: 0.5),
              ...extras.take(2).map((t) => _CompactTrackTile(track: t)),
            ]),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Track track;
  final Color color;
  const _FeaturedCard({required this.track, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: track.artworkUrl != null
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Image.network(track.artworkUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: color.withValues(alpha: 0.3))))
              : Container(color: color.withValues(alpha: 0.3)),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cover
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF2A2A2A)),
                child: track.artworkUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(track.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.music_note,
                                color: Colors.white38)))
                    : const Icon(Icons.music_note, color: Colors.white38),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New!',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(track.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(track.artist,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              // Buttons
              Column(children: [
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.favorite_border,
                      color: Colors.white70, size: 22),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.black, size: 22),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TRENDING TAB
// ══════════════════════════════════════════════════════════════════════════════

class _TrendingTab extends StatelessWidget {
  const _TrendingTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenreCubit, GenreState>(
      builder: (context, state) {
        if (state.isLoading) return const _LoadingView();
        if (state.hasError)
          return _ErrorView(onRetry: () => context.read<GenreCubit>().retry());
        if (state.trending.isEmpty)
          return const _EmptyState(
              icon: Icons.trending_up_rounded,
              message: 'No trending tracks yet');

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: state.trending.length,
          itemBuilder: (_, i) => _TrackTile(
            track: state.trending[i],
            leading: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 20,
                child: Text('${i + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: i < 3 ? const Color(0xFFFF5500) : Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PLAYLISTS TAB
// ══════════════════════════════════════════════════════════════════════════════

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenreCubit, GenreState>(
      builder: (context, state) {
        if (state.isLoading) return const _LoadingView();
        if (state.hasError)
          return _ErrorView(onRetry: () => context.read<GenreCubit>().retry());
        if (state.playlists.isEmpty)
          return const _EmptyState(
              icon: Icons.playlist_play_rounded, message: 'No playlists found');

        return GridView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82),
          itemCount: state.playlists.length,
          itemBuilder: (_, i) => _PlaylistCard(playlist: state.playlists[i]),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ALBUMS TAB
// ══════════════════════════════════════════════════════════════════════════════

class _AlbumsTab extends StatelessWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenreCubit, GenreState>(
      builder: (context, state) {
        if (state.isLoading) return const _LoadingView();
        if (state.hasError)
          return _ErrorView(onRetry: () => context.read<GenreCubit>().retry());
        if (state.albums.isEmpty)
          return const _EmptyState(
            icon: Icons.album_outlined,
            message: 'No albums found for this genre',
            subtitle:
                'Double-check your spelling or explore other search keywords.',
          );

        return GridView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78),
          itemCount: state.albums.length,
          itemBuilder: (_, i) => _AlbumCard(album: state.albums[i]),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(actionLabel!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TRACK TILES
// ══════════════════════════════════════════════════════════════════════════════

/// Full-width track row with ⋮ menu
class _TrackTile extends StatelessWidget {
  final Track track;
  final Widget? leading;
  const _TrackTile({required this.track, this.leading});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Row(mainAxisSize: MainAxisSize.min, children: [
        if (leading != null) leading!,
        _Artwork(url: track.artworkUrl, size: 46, radius: 6),
      ]),
      title: Text(track.title,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Row(children: [
        Flexible(
          child: Text(track.artist,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        if ((track.likesCount) > 0) ...[
          const Text(' · ',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          const Icon(Icons.favorite, color: Colors.white38, size: 11),
          const SizedBox(width: 2),
          Text(_fmtCount(track.likesCount),
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
        if (track.durationMs != null && track.durationMs! > 0) ...[
          const Text(' · ',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          Text(_fmtMs(track.durationMs!),
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ]),
      trailing: GestureDetector(
        onTap: () => TrackOptionsSheet.show(context, track: track),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.more_horiz, color: Colors.white38, size: 20),
        ),
      ),
    );
  }
}

/// Compact tile used inside horizontal scroll & Introducing extras
class _CompactTrackTile extends StatelessWidget {
  final Track track;
  const _CompactTrackTile({required this.track});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        leading: _Artwork(url: track.artworkUrl, size: 44, radius: 6),
        title: Text(track.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Row(children: [
          Flexible(
            child: Text(track.artist,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (track.durationMs != null && track.durationMs! > 0) ...[
            const Text(' · ',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            Text(_fmtMs(track.durationMs!),
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ]),
        trailing: GestureDetector(
          onTap: () => TrackOptionsSheet.show(context, track: track),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.more_horiz, color: Colors.white38, size: 18),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PLAYLIST GRID + CARD
// ══════════════════════════════════════════════════════════════════════════════

class _PlaylistGrid extends StatelessWidget {
  final List<PlaylistEntity> playlists;
  const _PlaylistGrid({required this.playlists});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82),
        itemCount: playlists.length,
        itemBuilder: (_, i) => _PlaylistCard(playlist: playlists[i]),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final PlaylistEntity playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.hardEdge,
              child: playlist.artworkUrl.isNotEmpty
                  ? Image.network(playlist.artworkUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.queue_music_rounded,
                          color: Colors.white38,
                          size: 36))
                  : const Center(
                      child: Icon(Icons.queue_music_rounded,
                          color: Colors.white38, size: 36)),
            ),
          ),
          const SizedBox(height: 6),
          Text(playlist.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(playlist.ownerName,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ALBUM CARD
// ══════════════════════════════════════════════════════════════════════════════

class _AlbumCard extends StatelessWidget {
  final AlbumEntity album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.hardEdge,
              child: album.artworkUrl.isNotEmpty
                  ? Image.network(album.artworkUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.album_outlined,
                          color: Colors.white38,
                          size: 36))
                  : const Center(
                      child: Icon(Icons.album_outlined,
                          color: Colors.white38, size: 36)),
            ),
          ),
          const SizedBox(height: 6),
          Text(album.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(album.artistName,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROFILES  (horizontal scroll + Follow button)
// ══════════════════════════════════════════════════════════════════════════════

class _HorizontalProfileList extends StatelessWidget {
  final List<GenreProfileEntity> profiles;
  const _HorizontalProfileList({required this.profiles});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: profiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) => _ProfileCard(profile: profiles[i]),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final GenreProfileEntity profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFF2A2A2A),
          backgroundImage: profile.avatarUrl.isNotEmpty
              ? NetworkImage(profile.avatarUrl)
              : null,
          child: profile.avatarUrl.isEmpty
              ? Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(height: 6),
        Text(profile.displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        _FollowButton(profile: profile),
      ]),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final GenreProfileEntity profile;
  const _FollowButton({required this.profile});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenreCubit, GenreState>(
      builder: (context, state) {
        final following = state.followingIds.contains(profile.id);
        return GestureDetector(
          onTap: () => context.read<GenreCubit>().toggleFollow(profile.id),
          child: Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: following ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color: following ? Colors.white38 : Colors.transparent),
            ),
            child: Center(
              child: Text(
                following ? 'Following' : 'Follow',
                style: TextStyle(
                    color: following ? Colors.white38 : Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ══════════════════════════════════════════════════════════════════════════════

class _Artwork extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;
  final IconData fallback;
  const _Artwork(
      {required this.url,
      required this.size,
      required this.radius,
      // ignore: unused_element_parameter
      this.fallback = Icons.music_note_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(radius)),
      child: url != null && url!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.network(url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(fallback, color: Colors.white38, size: size * 0.46)))
          : Icon(fallback, color: Colors.white38, size: size * 0.46),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(
      child:
          CircularProgressIndicator(color: Color(0xFFFF5500), strokeWidth: 2));
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  const _EmptyState({required this.icon, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Empty Stage!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 52),
          const SizedBox(height: 12),
          const Text('Something went wrong',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onRetry,
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFFF5500)),
            child: const Text('Try again'),
          ),
        ]),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

String _fmtMs(int ms) {
  if (ms <= 0) return '';
  final total = ms ~/ 1000;
  final m = total ~/ 60;
  final s = total % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
