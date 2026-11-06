# Astro Siri Learning Hub

Flutter mobile learning application for astrology subjects, courses, lessons,
video content, study notes, and learner profiles.

## Requirements

- Flutter SDK compatible with Dart `3.12.1` or newer within the declared SDK range
- Android Studio/Xcode for device builds
- A configured Android or iOS device/emulator

## Setup

```bash
flutter pub get
flutter analyze
flutter test
```

Run the app on a connected device or emulator:

```bash
flutter run
```

Build an Android APK:

```bash
flutter build apk --release
```

## Project structure

- `lib/core` — shared constants, routes, theme, validation, and reusable widgets
- `lib/data` — API services and repository implementations
- `lib/domain` — application models and repository contracts
- `lib/features/auth` — login, OTP, and first-time profile setup
- `lib/features/dashboard` — dashboard, subjects, courses, lessons, media, and profile flows
- `test` — unit and widget tests, including token refresh and media handling

## Authentication and API

The app uses the mobile API configured in
`lib/core/constants/api_constants.dart`. Access tokens are refreshed through
the existing authentication service when possible. Do not commit credentials,
signing keys, `.env` files, or machine-specific platform configuration.

## QA handover

Before sharing a build, run:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Share the generated APK from `build/app/outputs/flutter-apk/` together with the
test results and the build version.
