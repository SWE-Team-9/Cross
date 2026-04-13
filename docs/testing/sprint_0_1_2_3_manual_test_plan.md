# Sprint 0/1/2/3 Manual Test Plan

Use this checklist to execute manual QA for the currently implemented scope.

## Test Execution Output Format

Capture each run with these fields:

- Test Case ID
- Sprint #
- Feature
- Preconditions
- Steps
- Expected Result
- Actual Result
- Pass/Fail
- Notes/Screenshot link

---

## Sprint 0 — Environment & Smoke

- **TC-ENV-01**: Android launch with required `--dart-define` values.
  - Preconditions: Android emulator/device available.
  - Steps: Run Android dev configuration.
  - Expected: App opens to splash/welcome and does not crash.
- **TC-ENV-02**: Windows launch with required `--dart-define` values.
  - Preconditions: Windows desktop target available.
  - Steps: Run Windows dev configuration.
  - Expected: App opens to splash/welcome and does not crash.
- **TC-SMK-01**: Core tab navigation.
  - Steps: Open Home, Feed, Search, Library, Upgrade tabs.
  - Expected: Tabs resolve to valid screens/placeholders and do not route to 404.

## Sprint 1 — Auth + Core Navigation + Profile/Social Basics

- **TC-S1-AUTH-01**: Register with valid inputs.
- **TC-S1-AUTH-02**: Register with invalid inputs.
- **TC-S1-AUTH-03**: Register duplicate email.
- **TC-S1-AUTH-04**: Login with valid credentials.
- **TC-S1-AUTH-05**: Login with wrong password.
- **TC-S1-AUTH-06**: Login captcha failure/cancel flow.
- **TC-S1-AUTH-07**: Remember-me checked/unchecked session behavior.
- **TC-S1-AUTH-08**: Forgot-password request with valid email.
- **TC-S1-AUTH-09**: Reset password with valid token.
- **TC-S1-AUTH-10**: Reset password with invalid/expired token.
- **TC-S1-AUTH-11**: Logout clears session and returns to auth flow.
- **TC-S1-PROF-01**: Open profile by handle.
- **TC-S1-PROF-02**: Edit profile fields/image/country and verify persisted reload.
- **TC-S1-SOC-01**: Followers/following load states.
- **TC-S1-SOC-02**: Followers/following empty states.
- **TC-S1-SOC-03**: Followers/following error states.
- **TC-S1-SOC-04**: Follow/unfollow/block actions (if in assigned scope).

## Sprint 2 — Upload + Track Management

- **TC-S2-UP-01**: Upload access blocked for non-logged user.
- **TC-S2-UP-02**: Upload access blocked for authenticated non-artist.
- **TC-S2-UP-03**: Upload access allowed for artist.
- **TC-S2-UP-04**: File picker permission denied.
- **TC-S2-UP-05**: Permission permanently denied with settings path.
- **TC-S2-UP-06**: Supported file pick (MP3/WAV) reaches ready state.
- **TC-S2-UP-07**: Metadata validation boundaries (title/genre/tags/description).
- **TC-S2-UP-08**: Visibility private/public selection and persistence.
- **TC-S2-UP-09**: Upload lifecycle transitions (picking → ready → uploading → processing → success).
- **TC-S2-UP-10**: Upload failure path.
- **TC-S2-UP-11**: Private track token + copy-link behavior.
- **TC-S2-TM-01**: Open track management page for managed track.
- **TC-S2-TM-02**: Edit metadata and save.
- **TC-S2-TM-03**: Reset form behavior.
- **TC-S2-TM-04**: Change visibility and save.
- **TC-S2-TM-05**: Delete track cancel path.
- **TC-S2-TM-06**: Delete track confirm path.
- **TC-S2-TM-07**: Home managed list reflects updates/deletions.

### Task-Mapped Detailed Execution (T1.11 / T2.7 / T2.8)

#### T1.11 — File Picker (Audio Only)

- **TC-T1.11-01**: Supported/unsupported file type handling.
  - Preconditions: Authenticated artist account on upload page.
  - Steps:
    1. Tap `Select MP3 / WAV`.
    2. Select `.mp3` and `.wav` files.
    3. Repeat with `.png`, `.pdf`, file without extension, and a corrupted audio file.
  - Expected:
    - MP3/WAV are accepted and move to ready state.
    - Unsupported/invalid files are rejected with clear error feedback.
- **TC-T1.11-02**: Selected file metadata visibility.
  - Preconditions: Authenticated artist account.
  - Steps: Pick a valid audio file.
  - Expected: Selected file card shows file name, extension/type, size, and duration when available.
