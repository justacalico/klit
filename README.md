# Kilt

An **E926**/**[Self21](https://gitlab.com/HttpAnimations/Self21)**-compatible client,

## Prerequisites

- [Flutter](https://flutter.dev) SDK (see `pubspec.yaml` for `sdk` constraint)
- An E926-compatible host (e.g. [e926.net](https://e926.net)) OR a [Self21](https://gitlab.com/HttpAnimations/Self21) host.

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

# Release
flutter build linux
flutter build windows
flutter build macos
flutter build apk
flutter build ios
```

## Supported platforms

- Linux  
- Windows  
- macOS  
- Android  
- iOS  

## License

See [LICENSE](LICENSE).
