# Klit

An **E926**-compatible Flutter client with an iOS-style (Cupertino) UI. Browse, search, and manage posts with a responsive layout: bottom navigation on mobile and a sidebar on desktop.

## Features

- **Browse** — Hot, popular, and custom feeds
- **Search** — Full-text search with tag filters and blacklist
- **Favorites** — Save and organize favorites (login required)
- **Feeds** — Create and edit saved feed configurations
- **Media** — Images and video playback (including in-app video player)
- **Account** — Login, profile, and secure credential storage
- **Settings** — Host URL, proxy, theme (light/dark/system), and UI style
- **Responsive** — Single codebase: mobile (bottom nav) and desktop (sidebar) based on screen size

## Prerequisites

- [Flutter](https://flutter.dev) SDK (see `pubspec.yaml` for `sdk` constraint)
- An E926-compatible host (e.g. [e926.net](https://e926.net))

## Getting started

```bash
git clone https://gitlab.com/Openlyst/klit.git
cd klit
flutter pub get
flutter run -d <device eg. linux> 
```

## Building

```bash
# Run
flutter run -d linux
flutter run -d windows
flutter run -d macos
flutter run -d chrome
flutter run  # Android/iOS with device/emulator

# Release
flutter build linux
flutter build windows
flutter build macos
flutter build web
flutter build apk
flutter build ios
```

## Supported platforms

- Linux  
- Windows  
- macOS  
- Android  
- iOS  
- Web  

## License

See repository license file if present.
