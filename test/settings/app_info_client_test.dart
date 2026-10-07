// SPDX-License-Identifier: AGPL-3.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/settings/settings.dart';
import 'package:pub_semver/pub_semver.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, {this.statusCode = 200});

  final Object body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body is String ? body as String : json.encode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _apiResponse({
  String version = '11.0.0',
  String? date = '2026-08-27',
  String description = '',
  bool downloadsDisabled = false,
}) => {
  'success': true,
  'appName': 'Kilt',
  'appSlug': 'kilt',
  'data': {
    'version': version,
    'date': date,
    'localizedDescription': description,
    'platforms': ['iOS', 'macOS', 'Windows', 'Linux', 'Android', 'Web'],
    'downloadsDisabled': downloadsDisabled,
    'downloads': {
      'iOS': 'https://example.com/kilt.ipa',
      'Android': {'apk': 'https://example.com/kilt.apk'},
      'macOS': {
        'x86_64': 'https://example.com/kilt-macos-x64.zip',
        'arm64': 'https://example.com/kilt-macos-arm64.zip',
        'universal': 'https://example.com/kilt-macos.zip',
      },
      'Windows': {
        'zip': {'x86_64': 'https://example.com/kilt-win-x64.zip'},
        'exe': {'x86_64': 'https://example.com/kilt-win-x64.exe'},
      },
      'Linux': {
        'zip': {'x86_64': 'https://example.com/kilt-linux-x64.zip'},
        'appimage': {
          'x86_64': 'https://example.com/kilt-linux-x64.AppImage',
        },
        'deb': {'x86_64': 'https://example.com/kilt-linux-x64.deb'},
      },
    },
  },
};

Future<AppInfoClient> _client({
  Object? body,
  int statusCode = 200,
  String version = '10.0.0',
  String buildNumber = '1',
  Source source = Source.UNKNOWN,
}) async {
  await AppInfo.initializeMock(
    developer: 'OpenLyst',
    github: null,
    discord: null,
    website: 'openlyst.ink',
    kofi: null,
    email: null,
    appName: 'Kilt',
    packageName: 'gitlab.openlyst.kilt',
    version: version,
    buildNumber: buildNumber,
    source: source,
  );
  final dio = Dio()
    ..httpClientAdapter = _StubAdapter(body ?? _apiResponse(), statusCode: statusCode);
  return AppInfoClient(dio: dio);
}

void main() {
  group('AppInfoClient.getVersions', () {
    test('parses the Openlyst latest-version response', () async {
      final client = await _client();
      final versions = await client.getVersions(force: true);

      expect(versions, hasLength(1));
      final release = versions.single;
      expect(release.version, Version.parse('11.0.0'));
      expect(release.name, '11.0.0');
      expect(release.date, DateTime.parse('2026-08-27'));
      expect(release.binaries, containsAll(['apk', 'ipa']));
    });

    test('uses localizedDescription for the version description', () async {
      final client = await _client(
        body: _apiResponse(description: 'changelog text'),
      );
      final versions = await client.getVersions(force: true);

      expect(versions.single.description, 'changelog text');
    });

    test('throws when the API reports failure', () async {
      final client = await _client(body: {'success': false});

      expect(
        () => client.getVersions(force: true),
        throwsA(isA<AppUpdaterException>()),
      );
    });

    test('throws when the version is missing', () async {
      final body = _apiResponse()
        ..['data'] = {'date': '2026-08-27'};
      final client = await _client(body: body);

      expect(
        () => client.getVersions(force: true),
        throwsA(isA<AppUpdaterException>()),
      );
    });
  });

  group('AppInfoClient.getNewVersions', () {
    test('returns versions newer than the installed one', () async {
      final client = await _client();
      final versions = await client.getNewVersions(force: true);

      expect(versions, hasLength(1));
      expect(versions.single.version, Version.parse('11.0.0'));
    });

    test('returns empty when installed version matches', () async {
      final client = await _client(version: '11.0.0');
      final versions = await client.getNewVersions(force: true);

      expect(versions, isEmpty);
    });

    test('returns empty when installed version is newer', () async {
      final client = await _client(version: '12.0.0');
      final versions = await client.getNewVersions(force: true);

      expect(versions, isEmpty);
    });

    test('does not throw when the build number is empty', () async {
      // Desktop builds without a pubspec build number report ''.
      final client = await _client(buildNumber: '');
      final versions = await client.getNewVersions(force: true);

      expect(versions, hasLength(1));
    });

    test('does not throw when version already contains build metadata', () async {
      final client = await _client(version: '10.0.0+5');
      final versions = await client.getNewVersions(force: true);

      expect(versions, hasLength(1));
    });

    test('hides releases newer than 7 days for store installs', () async {
      final recent = DateTime.now().subtract(const Duration(days: 1));
      final client = await _client(
        source: Source.IS_INSTALLED_FROM_PLAY_STORE,
        body: _apiResponse(date: recent.toIso8601String()),
      );
      final versions = await client.getNewVersions(force: true);

      expect(versions, isEmpty);
    });

    test('shows releases older than 7 days for store installs', () async {
      final old = DateTime.now().subtract(const Duration(days: 30));
      final client = await _client(
        source: Source.IS_INSTALLED_FROM_PLAY_STORE,
        body: _apiResponse(date: old.toIso8601String()),
      );
      final versions = await client.getNewVersions(force: true);

      expect(versions, hasLength(1));
    });
  });

  group('AppInfoClient.getDownloadUrl', () {
    test('returns a desktop download URL on Linux', () async {
      if (!Platform.isLinux) return;
      final client = await _client();
      final url = await client.getDownloadUrl();

      expect(url, 'https://example.com/kilt-linux-x64.AppImage');
    });

    test('returns null when downloads are disabled', () async {
      final client = await _client(
        body: _apiResponse(downloadsDisabled: true),
      );
      final url = await client.getDownloadUrl();

      expect(url, isNull);
    });
  });

  group('followsBackgroundTaskKey', () {
    test('matches an iOS BGTaskSchedulerPermittedIdentifiers entry', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('<string>$followsBackgroundTaskKey</string>'));
    });
  });
}
