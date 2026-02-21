# Cross Platform (Mobile)

# Phase 0: Proposal & Architecture

## 🏢 Company & Project Overview
**Company Name:** ---------------------------[TODO: Insert Company Name]----------------------------  
**Project:** Social Streaming Platform (SoundCloud Clone)  
**Platforms:** Android + iOS  
**Framework:** Flutter (Dart)

This repository contains the Cross-Platform (Mobile) client application that mimics core SoundCloud behaviors (authentication, streaming playback, social graph, playlists, messaging, notifications, etc.) while maintaining clean architecture, high test coverage, and smooth integration with Backend APIs.

---

## 🛠️ Cross Platform Technology Stack & Architecture

To deliver a responsive, scalable, and maintainable mobile client for both Android and iOS, our team has selected a modern Flutter stack with strong separation of concerns and high testability.

### 1. Core Framework & Platform Targets
* **Framework:** Flutter (Dart)  
* **Targets:** Android + iOS  
* **Build Flavors:** `dev`, `staging`, `prod` (environment-isolated base URLs and feature flags)

### 2. App Architecture (Clean Architecture + Feature Modules)
We use a layered architecture to keep the codebase testable and modular:
* **Presentation Layer:** Screens, Widgets, Navigation, State (BLoC/Cubit)
* **Domain Layer:** Entities, Use Cases, Business Rules
* **Data Layer:** Repositories, Remote Data Sources (API clients), Local Data Sources (cache), DTO mapping

**Design Patterns (≥3 used):**
* **Repository Pattern:** isolate data access behind domain contracts (e.g., `AuthRepository`, `TracksRepository`)
* **Dependency Injection (DI):** swap real vs mock services, simplify testing (GetIt/Injectable)
* **Factory/Mapper Pattern:** DTO ↔ Domain conversions using generated serializers
* **Observer Pattern:** reactive UI updates using streams/state changes (BLoC)

### 3. State Management & Navigation
* **State Management:** `flutter_bloc` (BLoC/Cubit) + `equatable`
* **Navigation:** `go_router` (guarded routes, deep linking-ready)
* **Error Handling:** unified `Failure` model (network/server/cache/auth)

### 4. Networking, API Integration & Serialization
* **HTTP Client:** `dio`
* **REST Client Layer (optional):** `retrofit` (Dart) for typed endpoints
* **Auth Tokens / Cookies:** compatible with Backend decisions (token-based auth; cookie-jar support if cookies are used)
* **Serialization:** `json_serializable` / `freezed` for immutable models and safe parsing
* **Pagination:** supported whenever applicable (feeds, followers, search results)

### 5. Local Storage, Caching & Offline-Ready Behavior
* **Secure Storage:** `flutter_secure_storage` (tokens/session where needed)
* **Local Cache:** `hive` / `shared_preferences` (preferences, lightweight cached responses)
* **Media Cache:** `cached_network_image` (artwork), file caching for previews if required
* **Connectivity Awareness:** `connectivity_plus` (UI states + retries)

### 6. Media Playback & Streaming
Streaming is a core experience; we implement a persistent player that survives navigation:
* **Playback Engine:** `just_audio`
* **Background / OS controls:** `audio_service` (lock-screen controls, notification controls)
* **Player State:** global BLoC for queue, buffering, seek, repeat/shuffle, playback speed (if needed)
* **Sticky Player UI:** persistent mini-player + full-screen player

### 7. Real-Time Features (Messaging / Notifications)
* **Real-time channel (if Backend uses Socket.IO):** `socket_io_client`
* **Push Notifications:** Firebase Cloud Messaging (`firebase_messaging`)
* **In-app notifications UI:** notification list + unread badge + mark-as-read flows

---

## 📦 Module Implementation Plan (Feature-Based)

> The following modules reflect the official project modules.

### 1. Authentication & User Management (Module 1)
* **UI:** registration/login/verification/reset password screens
* **Google OAuth:** `google_sign_in` (or WebView fallback if required)
* **Session Handling:** access/refresh strategy aligned with Backend contract
* **Form Validation:** centralized validators + error mapping
* **Security:** no tokens in logs; secure storage; http-only cookie support via cookie jar when applicable

### 2. User Profile & Social Identity (Module 2)
* **Profile Customization:** bio, location, favorite genres
* **Visual Assets:** avatar + cover (upload + cached display)
* **External Links:** Instagram/Twitter/website links validation
* **Privacy:** public vs private profile states reflected in UI

### 3. Followers & Social Graph (Module 3)
* **Follow/Unfollow:** optimistic UI + rollback on failure
* **Lists:** Followers / Following / Suggested Users
* **Block/Unblock:** UI enforcement + server-backed restrictions

### 4. Audio Upload & Track Management (Module 4)
* **File Selection:** `file_picker`
* **Metadata Forms:** title, tags, genre, release date, visibility
* **Upload:** multipart upload via `dio` with progress indicator
* **Track State:** Processing vs Finished UI states as returned from Backend

