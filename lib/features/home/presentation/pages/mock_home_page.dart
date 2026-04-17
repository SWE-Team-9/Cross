import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '/features/profile/presentation/routes/profile_routes.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/notifiers/overlay_notifiers.dart';
import 'package:soundcloud_clone/core/utils/platform_url_utils.dart';
import 'package:soundcloud_clone/core/widgets/bottom_nav_bar.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';

class MockHomePage extends StatefulWidget {
  const MockHomePage({super.key});

  @override
  State<MockHomePage> createState() => _MockHomePageState();
}

class _MockHomePageState extends State<MockHomePage> {
  int _selectedTab = 0;
  String _selectedGenre = 'ELECTRONIC';
  bool _isLoadingTrending = false;
  String? _trendingError;
  List<dynamic>? _trendingRawTrackPool;
  Future<List<dynamic>>? _trendingRawTrackPoolRequest;
  List<Track> _trendingTracks = const <Track>[];

  final _genres = const [
    'ELECTRONIC',
    'FOLK',
    'HOUSE',
    'TECHNO',
    'POP',
    'HIP-HOP',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrendingTracks();
  }

  Future<void> _loadTrendingTracks() async {
    setState(() {
      _isLoadingTrending = true;
      _trendingError = null;
    });

    try {
      final rawList = await _getTrendingRawTrackPool();
      final tracks = _buildTrendingTracksForSelectedGenre(rawList);

      if (!mounted) return;
      setState(() {
        _trendingRawTrackPool = rawList;
        _trendingTracks = tracks;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trendingError = 'Failed to load genre tracks';
        _trendingTracks = const <Track>[];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingTrending = false;
      });
    }
  }

  void _filterCachedTrendingTracks() {
    final rawList = _trendingRawTrackPool;
    if (rawList == null) {
      if (!_isLoadingTrending) {
        _loadTrendingTracks();
      }
      return;
    }

    setState(() {
      _trendingError = null;
      _trendingTracks = _buildTrendingTracksForSelectedGenre(rawList);
    });
  }

  List<Track> _buildTrendingTracksForSelectedGenre(List<dynamic> rawList) {
    final trackLikeRawList = rawList
        .where(_looksLikeTrackPayload)
        .where(_isDiscoverableTrackPayload)
        .toList(growable: false);
    final genreMatched = trackLikeRawList
        .where((raw) => _rawMatchesGenre(raw, _selectedGenre))
        .toList(growable: false);
    final filteredRawList =
        genreMatched.isEmpty ? trackLikeRawList : genreMatched;

    return filteredRawList
        .map(_mapToTrack)
        .whereType<Track>()
        .toList(growable: false)
      ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
  }

  Future<List<dynamic>> _getTrendingRawTrackPool() {
    final cached = _trendingRawTrackPool;
    if (cached != null) return Future.value(cached);

    final inFlight = _trendingRawTrackPoolRequest;
    if (inFlight != null) return inFlight;

    final request = _fetchTrendingRawTracks().whenComplete(() {
      _trendingRawTrackPoolRequest = null;
    });
    _trendingRawTrackPoolRequest = request;
    return request;
  }

  bool _looksLikeTrackPayload(dynamic raw) {
    if (raw is! Map) return false;
    final map = Map<String, dynamic>.from(raw);
    final nestedTrack = map['track'];
    if (nestedTrack is Map) return true;
    return map.containsKey('title') ||
        map.containsKey('genre') ||
        map.containsKey('coverArtUrl') ||
        map.containsKey('duration');
  }

  bool _isDiscoverableTrackPayload(dynamic raw) {
    if (raw is! Map) return false;
    final map = Map<String, dynamic>.from(raw);
    final nestedTrack = map['track'];
    final source =
        nestedTrack is Map ? Map<String, dynamic>.from(nestedTrack) : map;

    final visibility = (source['visibility'] ?? '').toString().toUpperCase();
    if (visibility == 'PRIVATE') return false;

    final status = (source['status'] ?? '').toString().toUpperCase();
    if (status == 'PROCESSING' || status == 'FAILED') return false;

    return true;
  }