- **TC-T1.11-03**: Permission first-time allow flow.
  - Preconditions: File/audio permission not granted yet.
  - Steps: Tap `Select MP3 / WAV`, then allow permission.
  - Expected: Picker opens and selection proceeds normally.
- **TC-T1.11-04**: Permission deny flow.
  - Preconditions: File/audio permission prompt available.
  - Steps: Tap `Select MP3 / WAV`, then deny permission.
  - Expected: User sees permission-related error/guidance and upload cannot proceed.
- **TC-T1.11-05**: Permission permanently denied flow.
  - Preconditions: File/audio permission in "don't ask again"/permanently denied state.
  - Steps: Tap `Select MP3 / WAV`.
  - Expected: Dialog/error explains permission is permanently denied and provides settings path.
- **TC-T1.11-06**: Edge handling for cancel and large files.
  - Preconditions: Authenticated artist account.
  - Steps:
    1. Open picker then cancel without selecting.
    2. Select a very large valid MP3/WAV.
  - Expected:
    - Cancel does not crash and keeps page stable.
    - Large file is handled gracefully (accepted or rejected with clear error).

#### T2.7 — Profile Image Upload Flow (Avatar/Cover)

- **TC-T2.7-01**: Avatar upload happy path.
  - Preconditions: User can access profile edit page.
  - Steps: Select avatar image, crop/resize, upload.
  - Expected:
    - Preview matches crop result before upload.
    - Upload state transitions are visible (idle → uploading/progress → success).
    - Updated avatar appears immediately in UI after success.
- **TC-T2.7-02**: Cover upload happy path.
  - Preconditions: User can access profile edit page.
  - Steps: Select cover image, crop/resize, upload.
  - Expected: Same behavior as avatar flow with immediate UI refresh on success.
- **TC-T2.7-03**: Upload failure and retry.
  - Preconditions: Profile image upload available.
  - Steps:
    1. Start image upload while simulating network failure.
    2. Retry upload after restoring network.
  - Expected: Error feedback is shown on failure and retry succeeds.
- **TC-T2.7-04**: Unsupported/large file and cancel behavior.
  - Preconditions: Profile image upload available.
  - Steps:
    1. Attempt unsupported image format.
    2. Attempt very large image.
    3. Cancel during crop and during upload.
  - Expected:
    - Unsupported/oversized handling is clear and stable.
    - Cancel actions do not crash and leave predictable UI state.

#### T2.8 — Track Management Basics

- **TC-T2.8-01**: Edit metadata and save.
  - Preconditions: Creator-owned managed track exists.
  - Steps: Update title, genre, tags, and description; save.
  - Expected: Success feedback appears and updated values are reflected immediately in profile/managed list.
- **TC-T2.8-02**: Toggle privacy and save.
  - Preconditions: Creator-owned managed track exists.
  - Steps: Switch public/private visibility and save.
  - Expected: Visibility badge/state updates immediately without stale data.
- **TC-T2.8-03**: Delete cancel path.
  - Preconditions: Creator-owned managed track exists.
  - Steps: Tap delete, then cancel from confirmation dialog.
  - Expected: Track remains present and unchanged.
- **TC-T2.8-04**: Delete confirm path.
  - Preconditions: Creator-owned managed track exists.
  - Steps: Tap delete and confirm.
  - Expected: Track is removed and list/UI updates immediately.
- **TC-T2.8-05**: Non-owner restrictions.
  - Preconditions: Logged in as non-owner for target track.
  - Steps: Open track details/management entry points.
  - Expected: Non-owner cannot edit metadata, change visibility, or delete track.

#### T3.8 — Upload Flow UI

- **TC-S2-UP-03**: Artist opens upload page → full upload UI shown.
  - Preconditions: Logged in as artist.
  - Steps:
    1. Open Upload entry point from app navigation.
    2. Wait until page fully renders.
  - Expected:
    - Upload page opens without redirect/error.
    - Core UI sections are visible: file picker CTA, metadata form, visibility selection, upload action area.
- **TC-S2-UP-06**: Select MP3/WAV → file card + ready state.
  - Preconditions: Artist on upload page.
  - Steps:
    1. Tap `Select MP3 / WAV`.
    2. Pick valid `.mp3`.
    3. Repeat with valid `.wav`.
  - Expected:
    - Selected file card appears with file details.
    - Screen enters ready state (upload can proceed when required metadata is valid).
- **TC-S2-UP-07**: Metadata validation (title/genre/tags/description).
  - Preconditions: Valid audio file already selected.
  - Steps:
    1. Leave required fields empty and try upload.
    2. Enter invalid boundary values (too short/too long/invalid format if enforced).
    3. Enter valid values for all fields.
  - Expected:
    - Field-level validation messages appear for invalid input.
    - Upload blocked until validation passes.
    - Errors clear after valid correction.
