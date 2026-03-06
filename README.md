# Noorify

Noorify is an Islamic companion app built with Flutter. It focuses on daily
Islamic routines with prayer timing support, Quran reading, Qibla direction,
and offline-friendly behavior.

## Core Features

- Prayer times with device location support and fallback timing logic.
- Sehri, Iftar, and prayer alerts using local notifications.
- Quran browsing and Surah detail views.
- Ayah-level bookmarks and short personal notes (stored locally).
- Offline Quran text cache and offline audio download support.
- Qibla compass with heading and bearing guidance.
- Profile/preferences for language, location mode, and alert settings.
- Privacy policy and app information screens.
- UI preview screen for quickly opening mock/feature screens.

## Tech Stack

- Flutter + Dart
- `google_fonts`
- `geolocator`, `geocoding`, `flutter_compass`
- `adhan_dart`, `hijri`, `ponjika`
- `flutter_local_notifications`, `timezone`
- `dio`, `flutter_cache_manager`, `just_audio`

## Getting Started

### 1. Prerequisites

- Install Flutter (stable channel) with Dart 3.11+ support.
- Set up Android Studio or Xcode (depending on your target platform).
- Verify setup:

```bash
flutter doctor
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

### 4. Validate Code Quality

```bash
flutter analyze
flutter test
```

## Useful Project Paths

- `lib/main.dart`: app entry point and theme/bootstrap.
- `lib/screens/`: UI screens (home, prayer activity, Quran, Qibla, settings).
- `lib/services/`: API, offline cache, and Quran helper services.
- `lib/app/`: route names, route generator, shared app-wide settings.
- `assets/images/`: static image assets.

## Notes

- Display name is currently branded as `Noorify` across Flutter and platform
  shells.
- Package and bundle IDs are still scaffold defaults (`com.example.first_project`)
  and can be renamed later for production release.

## Roadmap

- Future feature roadmap: [docs/FUTURE_UPDATES.md](docs/FUTURE_UPDATES.md)
- Current execution mode: local-first (no backend), one feature at a time.
