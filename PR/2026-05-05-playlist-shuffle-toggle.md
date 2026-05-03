# PR: Playlist Shuffle Toggle

## Date
2026-05-05

## Summary
Converted the playlist shuffle control into a two-state toggle and made playlist playback honor that state.

## Changes
- Shuffle button now toggles between on and off states.
- The button visually reflects the active shuffle state.
- Play playlist now starts in shuffled order when shuffle is enabled.

## Notes
- This keeps shuffle as a persistent choice for the playlist surface instead of a one-shot action.
- The full player shuffle control remains unchanged.
