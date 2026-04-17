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
  final mapped = switch (normalized) {
    'hip hop' => 'hip-hop',
    'r&b' || 'r&b / soul' || 'r b soul' => 'r-b-soul',
    'drum & bass' => 'drum-bass',
    'deep house' => 'deep-house',
    'spoken word' => 'spoken-word',
    'folk / singer-songwriter' || 'folk singer songwriter' =>
      'folk-singer-songwriter',
    _ => normalized.replaceAll(' ', '-'),
  };

  return supportedFavoriteGenreSlugs.contains(mapped) ? mapped : '';
}

String _capitalizeWord(String part) {
  if (part.isEmpty) return '';
  if (part.length == 1) return part.toUpperCase();
  return '${part[0].toUpperCase()}${part.substring(1)}';
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
          .map(_capitalizeWord)
          .join(' ');
  }
}
