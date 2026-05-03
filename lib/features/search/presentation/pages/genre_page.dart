import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/models/track.dart';
import '../../../../core/widgets/track_options_sheet.dart';
import '../../domain/entities/genre_entities.dart';
import '../../domain/entities/search_entities.dart';
import '../bloc/genre_cubit.dart';

class GenrePage extends StatelessWidget {
  const GenrePage({
    super.key,
    required this.genreSlug,
    required this.genreLabel,
  });

  final String genreSlug;
  final String genreLabel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GenreCubit>(
      create: (_) => getIt<GenreCubit>()..load(genreSlug),
      child: _GenreView(
        genreSlug: genreSlug,
        genreLabel: genreLabel,
      ),
    );
  }
}

class _GenreView extends StatelessWidget {
  const _GenreView({
    required this.genreSlug,
    required this.genreLabel,
  });

  final String genreSlug;
  final String genreLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          genreLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocBuilder<GenreCubit, GenreState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF5500),
              ),
            );
          }

          if (state.hasError) {
            return _ErrorView(
              onRetry: () => context.read<GenreCubit>().retry(),
            );
          }

          if (state.trending.isEmpty &&
              state.playlists.isEmpty &&
              state.profiles.isEmpty &&
              state.discoverMore.isEmpty) {
            return _EmptyView(genreLabel: genreLabel);
          }

          return RefreshIndicator(
            color: const Color(0xFFFF5500),
            backgroundColor: const Color(0xFF1C1C1C),
            onRefresh: () => context.read<GenreCubit>().load(genreSlug),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                if (state.trending.isNotEmpty) ...[
                  const _SectionTitle('Trending tracks'),
                  ...state.trending.asMap().entries.map(
                        (entry) => _TrackTile(
                          index: entry.key + 1,
                          track: entry.value,
                        ),
                      ),
                  const SizedBox(height: 20),
                ],
                if (state.introducing != null) ...[
                  const _SectionTitle('Introducing'),
                  _FeaturedTrackCard(track: state.introducing!),
                  if (state.introducingExtras.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...state.introducingExtras.map(
                      (track) => _TrackTile(track: track),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
                if (state.playlists.isNotEmpty) ...[
                  const _SectionTitle('Playlists'),
                  _PlaylistGrid(playlists: state.playlists),
                  const SizedBox(height: 20),
                ],
                if (state.profiles.isNotEmpty) ...[
                  const _SectionTitle('Profiles'),
                  _ProfilesList(
                    profiles: state.profiles,
                    followingIds: state.followingIds,
                  ),
                  const SizedBox(height: 20),
                ],
                if (state.discoverMore.isNotEmpty) ...[
                  const _SectionTitle('Discover more'),
                  ...state.discoverMore.map(
                    (track) => _TrackTile(track: track),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    this.index,
  });

  final Track track;
  final int? index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (index != null)
            SizedBox(
              width: 28,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: index! <= 3 ? const Color(0xFFFF5500) : Colors.white38,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          _Artwork(url: track.artworkUrl, size: 52),
        ],
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        [
          track.artist,
          if (track.genre != null && track.genre!.isNotEmpty) track.genre!,
        ].where((value) => value.isNotEmpty).join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz, color: Colors.white54),
        onPressed: () => TrackOptionsSheet.show(context, track: track),
      ),
    );
  }
}

class _FeaturedTrackCard extends StatelessWidget {
  const _FeaturedTrackCard({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TrackOptionsSheet.show(context, track: track),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            _Artwork(url: track.artworkUrl, size: 76),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top pick',
                    style: TextStyle(
                      color: Color(0xFFFF5500),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 34),
          ],
        ),
      ),
    );
  }
}

class _PlaylistGrid extends StatelessWidget {
  const _PlaylistGrid({required this.playlists});

  final List<PlaylistEntity> playlists;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: playlists.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        return _PlaylistCard(playlist: playlists[index]);
      },
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist});

  final PlaylistEntity playlist;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: playlist.artworkUrl.isNotEmpty
                ? Image.network(
                    playlist.artworkUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _PlaylistFallback(),
                  )
                : const _PlaylistFallback(),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              playlist.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Text(
              '${playlist.trackCount} tracks',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistFallback extends StatelessWidget {
  const _PlaylistFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF242424),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          color: Colors.white38,
          size: 40,
        ),
      ),
    );
  }
}

class _ProfilesList extends StatelessWidget {
  const _ProfilesList({
    required this.profiles,
    required this.followingIds,
  });

  final List<GenreProfileEntity> profiles;
  final Set<String> followingIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: profiles.map((profile) {
        final isFollowing = followingIds.contains(profile.id);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF2A2A2A),
            backgroundImage: profile.avatarUrl.isNotEmpty
                ? NetworkImage(profile.avatarUrl)
                : null,
            child: profile.avatarUrl.isEmpty
                ? Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          title: Text(
            profile.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '@${profile.username}',
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: OutlinedButton(
            onPressed: () =>
                context.read<GenreCubit>().toggleFollow(profile.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(isFollowing ? 'Following' : 'Follow'),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.url,
    required this.size,
  });

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.music_note,
                color: Colors.white38,
              ),
            )
          : const Icon(
              Icons.music_note,
              color: Colors.white38,
            ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white38, size: 54),
            const SizedBox(height: 12),
            const Text(
              'Could not load this genre.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.genreLabel});

  final String genreLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up, color: Colors.white38, size: 54),
            const SizedBox(height: 12),
            Text(
              'No $genreLabel tracks yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try another genre or check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
