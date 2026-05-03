// lib/features/search/presentation/pages/search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/models/track.dart';
import '../../../search/domain/entities/search_entities.dart';
import '../bloc/search_cubit.dart';
import '/core/widgets/track_options_sheet.dart';
import '../../../../core/di/injector.dart';
import '../../../social/data/repositories/social_repo.dart';
import '../../../social/domain/events/social_events.dart';
import '../../../playback/presentation/bloc/player_cubit.dart';
import 'genre_page.dart'; // ← import GenrePage

// ══════════════════════════════════════════════════════════════════════════════
// GENRES
// ══════════════════════════════════════════════════════════════════════════════

const _kGenres = [
  _Genre(
      'Electronic', Color(0xFFDB2777), Icons.graphic_eq_rounded, 'electronic'),
  _Genre('Hip-Hop', Color(0xFF7C3AED), Icons.mic_none_rounded, 'hip-hop'),
  _Genre('Pop', Color(0xFFCA8A04), Icons.star_outline_rounded, 'pop'),
  _Genre('Rock', Color(0xFFEA580C), Icons.electric_bolt_rounded, 'rock'),
  _Genre('Alternative', Color(0xFF0891B2), Icons.album_outlined, 'alternative'),
  _Genre('Ambient', Color(0xFF2563EB), Icons.cloud_queue_rounded, 'ambient'),
  _Genre('Classical', Color(0xFF7C3AED), Icons.piano_rounded, 'classical'),
  _Genre('Jazz', Color(0xFFCA8A04), Icons.queue_music_rounded, 'jazz'),
  _Genre('R&B / Soul', Color(0xFF0891B2), Icons.favorite_border_rounded,
      'r-b-soul'),
  _Genre('Metal', Color(0xFFEA580C), Icons.electric_bolt_rounded, 'metal'),
  _Genre('Folk', Color(0xFFEA580C), Icons.music_note_rounded,
      'folk-singer-songwriter'),
  _Genre('Country', Color(0xFFCA8A04), Icons.queue_music_rounded, 'country'),
  _Genre('Reggaeton', Color(0xFFDB2777), Icons.nightlife_rounded, 'reggaeton'),
  _Genre(
      'Dancehall', Color(0xFFDB2777), Icons.celebration_outlined, 'dancehall'),
  _Genre('Drum & Bass', Color(0xFF7C3AED), Icons.blur_on_rounded, 'drum-bass'),
  _Genre('House', Color(0xFFDB2777), Icons.speaker_rounded, 'house'),
  _Genre('Techno', Color(0xFFDB2777), Icons.blur_on_rounded, 'techno'),
  _Genre('Deep House', Color(0xFF2563EB), Icons.speaker_rounded, 'deep-house'),
  _Genre('Trance', Color(0xFF7C3AED), Icons.graphic_eq_rounded, 'trance'),
  _Genre('Lo-Fi', Color(0xFF0891B2), Icons.cloud_queue_rounded, 'lo-fi'),
  _Genre('Indie', Color(0xFF2563EB), Icons.album_outlined, 'indie'),
  _Genre('Punk', Color(0xFFEA580C), Icons.electric_bolt_rounded, 'punk'),
  _Genre('Blues', Color(0xFF0891B2), Icons.piano_rounded, 'blues'),
  _Genre('Latin', Color(0xFFDB2777), Icons.nightlife_rounded, 'latin'),
  _Genre('Afrobeat', Color(0xFFCA8A04), Icons.celebration_outlined, 'afrobeat'),
  _Genre('Trap', Color(0xFF7C3AED), Icons.mic_none_rounded, 'trap'),
  _Genre('Experimental', Color(0xFFDB2777), Icons.science_outlined,
      'experimental'),
  _Genre('World', Color(0xFF16A34A), Icons.public_rounded, 'world'),
  _Genre('Gospel', Color(0xFFCA8A04), Icons.church_outlined, 'gospel'),
  _Genre('Spoken Word', Color(0xFF0891B2), Icons.record_voice_over_rounded,
      'spoken-word'),
  _Genre('Quran', Color(0xFF16A34A), Icons.menu_book_rounded, 'quran'),
  _Genre('Sha3by', Color(0xFFEA580C), Icons.queue_music_rounded, 'sha3by'),
  _Genre(
      'Islamic', Color(0xFF16A34A), Icons.self_improvement_rounded, 'islamic'),
];

class _Genre {
  final String label;
  final Color color;
  final IconData icon;
  final String queryValue;
  const _Genre(this.label, this.color, this.icon, this.queryValue);
}

