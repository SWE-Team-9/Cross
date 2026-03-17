# Contributing Guide

## Getting Started

1. Clone the repository.
2. Checkout the `dev` branch.
3. Pull the latest changes:
   ```bash
   git pull origin dev
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Create a new branch from `dev` before starting any work.

---

## Branch Naming

Create branches from `dev` using one of the following conventions:

- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Internal code improvements without changing behavior
- `test/description` - Adding or updating tests
- `docs/description` - Documentation-only changes
- `chore/description` - Maintenance and repository housekeeping
- `ci/description` - CI/CD workflow changes

### Examples

- `feature/auth-login`
- `fix/router-unknown-route`
- `refactor/secure-storage-di`
- `test/dio-client-coverage`
- `docs/update-contributing`
- `chore/cleanup-unused-imports`
- `ci/update-test-workflow`

### Branch Rules

- Always branch from `dev`.
- Keep each branch focused on one logical task.
- Do not mix unrelated changes in the same branch.
- Use short, clear, lowercase names separated by hyphens.

---

## Code Formatting and Local Checks

Before pushing any branch, make sure your code is formatted and all checks pass locally.

### Required Commands

Run the following commands before every push:

```bash
flutter pub get
dart format .
flutter analyze
flutter test --coverage
```

### Why this is required

This helps prevent:

- formatting issues in PRs
- analyzer errors in CI
- broken tests after push
- unnecessary back-and-forth during review

Do not push code before running these checks locally.

---

## Commit Messages

Use the following format for commit messages:

```text
type(scope): short description
```

### Allowed Types

- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code improvement without behavior change
- `test` - Add or update tests
- `docs` - Documentation-only changes
- `chore` - Maintenance work
- `style` - Formatting or style-only changes
- `perf` - Performance improvement
- `build` - Build system or dependency updates
- `ci` - CI/CD workflow changes
- `revert` - Revert a previous commit

### Suggested Scopes

Use a scope that reflects the affected part of the project, such as:

- `auth`
- `profile`
- `social`
- `comments`
- `premium`
- `feed`
- `search`
- `playback`
- `messaging`
- `upload`
- `playlists`
- `notifications`
- `router`
- `di`
- `network`
- `storage`
- `core`
- `docs`
- `ci`

### Examples

```text
feat(auth): add login endpoint integration
fix(router): handle unknown routes correctly
refactor(di): simplify secure storage registration
test(network): add dio client error mapping tests
docs(contributing): add commit message guidelines
chore(ci): update Flutter test workflow
style(auth): format auth cubit file
perf(playback): reduce waveform rebuilds
build(android): update Gradle config
revert(auth): revert login state persistence change
```

### Commit Rules

- Use lowercase for `type` and `scope`.
- Keep the description short and clear.
- Write the description in imperative style.
- Do not end the description with a period.
- Keep each commit focused on one logical change.

---

## Pull Request Process

1. Make sure your branch is up to date with `dev`.
2. Run formatting, analyzer, and tests locally before pushing.
3. Push your branch to the remote repository.
4. Open a pull request targeting `dev`.
5. Add a clear PR title and description.
6. Ensure all CI checks pass.
7. Request review from the appropriate team member.
8. Address review comments before merging.

---

## Pull Request Checklist

Before opening a PR, confirm that:

- [ ] The branch was created from `dev`
- [ ] The change is focused and scoped correctly
- [ ] Code has been formatted with `dart format .`
- [ ] `flutter analyze` passes locally
- [ ] `flutter test --coverage` passes locally
- [ ] No unrelated files are included
- [ ] Commit messages follow the required format
- [ ] CI passes successfully

---

## General Contribution Rules

- Follow the project structure and naming conventions.
- Prefer small, focused PRs over large mixed changes.
- Do not commit temporary debug code or commented-out code.
- Do not push broken code hoping CI will catch it.
- Write or update tests when changing behavior in testable areas.
- Keep documentation updated when workflows or conventions change.