  Future<List<dynamic>> _fetchTrendingRawTracks() async {
    final dioClient = GetIt.I<DioClient>();
    final authState = context.read<AuthCubit>().state;
    final String viewerId =
        authState is AuthAuthenticated ? authState.user.id.trim() : '';
    final List<dynamic> collected = <dynamic>[];
    final Set<String> seenTrackIds = <String>{};
    final Set<String> userIdsToLoad = <String>{};

    void addTracks(Iterable<dynamic> tracks) {
      for (final raw in tracks) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final nestedTrack = map['track'];
        final source =
            nestedTrack is Map ? Map<String, dynamic>.from(nestedTrack) : map;
        final id =
            (source['id'] ?? source['trackId'] ?? source['track_id'] ?? '')
                .toString()
                .trim();
        if (id.isEmpty || seenTrackIds.contains(id)) continue;
        seenTrackIds.add(id);
        collected.add(raw);
      }
    }

    if (viewerId.isNotEmpty) {
      userIdsToLoad.add(viewerId);

      try {
        final followingResponse = await dioClient.get(
          ApiConstants.followingPath(viewerId),
          queryParameters: const <String, dynamic>{'page': 1, 'limit': 100},
        );
        userIdsToLoad.addAll(_extractUserIds(followingResponse.data));
      } catch (_) {}
    }

    for (final userId in userIdsToLoad.take(10)) {
      try {
        final response = await dioClient.get(
          ApiConstants.userTracksPath(userId),
          queryParameters: const <String, dynamic>{
            'page': 1,
            'limit': 20,
          },
        );
        addTracks(_extractTracksList(response.data));
      } catch (_) {}

      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    return collected;
  }