// ══════════════════════════════════════════════════════════════════════════════
// SearchPage — idle / genre grid
// ══════════════════════════════════════════════════════════════════════════════

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const BottomNavBar(selected: 2),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push('/search/active'),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1C),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 14),
                            Icon(Icons.search, color: Colors.white54, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Search',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.cast_outlined,
                        color: Colors.white54, size: 22),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _GenreGrid(
                // ↓ الآن يفتح GenrePage مباشرة بدل /search/active
                onGenreTap: (genre) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GenrePage(
                      genreLabel: genre.label,
                      genreQuery: genre.queryValue,
                      genreColor: genre.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreGrid extends StatelessWidget {
  final ValueChanged<_Genre> onGenreTap;
  const _GenreGrid({required this.onGenreTap});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Vibes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _GenreCard(
                genre: _kGenres[i],
                onTap: () => onGenreTap(_kGenres[i]),
              ),
              childCount: _kGenres.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _GenreCard extends StatelessWidget {
  final _Genre genre;
  final VoidCallback onTap;
  const _GenreCard({required this.genre, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: genre.color.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      genre.color.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 50, 10),
              child: Text(
                genre.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              right: 10,
              bottom: 8,
              child: Icon(genre.icon, color: genre.color, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SearchActivePage
// ══════════════════════════════════════════════════════════════════════════════

class SearchActivePage extends StatelessWidget {
  final String? initialQuery;
  const SearchActivePage({super.key, this.initialQuery});

  @override
  Widget build(BuildContext context) {
    if (initialQuery != null && initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<SearchCubit>().submitSearch(initialQuery!);
        }
      });
    }
    return _SearchActiveView(initialQuery: initialQuery);
  }
}

class _SearchActiveView extends StatefulWidget {
  final String? initialQuery;
  const _SearchActiveView({this.initialQuery});

  @override
  State<_SearchActiveView> createState() => _SearchActiveViewState();
}

class _SearchActiveViewState extends State<_SearchActiveView>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final TabController _tabController;
  final _scrollController = ScrollController();

  static const _tabTracks = 1;
  static const _tabProfiles = 2;
  static const _tabPlaylists = 3;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    if (widget.initialQuery == null || widget.initialQuery!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        final cubit = context.read<SearchCubit>();
        if (cubit.state.submittedQuery.isNotEmpty) {
          cubit.onQueryChanged(_controller.text);
        }
      }
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = switch (_tabController.index) {
      _tabTracks => SearchTab.tracks,
      _tabProfiles => SearchTab.people,
      _tabPlaylists => SearchTab.playlists,
      _ => SearchTab.all,
    };
    context.read<SearchCubit>().onTabChanged(tab);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<SearchCubit>().loadNextPage();
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goBack() {
    _focusNode.unfocus();
    if (context.canPop())
      context.pop();
    else
      context.go('/search');
  }

  void _pickQuery(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _focusNode.unfocus();
    context.read<SearchCubit>().submitSearch(query);
  }

  void _submit() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    _focusNode.unfocus();
    context.read<SearchCubit>().submitSearch(q);
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        bottomNavigationBar: keyboardOpen
            ? null
            : BottomNavBar(
                selected: 2,
                onTap: (i) {
                  _focusNode.unfocus();
                  if (i == 2) {
                    _goBack();
                    return;
                  }
                  const routes = [
                    '/home',
                    '/feed',
                    '/search',
                    '/library',
                    '/upgrade'
                  ];
                  context.go(routes[i]);
                },
              ),
        body: SafeArea(
          child: Column(
            children: [
              _ActiveSearchBar(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (v) => context.read<SearchCubit>().onQueryChanged(v),
                onSubmit: (_) => _submit(),
                onClear: () {
                  _controller.clear();
                  context.read<SearchCubit>().onQueryChanged('');
                  _focusNode.requestFocus();
                },
                onBack: _goBack,
              ),
              Expanded(
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) {
                    return switch (state.bodyMode) {
                      SearchBodyMode.idle => const _IdleHint(),
                      SearchBodyMode.recents => _RecentsPanel(
                          recents: state.recentSearches,
                          onTap: _pickQuery,
                          onRemove: (q) =>
                              context.read<SearchCubit>().removeRecent(q),
                          onClearAll: () =>
                              context.read<SearchCubit>().clearRecents(),
                        ),
                      SearchBodyMode.suggestions => _SuggestionsPanel(
                          query: state.typingQuery,
                          suggestions: state.suggestions,
                          isLoading: state.isSuggestionsLoading,
                          onTap: _pickQuery,
                        ),
                      SearchBodyMode.loading => const _SearchShimmer(),
                      SearchBodyMode.failure => _ErrorView(
                          onRetry: () => context
                              .read<SearchCubit>()
                              .submitSearch(state.submittedQuery),
                        ),
                      SearchBodyMode.empty =>
                        _EmptyResults(query: state.submittedQuery),
                      SearchBodyMode.results => Column(
                          children: [
                            _SearchTabBar(
                              controller: _tabController,
                              state: state,
                            ),
                            Expanded(
                              child: _ResultsView(
                                state: state,
                                tabController: _tabController,
                                scrollController: _scrollController,
                              ),
                            ),
                          ],
                        ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ══════════════════════════════════════════════════════════════════════════════

class _ActiveSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;
  final VoidCallback onBack;

  const _ActiveSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: onBack,
          ),
          Expanded(
            child: Container(
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
                      onSubmitted: onSubmit,
                      textInputAction: TextInputAction.search,
                      textAlign: TextAlign.start,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle:
                            TextStyle(color: Colors.white38, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
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
                          child: Icon(Icons.close,
                              color: Colors.white54, size: 18),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.cast_outlined, color: Colors.white54, size: 22),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// RECENTS PANEL
// ══════════════════════════════════════════════════════════════════════════════

class _RecentsPanel extends StatelessWidget {
  final List<String> recents;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  const _RecentsPanel({
    required this.recents,
    required this.onTap,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text('Recent searches',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: onClearAll,
                child: const Text('Clear all',
                    style: TextStyle(
                        color: Color(0xFFFF5500),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recents.length,
            itemBuilder: (_, i) {
              final q = recents[i];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading:
                    const Icon(Icons.history, color: Colors.white38, size: 20),
                title: Text(q,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400)),
                trailing: GestureDetector(
                  onTap: () => onRemove(q),
                  child:
                      const Icon(Icons.close, color: Colors.white38, size: 18),
                ),
                onTap: () => onTap(q),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUGGESTIONS PANEL
// ══════════════════════════════════════════════════════════════════════════════

class _SuggestionsPanel extends StatelessWidget {
  final String query;
  final List<String> suggestions;
  final bool isLoading;
  final ValueChanged<String> onTap;

  const _SuggestionsPanel({
    required this.query,
    required this.suggestions,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && suggestions.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFFF5500)),
        ),
      );
    }

    final items = suggestions.isEmpty ? [query] : suggestions;

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final s = items[i];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            i == 0 ? Icons.search : Icons.trending_up_rounded,
            color: i == 0 ? const Color(0xFFFF5500) : Colors.white38,
            size: 18,
          ),
          title: Text(s,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400)),
          onTap: () => onTap(s),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB BAR
// ══════════════════════════════════════════════════════════════════════════════

class _SearchTabBar extends StatelessWidget {
  final TabController controller;
  final SearchState state;
  const _SearchTabBar({required this.controller, required this.state});

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
// RESULTS VIEW
// ══════════════════════════════════════════════════════════════════════════════

class _ResultsView extends StatelessWidget {
  final SearchState state;
  final TabController tabController;
  final ScrollController scrollController;

  const _ResultsView({
    required this.state,
    required this.tabController,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        _AllTab(state: state, scrollController: scrollController),
        _ListTab(
          isEmpty: state.tracks.isEmpty,
          emptyIcon: Icons.music_off_rounded,
          emptyMsg: 'No tracks found for "${state.submittedQuery}"',
          itemCount: state.tracks.length,
          scrollController: scrollController,
          isLoadingMore: state.isLoadingMore,
          itemBuilder: (_, i) => _TrackTile(track: state.tracks[i]),
        ),
        _ListTab(
          isEmpty: state.users.isEmpty,
          emptyIcon: Icons.person_off_rounded,
          emptyMsg: 'No profiles found for "${state.submittedQuery}"',
          itemCount: state.users.length,
          scrollController: scrollController,
          isLoadingMore: state.isLoadingMore,
          itemBuilder: (_, i) => _UserTile(user: state.users[i]),
        ),
        _ListTab(
          isEmpty: state.playlists.isEmpty,
          emptyIcon: Icons.playlist_remove_rounded,
          emptyMsg: 'No playlists found for "${state.submittedQuery}"',
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
    final topTrack = state.tracks.isNotEmpty ? state.tracks.first : null;
    final topUser = state.users.isNotEmpty ? state.users.first : null;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        if (topTrack != null || topUser != null) ...[
          const _SliverHeader(title: 'Top Result'),
          SliverToBoxAdapter(
            child: topTrack != null
                ? _TopResultTile(track: topTrack)
                : _TopUserTile(user: topUser!),
          ),
        ],
        if (state.tracks.isNotEmpty) ...[
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

// ── Top result — Track ────────────────────────────────────────────────────────

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
            Text(_fmtCount(track.playbackCount),
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const Text(' · ',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text(track.formattedDuration,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
            onPressed: () => _openOptions(context, track),
          ),
          onTap: () => getIt<PlayerCubit>().play(_toTrack(track)),
        ),
      ),
    );
  }
}

// ── Top result — User ─────────────────────────────────────────────────────────

class _TopUserTile extends StatelessWidget {
  final UserEntity user;
  const _TopUserTile({required this.user});

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
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF2A2A2A),
            backgroundImage:
                user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
            child: user.avatarUrl.isEmpty
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700))
                : null,
          ),
          title: Row(children: [
            Flexible(
              child: Text(user.displayName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (user.verified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded,
                  color: Color(0xFFFF5500), size: 15),
            ],
          ]),
          subtitle: Text('@${user.username}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: _FollowButton(
            userId: user.id,
            initialIsFollowing: user.isFollowing,
          ),
          onTap: () => context.push('/profile/${user.username}'),
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
          Text(_fmtCount(track.playbackCount),
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ]),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
        onPressed: () => _openOptions(context, track),
      ),
      onTap: () => getIt<PlayerCubit>().play(_toTrack(track)),
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
      trailing: _FollowButton(
        userId: user.id,
        initialIsFollowing: user.isFollowing,
      ),
      onTap: () => context.push('/profile/${user.username}'),
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
      trailing: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
      onTap: () => context.push('/playlist/${playlist.id}'),
    );
  }
}

// ── Follow Button ─────────────────────────────────────────────────────────────

class _FollowButton extends StatefulWidget {
  final String userId;
  final bool initialIsFollowing;
  const _FollowButton({
    required this.userId,
    required this.initialIsFollowing,
  });

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  late bool _isFollowing;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initialIsFollowing;
  }

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _isFollowing = !_isFollowing;
    });

    try {
      final repo = getIt<SocialRepo>();
      if (_isFollowing) {
        await repo.followUser(widget.userId);
      } else {
        await repo.unfollowUser(widget.userId);
      }
      SocialEvents.emitFollowChanged();
    } catch (_) {
      if (mounted) setState(() => _isFollowing = !_isFollowing);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _isFollowing ? Colors.transparent : const Color(0xFFFF5500),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isFollowing ? Colors.white38 : const Color(0xFFFF5500),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: Colors.white38),
              )
            : Text(
                _isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  color: _isFollowing ? Colors.white38 : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Track _toTrack(TrackEntity e) => Track(
      id: e.id,
      title: e.title,
      artist: e.artistName,
      handle: e.artistName,
      artworkUrl: e.artworkUrl.isNotEmpty ? e.artworkUrl : null,
      audioUrl: e.streamUrl,
      durationMs: e.duration.inMilliseconds,
      likesCount: e.likesCount,
      repostsCount: 0,
    );

void _openOptions(BuildContext context, TrackEntity track) {
  TrackOptionsSheet.show(context, track: _toTrack(track));
}

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

class _IdleHint extends StatelessWidget {
  const _IdleHint();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search, color: Colors.white12, size: 56),
          SizedBox(height: 12),
          Text('Search for tracks, people or playlists',
              style: TextStyle(color: Colors.white24, fontSize: 14)),
        ]),
      );
}

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});
  @override
  Widget build(BuildContext context) => Center(
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

class _SearchShimmer extends StatelessWidget {
  const _SearchShimmer();
  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 8,
        itemBuilder: (_, __) => const _ShimmerTile(),
      );
}

class _ShimmerTile extends StatefulWidget {
  const _ShimmerTile();
  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            _box(46, 46, radius: 6),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(14, double.infinity),
                    const SizedBox(height: 6),
                    _box(11, 160),
                  ]),
            ),
          ]),
        ),
      );

  Widget _box(double h, double w, {double radius = 3}) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: Color.lerp(
              const Color(0xFF2A2A2A), const Color(0xFF3E3E3E), _anim.value),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}