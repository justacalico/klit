# Klit

An E621 compatible Flutter app with iOS-style design.

## Building

### Default (Responsive UI)

The app automatically switches between mobile and desktop UI based on screen size:

```bash
flutter run -d linux
flutter build linux
```

### Force Desktop UI

Build with only the desktop UI, regardless of screen size:

```bash
flutter run -d linux --dart-define=FORCE_DESKTOP=true
flutter build linux --dart-define=FORCE_DESKTOP=true
```

### Force Mobile UI

Build with only the mobile UI, regardless of screen size:

```bash
flutter run -d linux --dart-define=FORCE_MOBILE=true
flutter build linux --dart-define=FORCE_MOBILE=true
```

## Supported Platforms

- Linux
- Windows
- macOS
- Android
- iOS
- Web
