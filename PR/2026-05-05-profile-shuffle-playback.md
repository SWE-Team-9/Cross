# PR: Profile Shuffle and Play Controls

## Date
2026-05-05

## Summary
Added working playback actions to the profile header and wired the full-player shuffle control to the active queue.

## Changes
- Profile shuffle button now shuffles the profile's tracks and starts playback.
- Profile play button now plays the profile's tracks in order.
- Full-player shuffle icon now reshuffles the current queue through `PlayerCubit`.
- Added a queue shuffle helper to `PlayerCubit`.

## Why
- The profile header controls were previously stubs.
- Shuffle and play should trigger real playback behavior, not just display icons.

## Notes
- Profile playback uses the existing track resolution pipeline, so tracks without direct stream URLs can still resolve through the backend.
- The shuffle action restarts playback from the reshuffled queue's current track position.
