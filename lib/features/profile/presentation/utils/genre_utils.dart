const List<String> supportedFavoriteGenreSlugs = [
  'electronic',
  'hip-hop',
  'pop',
  'rock',
  'alternative',
  'ambient',
  'classical',
  'jazz',
  'r-b-soul',
  'metal',
  'folk-singer-songwriter',
  'country',
  'reggaeton',
  'dancehall',
  'drum-bass',
  'house',
  'techno',
  'deep-house',
  'trance',
  'lo-fi',
  'indie',
  'punk',
  'blues',
  'latin',
  'afrobeat',
  'trap',
  'experimental',
  'world',
  'gospel',
  'spoken-word',
];

String normalizeFavoriteGenreSlug(String genre) {
  final normalized = genre.trim().toLowerCase();
  switch (normalized) {
    case 'hip hop':
      return 'hip-hop';
    case 'r&b':
    case 'r&b / soul':
    case 'r b soul':
      return 'r-b-soul';
    case 'drum & bass':
      return 'drum-bass';
    case 'deep house':
      return 'deep-house';
    case 'spoken word':
      return 'spoken-word';
    case 'folk / singer-songwriter':
    case 'folk singer songwriter':
      return 'folk-singer-songwriter';
    default:
      return normalized.replaceAll(' ', '-');
  }
}

String favoriteGenreLabel(String value) {
  final slug = value.trim().toLowerCase();
  switch (slug) {
    case 'hip-hop':
      return 'Hip Hop';
    case 'r-b-soul':
      return 'R&B / Soul';
    case 'drum-bass':
      return 'Drum & Bass';
    case 'deep-house':
      return 'Deep House';
    case 'lo-fi':
      return 'Lo-fi';
    case 'spoken-word':
      return 'Spoken Word';
    case 'folk-singer-songwriter':
      return 'Folk / Singer-Songwriter';
    default:
      return slug
          .split('-')
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
  }
}