### 5. Playback & Streaming Engine (Module 5)
* **Core Controls:** play/pause/seek/volume
* **Accessibility State:** playable/preview/blocked (tier/region) reflected in UI
* **History:** recently played / listening history views
* **Persistent Player:** consistent across all screens

### 6. Engagement & Social Interactions (Module 6)
* **Likes/Favorites:** toggle + count
* **Reposts:** repost to user feed/profile
* **Timestamped Comments:** comment at a specific second (synced with playback position)
* **Engagement Lists:** list of users who liked/reposted

### 7. Sets & Playlists (Module 7)
* **CRUD:** create/edit/delete playlists
* **Track Sequencing:** reorder (drag & drop) and add/remove tracks
* **Privacy:** secret vs public playlists, shareable link support

### 8. Feed, Search & Discovery (Module 8)
* **Activity Feed:** chronological feed of followed users’ activity
* **Global Search:** tracks/users/playlists keyword search
* **Trending:** charts/discovery based on backend criteria
* **Resolver:** permalink resolver support when used in sharing/deep links

### 9. Messaging & Track Sharing (Module 9)
* **Direct Messages:** 1-to-1 chat only (no groups)
* **In-chat previews:** track/playlist cards inside messages
* **Unread Counts:** conversation list badges
* **Blocking Rules:** enforced in UI and via server errors

### 10. Real-Time Notifications (Module 10)
* **In-app notifications:** list + mark as read
* **Push notifications:** FCM integration (when enabled by DevOps)
* **Unread counter:** global badge state synced with backend

### 11. Moderation & Admin Dashboard (Module 11)
* Mobile includes **user-facing reporting flows** (report track/comment/user) where applicable.
* Full admin dashboard is typically web-based; mobile will only implement agreed limited moderation actions (if required).

### 12. Premium Subscription (Pro/Go+) (Module 12)
* **Paywall UI:** plan comparison + feature gating
* **Limits:** enforce UX around free limits (e.g., upload limits) based on backend plan status
* **Payments:** Stripe Test Mode handled on backend; mobile consumes subscription status (no store billing unless explicitly required)

---

## ✅ Course / Implementation Constraints
* **Messaging:** No group chats; only 1-to-1 direct messaging
* **Comment replies:** Restricted to one level deep
* **Message reactions:** Not implemented
* **Testing:** Unit tests target >95% coverage
* **Push policy:** avoid huge commits; push frequently; integration is graded

---

## 🧪 Testing & Coverage (Target: >95% Unit Testing)
* **Unit Tests:** `flutter_test`
* **Mocking:** `mocktail` / `mockito`
* **BLoC Tests:** `bloc_test`
* **Coverage:** `flutter test --coverage`
* **Integration Tests (optional but recommended):** `integration_test`
* **Golden Tests (optional):** UI regression snapshots where helpful

---

## 📝 Software Process & Quality Assurance Tools
* **Version Control:** GitHub
* **Task Management:** ----------------[TODO: Jira/Trello/GitHub Projects]-------------------------------
* **Code Quality:** `flutter_lints`, `dart format`, `dart analyze`
* **Documentation:** inline dartdoc for public APIs + clear module READMEs when needed

---

## DevOps / Infrastructure

The project will use the following DevOps tools and processes (aligned with the global workflow):

- **Continuous Integration / Deployment:** GitHub Actions workflows for:
  - Flutter: format + analyze + test + coverage
  - Android: build APK/AAB (dev/staging/prod)
  - iOS: build (IPA/archive) on macOS runners
- **Branch protection rules:**
  - `main` branch protected
  - Pull requests required before merging
  - 1–2 approvals required per PR
  - CI checks must pass before merging
  - Direct pushes restricted to maintainers/devops-team only (if necessary)
- **Environment management:**
  - `.env` files (local) + GitHub Secrets (CI)
  - `--dart-define` / `flutter_dotenv` for base URLs and feature flags
- **Testing / QA team:** reviews PRs and executes E2E coverage for cross-platform flows

---

## 🤝 Team Connections (Integration Owners)

- **Backend Team:** API contract (Swagger/Postman), auth strategy, streaming endpoints, websocket events, notifications triggers
- **Frontend Team:** UX parity, naming consistency, shared business rules (limits, permissions)
- **Testing Team:** stable widget keys/selectors, deterministic test accounts/seeds, reproducible flows
- **DevOps Team:** CI/CD setup, secrets/env handling, release artifacts, FCM setup for push

---

## 📄 Attribution & Licensing
- Any external code/resources must be explicitly acknowledged:
  - inside source code comments
  - in this README
  - and in final project documentation
- All third-party dependencies must be license-checked (commercial restrictions must be stated).

---

## 👥 Team
**Sub-Team Leader:** Eyad Adel Mohamed 
**Members:**  
- Abdallah ibrahim 
- Ali Mahmoud Ali  
- Ali Mahmoud Ahmed 
- Ahmed Reda

**Weekly progress report day:** [TODO: Day]

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (stable)
- Android Studio / Xcode
- CocoaPods (iOS)
- A running backend instance OR mock server

### Install
```bash
flutter pub get
