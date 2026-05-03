# PR: Playlist Shuffle Playback

## Date
2026-05-05

## Summary
Added a shuffle action to playlist detail playback controls so playlists can start in randomized order.

## Changes
- Added a Shuffle playlist button next to Play playlist.
- Wired shuffle playback through the existing `PlayerCubit` queue pipeline.
- Kept the normal Play playlist action unchanged.

## Notes
- Shuffle reuses the same playback flow as normal play, but starts from a randomized track order.
- The full player already exposes shuffle in its Next up controls, so no extra wiring was needed there.
