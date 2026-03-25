# SoundCloud Clone - Cross

Flutter cross-platform client for the SoundCloud clone project.

## Configuration

This project uses compile-time environment variables via `--dart-define`.

The app does **not** load `.env` files directly.  
Use `.env.example` only as a reference for the required variables.

### Required variables

- `APP_ENV`
- `API_URL`
- `USE_MOCK_TRACK_MANAGEMENT`
- `MOCK_TRACK_MANAGEMENT_MODE`
- `RECAPTCHA_ANDROID_SITE_KEY`
- `RECAPTCHA_WINDOWS_WEB_URL`

### Example values

See `.env.example`.

## VS Code Run Configurations

The repository includes VS Code launch configurations for common development targets.

Available configurations:
- `Flutter - Android Emulator (Dev)`
- `Flutter - Windows Desktop (Dev)`

Open **Run and Debug** in VS Code and choose the configuration you want.

These configurations already include the required `--dart-define` values, so you do not need to type them manually each time.

## Running the app manually

### PowerShell - Android emulator

```powershell
flutter run --dart-define=APP_ENV=dev --dart-define=API_URL=http://10.0.2.2:3006 --dart-define=USE_MOCK_TRACK_MANAGEMENT=false --dart-define=MOCK_TRACK_MANAGEMENT_MODE=success --dart-define=RECAPTCHA_ANDROID_SITE_KEY=6LcxwJYsAAAAAOOjnV1K6O-Sx7hx02ltn85ugKK5 --dart-define=RECAPTCHA_WINDOWS_WEB_URL=https://inquisitive-seahorse-5af208.netlify.app
```

### PowerShell - Windows desktop

```powershell
flutter run -d windows --dart-define=APP_ENV=dev --dart-define=API_URL=http://localhost:3006 --dart-define=USE_MOCK_TRACK_MANAGEMENT=false --dart-define=MOCK_TRACK_MANAGEMENT_MODE=success --dart-define=RECAPTCHA_ANDROID_SITE_KEY=6LcxwJYsAAAAAOOjnV1K6O-Sx7hx02ltn85ugKK5 --dart-define=RECAPTCHA_WINDOWS_WEB_URL=https://inquisitive-seahorse-5af208.netlify.app
```