- **TC-S2-UP-09**: Upload lifecycle (picking → ready → uploading → processing → success).
  - Preconditions: Artist account; valid file + metadata.
  - Steps:
    1. Pick file (confirm picking/ready transitions).
    2. Tap upload.
    3. Observe states until completion.
  - Expected:
    - States appear in correct order with no skipped/broken state.
    - Final success state shown with resulting track confirmation.
- **TC-S2-UP-10**: Upload failure path shows correct error.
  - Preconditions: Valid file + metadata; simulate network/server failure.
  - Steps:
    1. Start upload during forced failure condition.
    2. Observe error handling.
    3. Retry after restoring network.
  - Expected:
    - Clear failure message shown.
    - UI remains stable (no crash/freeze).
    - Retry path works and can recover to success.

#### T3.9 — Track Visibility & Share Rules UI

- **TC-S2-UP-08**: Visibility private/public selection affects result state.
  - Preconditions: Artist on upload page with valid file/metadata.
  - Steps:
    1. Set visibility to `Public`, upload track.
    2. Repeat with `Private`.
  - Expected:
    - Final created track reflects selected visibility each time.
    - Visibility badge/state in UI matches saved value.
- **TC-S2-UP-11**: Private upload returns token + copy private link works.
  - Preconditions: Private upload flow available.
  - Steps:
    1. Upload as private.
    2. Copy generated private link/token from success/manage UI.
    3. Open link in new session/account.
  - Expected:
    - Private token/link is generated.
    - Copy action works.
    - Link resolves to intended private track access behavior.
- **TC-S2-TM-04**: Change visibility + save visibility.
  - Preconditions: Owner opens Track Management for existing track.
  - Steps:
    1. Toggle visibility (public ↔ private).
    2. Save changes.
    3. Reload page/app.
  - Expected:
    - Success feedback appears.
    - Visibility persists after reload.
- **TC-S2-TM-07**: Home managed list reflects visibility/update state.
  - Preconditions: Owner has at least one managed track updated in Track Management.
  - Steps:
    1. Change metadata and/or visibility in management page.
    2. Return to Home/managed list.
    3. Refresh/reopen app.
  - Expected:
    - Managed list reflects latest title/metadata/visibility.
    - No stale old state after navigation or refresh.

### Final Acceptance Checklist (for T1.11 / T2.7 / T2.8 / T3.8 / T3.9)

- No crashes across all task flows.
- Validation/error messages are clear and consistent.
- Successful actions update UI immediately.
- Failure paths provide retry and recover correctly.
- Data remains correct after app refresh/reopen.
- After major Track Management UI redesign, rerun T3.8/T3.9 cases as regression.

## Sprint 3 — Deep Links + Playback + Engagement

- **TC-S3-DL-01**: `soundclone://track/{id}`
- **TC-S3-DL-02**: `soundclone://track/secret/{token}`
- **TC-S3-DL-03**: `soundclone://user/{handle}`
- **TC-S3-DL-04**: `soundclone://playlist/{id}`
- **TC-S3-DL-05**: `soundclone://search?q=...`
- **TC-S3-DL-06**: Invalid deep-link handling.
- **TC-S3-DL-07**: Duplicate deep-link handling.
- **TC-S3-PB-01**: Track load success behavior.
- **TC-S3-PB-02**: Track load failure behavior.
- **TC-S3-PB-03**: Mini-player show/hide behavior.
- **TC-S3-PB-04**: Full player controls (play/pause/seek/waveform).
- **TC-S3-PB-05**: Back navigation from full player.
- **TC-S3-ENG-01**: Like/unlike.
- **TC-S3-ENG-02**: Repost/unrepost.
- **TC-S3-ENG-03**: Likers/reposters lists + pagination/load-more.
- **TC-S3-CMT-01**: Load comments.
- **TC-S3-CMT-02**: Add comment.
- **TC-S3-CMT-03**: Reply to comment.
- **TC-S3-CMT-04**: Delete comment.
- **TC-S3-LIB-01**: Recently played updates after playback.
- **TC-S3-LIB-02**: Recently played persistence.

## Negative + Regression

- **TC-NEG-01**: Network failure/offline during auth flows.
- **TC-NEG-02**: Network failure/offline during upload flows.
- **TC-NEG-03**: Network failure/offline during playback flows.
- **TC-NEG-04**: Network failure/offline during comments/interactions.
- **TC-REG-01**: Re-run core smoke after each sprint verification pass.

---

## Execution Row Template

| Test Case ID | Sprint # | Feature | Preconditions | Steps | Expected Result | Actual Result | Pass/Fail | Notes/Screenshot link |
|---|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |  |
