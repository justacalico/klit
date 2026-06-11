<div align="center">

<img src="icon.svg" width="120" alt="Kilt logo">

# Kilt

**A proper E926/Self21 client**

[![Flutter](https://img.shields.io/badge/Flutter-3.32.0+-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.0+-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-AGPL--3.0-yellow?style=flat-square)](LICENSE)

</div>

Kilt is a client for E926 and Self21-compatible image boards. It works on desktop and mobile.

## Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) SDK 3.32.0 or higher
- Dart SDK 3.8.0 or higher
- An E926-compatible host (e.g. [e926.net](https://e926.net)) or a [Self21](https://gitlab.com/HttpAnimations/Self21) instance


## Getting Started

### Clone the repository

```bash
git clone https://gitlab.com/Openlyst/klit.git
cd klit
```

### Install dependencies

```bash
flutter pub get
```


## Building

### Desktop builds

```bash
flutter build linux
flutter build windows
flutter build macos
```

### Mobile builds

```bash
flutter build apk
flutter build ios
```

## Configuration

Kilt connects to E926 by default. For a Self21 instance, go to Settings > Server and enter your URL.

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.
