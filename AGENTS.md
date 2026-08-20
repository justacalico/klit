# Agent Notes

## Verification

- Run the full test suite: `flutter test`
- Run static analysis: `flutter analyze`
- Refresh generated code: `dart run build_runner build --delete-conflicting-outputs`
- Generate localizations: `flutter gen-l10n`

## Project Structure

- Flutter cross-platform app (Android, iOS, Windows, macOS, Linux).
- State management uses `flutter_riverpod` / `hooks_riverpod` alongside a custom `flutter_sub_provider`.
- Local persistence uses Drift.
- Networking uses Dio.
- Models use Freezed / JSON Serializable.
- Generated files (`.freezed.dart`, `.g.dart`, `.drift.dart`, `lib/l10n/gen/`) are excluded from version control.

## Branch

Active feature branch: `refactor/codebase-review-fixes`.
