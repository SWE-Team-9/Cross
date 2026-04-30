const String kTrackGenreNone = 'None';

const List<String> kTrackGenreNames = <String>[
  kTrackGenreNone,
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
  'quran',
  'sha3by',
  'islamic',
];

const Map<String, String> _trackGenreAliases = <String, String>{
  'electronic': 'electronic',
  'hip hop': 'hip-hop',
  'hip-hop': 'hip-hop',
  'hiphop': 'hip-hop',
  'pop': 'pop',
  'rock': 'rock',
  'alternative': 'alternative',
  'ambient': 'ambient',
  'classical': 'classical',
  'jazz': 'jazz',
  'r&b': 'r-b-soul',
  'r&b/soul': 'r-b-soul',
  'r&b / soul': 'r-b-soul',
  'r b soul': 'r-b-soul',
  'r-b-soul': 'r-b-soul',
  'metal': 'metal',
  'folk': 'folk-singer-songwriter',
  'folk singer songwriter': 'folk-singer-songwriter',
  'folk/singer-songwriter': 'folk-singer-songwriter',
  'folk / singer-songwriter': 'folk-singer-songwriter',
  'folk-singer-songwriter': 'folk-singer-songwriter',
  'country': 'country',
  'reggaeton': 'reggaeton',
  'dancehall': 'dancehall',
  'drum & bass': 'drum-bass',
  'drum and bass': 'drum-bass',
  'drum-bass': 'drum-bass',
  'house': 'house',
  'techno': 'techno',
  'deep house': 'deep-house',
  'deep-house': 'deep-house',
  'trance': 'trance',
  'lo fi': 'lo-fi',
  'lo-fi': 'lo-fi',
  'lofi': 'lo-fi',
  'indie': 'indie',
  'punk': 'punk',
  'blues': 'blues',
  'latin': 'latin',
  'afrobeat': 'afrobeat',
  'trap': 'trap',
  'experimental': 'experimental',
  'world': 'world',
  'gospel': 'gospel',
  'spoken word': 'spoken-word',
  'spoken-word': 'spoken-word',
  'quran': 'quran',
  'sha3by': 'sha3by',
  'islamic': 'islamic',
};

const Map<String, String> _trackGenreApiValues = <String, String>{
  'electronic': 'Electronic',
  'hip-hop': 'Hip-Hop',
  'pop': 'Pop',
  'rock': 'Rock',
  'alternative': 'Alternative',
  'ambient': 'Ambient',
  'classical': 'Classical',
  'jazz': 'Jazz',
  'r-b-soul': 'R&B / Soul',
  'metal': 'Metal',
  'folk-singer-songwriter': 'Folk / Singer-Songwriter',
  'country': 'Country',
  'reggaeton': 'Reggaeton',
  'dancehall': 'Dancehall',
  'drum-bass': 'Drum & Bass',
  'house': 'House',
  'techno': 'Techno',
  'deep-house': 'Deep House',
  'trance': 'Trance',
  'lo-fi': 'Lo-Fi',
  'indie': 'Indie',
  'punk': 'Punk',
  'blues': 'Blues',
  'latin': 'Latin',
  'afrobeat': 'Afrobeat',
  'trap': 'Trap',
  'experimental': 'Experimental',
  'world': 'World',
  'gospel': 'Gospel',
  'spoken-word': 'Spoken Word',
  'quran': 'Quran',
  'sha3by': 'Sha3by',
  'islamic': 'Islamic',
};

String? normalizeTrackGenreName(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.toLowerCase() == kTrackGenreNone.toLowerCase()) {
    return kTrackGenreNone;
  }

  final lowered = trimmed.toLowerCase();
  final aliased = _trackGenreAliases[lowered];
  if (aliased != null) return aliased;

  final slug = lowered
      .replaceAll('&', '')
      .replaceAll('/', ' ')
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');

  return kTrackGenreNames.contains(slug) ? slug : trimmed;
}

String? trackGenreApiValue(String? value) {
  final normalized = normalizeTrackGenreName(value);
  if (normalized == null || normalized == kTrackGenreNone) {
    return null;
  }

  return _trackGenreApiValues[normalized] ?? normalized;
}
