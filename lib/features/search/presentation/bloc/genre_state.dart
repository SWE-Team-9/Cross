// // lib/features/search/presentation/bloc/genre_state.dart

// part of 'genre_cubit.dart';

// class GenreState extends Equatable {
//   final bool         isLoading;
//   final bool         hasError;
//   final String       headerImageUrl;

//   // All-tab sections
//   final List<Track>             trending;
//   final Track?                  introducing;
//   final List<Track>             introducingExtras;
//   final List<PlaylistEntity>    playlists;
//   final List<AlbumEntity>       albums;
//   final List<GenreProfileEntity> profiles;
//   final List<Track>             discoverMore;

//   // Follow state — set of user IDs the current user follows
//   final Set<String> followingIds;

//   const GenreState({
//     this.isLoading         = false,
//     this.hasError          = false,
//     this.headerImageUrl    = '',
//     this.trending          = const [],
//     this.introducing       = null,
//     this.introducingExtras = const [],
//     this.playlists         = const [],
//     this.albums            = const [],
//     this.profiles          = const [],
//     this.discoverMore      = const [],
//     this.followingIds      = const {},
//   });

//   GenreState copyWith({
//     bool?                   isLoading,
//     bool?                   hasError,
//     String?                 headerImageUrl,
//     List<Track>?            trending,
//     Track?                  introducing,
//     List<Track>?            introducingExtras,
//     List<PlaylistEntity>?   playlists,
//     List<AlbumEntity>?      albums,
//     List<GenreProfileEntity>? profiles,
//     List<Track>?            discoverMore,
//     Set<String>?            followingIds,
//   }) =>
//       GenreState(
//         isLoading:         isLoading         ?? this.isLoading,
//         hasError:          hasError           ?? this.hasError,
//         headerImageUrl:    headerImageUrl     ?? this.headerImageUrl,
//         trending:          trending           ?? this.trending,
//         introducing:       introducing        ?? this.introducing,
//         introducingExtras: introducingExtras  ?? this.introducingExtras,
//         playlists:         playlists          ?? this.playlists,
//         albums:            albums             ?? this.albums,
//         profiles:          profiles           ?? this.profiles,
//         discoverMore:      discoverMore       ?? this.discoverMore,
//         followingIds:      followingIds       ?? this.followingIds,
//       );

//   @override
//   List<Object?> get props => [
//         isLoading, hasError, headerImageUrl,
//         trending, introducing, introducingExtras,
//         playlists, albums, profiles, discoverMore,
//         followingIds,
//       ];
// }