  List<String> _extractUserIds(dynamic responseData) {
    final List<dynamic> rawUsers = <dynamic>[
      if (responseData is Map<String, dynamic>) ...[
        ...(responseData['following'] is List
            ? responseData['following'] as List
            : const <dynamic>[]),
        ...(responseData['followers'] is List
            ? responseData['followers'] as List
            : const <dynamic>[]),
        ...(responseData['users'] is List
            ? responseData['users'] as List
            : const <dynamic>[]),
        ...(responseData['items'] is List
            ? responseData['items'] as List
            : const <dynamic>[]),
        ...(responseData['results'] is List
            ? responseData['results'] as List
            : const <dynamic>[]),
        if (responseData['data'] is List) ...(responseData['data'] as List),
      ] else if (responseData is List)
        ...responseData,
    ];

    return rawUsers
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .map(
          (item) => (item['id'] ?? item['userId'] ?? item['user_id'] ?? '')
              .toString(),
        )
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  List<dynamic> _extractTracksList(dynamic responseData) {
    if (responseData is List) return responseData;
    if (responseData is Map<String, dynamic>) {
      final dynamic directTracks = responseData['tracks'] ??
          responseData['items'] ??
          responseData['results'] ??
          responseData['collection'];
      if (directTracks is List) return directTracks;

      final dynamic data = responseData['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final dynamic nestedTracks = data['tracks'] ??
            data['items'] ??
            data['results'] ??
            data['collection'];
        if (nestedTracks is List) return nestedTracks;
      }
    }
    return const <dynamic>[];
  }

  Track? _mapToTrack(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final nestedTrack = map['track'];
    final source =
        nestedTrack is Map ? Map<String, dynamic>.from(nestedTrack) : map;

    final id = (source['id'] ?? source['trackId'] ?? source['track_id'] ?? '')
        .toString()
        .trim();
    if (id.isEmpty) return null;

    final uploader = source['uploader'] ?? source['artist'] ?? source['owner'];
    final uploaderMap = uploader is Map
        ? Map<String, dynamic>.from(uploader)
        : <String, dynamic>{};

    final statsRaw = source['stats'];
    final stats = statsRaw is Map
        ? Map<String, dynamic>.from(statsRaw)
        : <String, dynamic>{};

    final likesCount = _asInt(
      source['likesCount'] ?? source['likes_count'] ?? stats['likesCount'],
    );
    final repostsCount = _asInt(
      source['repostsCount'] ??
          source['reposts_count'] ??
          stats['repostsCount'],
    );

    return Track(
      id: id,
      title: (source['title'] ?? 'Untitled').toString(),
      artist: (uploaderMap['displayName'] ??
              uploaderMap['username'] ??
              source['artistName'] ??
              source['artist'] ??
              'Unknown artist')
          .toString(),
      audioUrl: (source['streamUrl'] ?? source['audioUrl'] ?? '').toString(),
      artworkUrl: (source['coverArtUrl'] ??
              source['cover_art_url'] ??
              source['artworkUrl'])
          ?.toString(),
      handle: (uploaderMap['handle'] ?? uploaderMap['username'] ?? '')
          .toString()
          .trim(),
      likesCount: likesCount,
      repostsCount: repostsCount,
    );
  }

  bool _rawMatchesGenre(dynamic raw, String selectedGenre) {
    if (raw is! Map) return false;
    final map = Map<String, dynamic>.from(raw);
    final nestedTrack = map['track'];
    final source =
        nestedTrack is Map ? Map<String, dynamic>.from(nestedTrack) : map;

    final genreValue = source['genre'];
    String resolvedGenre = '';
    if (genreValue is String) {
      resolvedGenre = genreValue;
    } else if (genreValue is Map) {
      final typedGenre = Map<String, dynamic>.from(genreValue);
      resolvedGenre = (typedGenre['name'] ?? '').toString();
    } else {
      resolvedGenre =
          (source['genreName'] ?? source['genre_name'] ?? '').toString();
    }

    if (resolvedGenre.trim().isEmpty) return false;

    final normalizedResolved = _normalizeGenreToken(resolvedGenre);
    final normalizedSelected = _normalizeGenreToken(selectedGenre);
    return normalizedResolved == normalizedSelected;
  }

  String _normalizeGenreToken(String value) {
    final upper = value.trim().toUpperCase();
    if (upper.isEmpty) return upper;

    final compact = upper.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (compact == 'HIPHOP') return 'HIPHOP';
    return compact;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/welcome');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        String currentHandle = '';
        if (state is AuthAuthenticated) {
          currentHandle = state.user.handle;
        }

        return Scaffold(
          backgroundColor: Colors.black,
          // ── Bottom Nav ──────────────────────────────────────────────────
          bottomNavigationBar: BottomNavBar(
            selected: _selectedTab,
            onTap: (i) {
              setState(() => _selectedTab = i);
              switch (i) {
                case 0:
                  break;
                case 1:
                  context.go('/feed');
                  break;
                case 2:
                  context.go('/search');
                  break;
                case 3:
                  context.go('/library');
                  break;
                case 4:
                  context.go('/upgrade');
                  break;
              }
            },
          ),
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  currentUserHandle: currentHandle,
                  authState: state,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'More of what you like'),
                        const _RelatedTracksRow(),
                        const _SectionHeader(title: 'Mixed for you'),
                        _MixesRow(userHandle: currentHandle),
                        const _SectionHeader(title: 'Trending by genre'),
                        _GenreChips(
                          genres: _genres,
                          selected: _selectedGenre,
                          onSelect: (g) {
                            setState(() => _selectedGenre = g);
                            _filterCachedTrendingTracks();
                          },
                        ),
                        _TrendingByGenreTracks(
                          loading: _isLoadingTrending,
                          error: _trendingError,
                          tracks: _trendingTracks,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrendingByGenreTracks extends StatelessWidget {
  const _TrendingByGenreTracks({
    required this.loading,
    required this.error,
    required this.tracks,
  });

  final bool loading;
  final String? error;
  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5500)),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Text(
          error!,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    if (tracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Text(
          'No tracks found for this genre',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final visibleTracks = tracks.take(10).toList(growable: false);

    return Column(
      children: visibleTracks
          .map(
            (track) => TrackRow(
              track: track,
              queue: visibleTracks,
              source: 'home_trending',
              showLikesCount: true,
            ),
          )
          .toList(growable: false),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String currentUserHandle;
  final AuthState authState;

  const _TopBar({
    required this.currentUserHandle,
    required this.authState,
  });

  void _showLogoutSheet(BuildContext context) {
    isTrackSheetOpen.value = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Log out of Iqa3?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5500),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(bContext);
                    context.read<AuthCubit>().logout();
                  },
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(bContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      isTrackSheetOpen.value = false;
    });
  }

  void _navigateToProfile(BuildContext context) {
    if (currentUserHandle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to view profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ProfileRoutes.goToProfile(context, currentUserHandle);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 8),
      child: Row(
        children: [
          const Text(
            'Home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'GET PRO',
            style: TextStyle(
              color: Color(0xFFFF5500),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (authState is AuthAuthenticated)
            _IconBtn(
              icon: Icons.logout_rounded,
              onTap: () => _showLogoutSheet(context),
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: Builder(
              builder: (_) {
                String? avatarUrl;
                String fallbackText = '?';

                if (authState is AuthAuthenticated) {
                  final user = (authState as AuthAuthenticated).user;
                  avatarUrl = user.avatarUrl;
                  fallbackText = user.handle.isNotEmpty
                      ? user.handle.substring(0, 1).toUpperCase()
                      : '?';
                } else if (currentUserHandle.isNotEmpty) {
                  fallbackText =
                      currentUserHandle.substring(0, 1).toUpperCase();
                }

                final normalizedAvatarUrl =
                    PlatformUrlUtils.normalizeBackendUrl(avatarUrl);

                return CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFFF5500),
                  backgroundImage: normalizedAvatarUrl != null
                      ? NetworkImage(normalizedAvatarUrl)
                      : null,
                  child: normalizedAvatarUrl == null
                      ? Text(
                          fallbackText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          _IconBtn(icon: Icons.cast, onTap: () {}),
          _IconBtn(
            icon: Icons.upload_outlined,
            onTap: () => context.push('/upload-picker'),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RelatedTracksRow extends StatelessWidget {
  const _RelatedTracksRow();

  void _navigateToProfile(BuildContext context, String handle) {
    if (handle.isNotEmpty) {
      ProfileRoutes.goToProfile(context, handle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      const _AlbumData(
        label: 'Related tracks: L...',
        sub: 'SoundCloud',
        handle: 'sc1',
        topText: 'Cage\nThe\nElephant',
        color1: Color(0xFF1a1a2e),
        color2: Color(0xFF16213e),
      ),
      const _AlbumData(
        label: 'Related tracks: E...',
        sub: 'SoundCloud',
        handle: 'sc2',
        topText: 'THE\nStrokes',
        color1: Color(0xFF2d1b2e),
        color2: Color(0xFF8b1a1a),
      ),
      const _AlbumData(
        label: 'Related tracks: A...',
        sub: 'SoundCloud',
        handle: 'sc3',
        topText: 'ARABIC\nARTISTS',
        color1: Color(0xFF2a2a1a),
        color2: Color(0xFF1a2a1a),
      ),
    ];

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = cards[i];
          return GestureDetector(
            onTap: () => _navigateToProfile(context, c.handle),
            child: SizedBox(
              width: 148,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(colors: [c.color1, c.color2]),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c.topText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    c.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MixesRow extends StatelessWidget {
  final String userHandle;

  const _MixesRow({required this.userHandle});

  void _navigateToProfile(BuildContext context) {
    if (userHandle.isNotEmpty) {
      ProfileRoutes.goToProfile(context, userHandle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mixes = [
      const _MixData(
        label: 'MIX 1',
        sub: 'Balthazar, Cage...',
        badgeColor: Color(0xFF8250C8),
        color1: Color(0xFF1a1a1a),
        color2: Color(0xFF2d1b2e),
      ),
      const _MixData(
        label: 'MIX 2',
        sub: 'Arctic Monkeys...',
        badgeColor: Color(0xFF1E64C8),
        color1: Color(0xFF0d1b2a),
        color2: Color(0xFF1a3a2a),
      ),
      const _MixData(
        label: 'MIX 3',
        sub: 'The Weeknd, Drake...',
        badgeColor: Color(0x66CCCCCC),
        color1: Color(0xFF2d1b2e),
        color2: Color(0xFF6b2d4a),
      ),
    ];

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: mixes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = mixes[i];
          return GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: SizedBox(
              width: 148,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [m.color1, m.color2],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: m.badgeColor,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            m.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    m.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GenreChips extends StatelessWidget {
  final List<String> genres;
  final String selected;
  final ValueChanged<String> onSelect;

  const _GenreChips({
    required this.genres,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final g = genres[i];
          final active = g == selected;
          return GestureDetector(
            onTap: () => onSelect(g),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? const Color(0xFFFF5500)
                      : const Color(0xFF444444),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                g,
                style: TextStyle(
                  color: active ? const Color(0xFFFF5500) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _AlbumData {
  final String label, sub, handle, topText;
  final Color color1, color2;

  const _AlbumData({
    required this.label,
    required this.sub,
    required this.handle,
    required this.topText,
    required this.color1,
    required this.color2,
  });
}

class _MixData {
  final String label, sub;
  final Color badgeColor, color1, color2;

  const _MixData({
    required this.label,
    required this.sub,
    required this.badgeColor,
    required this.color1,
    required this.color2,
  });
}
