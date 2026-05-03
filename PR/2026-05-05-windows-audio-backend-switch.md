# PR: Windows Audio Backend Switch

## Date
2026-05-05

## Summary
Switched the Windows audio backend from `just_audio_windows` to `just_audio_media_kit` to avoid native thread channel warnings emitted by the previous plugin.

## Changes
- Removed `just_audio_windows` from `pubspec.yaml`.
- Added `just_audio_media_kit` and `media_kit_libs_windows_audio`.
- Initialized `JustAudioMediaKit` in `lib/main.dart` before `AudioService.init()`.

## Why
- The Windows runtime was logging platform-channel thread warnings from `just_audio_windows`.
- `just_audio_media_kit` is the supported alternative backend for Windows and Linux.

## Validation
- `main.dart` compiles cleanly.
- Windows build reached linking successfully, but the final step failed because `Iqa3.exe` was locked by another process.

## Notes
- The next Windows run/build should be done after closing any running copy of the app so the executable can be relinked.
