// lib/features/search/presentation/widgets/search_tabs_widget.dart

import 'package:flutter/material.dart';
import '../bloc/search_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // ← السطر الناقص


/// الـ page بتبعت controller بس — الـ counts بتجيب من BlocBuilder جوا الـ widget.
class SearchTabsWidget extends StatelessWidget {
  final TabController controller;

  const SearchTabsWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: BlocBuilder<SearchCubit, SearchState>(
        buildWhen: (p, n) =>
            p.tracks.length != n.tracks.length ||
            p.users.length != n.users.length ||
            p.playlists.length != n.playlists.length,
        builder: (context, state) {
          String trackLabel() => state.tracks.isNotEmpty
              ? 'Tracks (${state.tracks.length})'
              : 'Tracks';
          String peopleLabel() => state.users.isNotEmpty
              ? 'People (${state.users.length})'
              : 'People';
          String playlistLabel() => state.playlists.isNotEmpty
              ? 'Playlists (${state.playlists.length})'
              : 'Playlists';

          return TabBar(
            controller: controller,
            isScrollable: false,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Color(0xFFFF5500), width: 2.5),
            ),
            tabs: [
              Tab(text: trackLabel()),
              Tab(text: peopleLabel()),
              Tab(text: playlistLabel()),
            ],
          );
        },
      ),
    );
  }
}