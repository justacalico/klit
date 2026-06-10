import 'dart:io';

import 'package:deep_pick/deep_pick.dart';
import 'package:dio/dio.dart';
import 'package:kilt/logs/logs.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:pub_semver/pub_semver.dart';

const String _openlystBase = 'https://openlyst.ink/api/v1';
const String _appSlug = 'klit';

class AppInfoClient {
  AppInfoClient() {
    _dio.interceptors.add(LoggingDioInterceptor());
    _dio.interceptors.add(
      ClientCacheInterceptor(options: ClientCacheConfig(store: cache)),
    );
  }

  final AppInfo info = AppInfo.instance;
  final CacheStore? cache = MemCacheStore();
  late final Dio _dio = Dio(
    BaseOptions(headers: {HttpHeaders.userAgentHeader: info.userAgent}),
  );

  Future<List<AppVersion>> getVersions({bool force = false}) async {
    final response = await _dio.get(
      '$_openlystBase/apps/$_appSlug/latest',
      options: ClientCacheConfig(
        store: cache,
        policy: force ? CachePolicy.refresh : CachePolicy.request,
      ).toOptions(),
    );
    try {
      final root = pick(response.data);
      if (root('success').asBoolOrNull() == false) {
        throw PickException(
          'API returned success: false',
        );
      }
      final data = root('data');
      final versionPick = data('version');
      final versionStr = versionPick.asStringOrNull() ??
          versionPick.asDoubleOrNull()?.toString() ??
          versionPick.asIntOrNull()?.toString();
      if (versionStr == null || versionStr.isEmpty) {
        throw PickException('Missing or invalid version');
      }
      final dateStr = data('date').asStringOrNull();
      final platforms = data('platforms').asListOrEmpty((e) => e.asStringOrThrow());
      final binaries = platforms
          .map((p) => p == 'Android'
              ? 'apk'
              : p == 'iOS'
                  ? 'ipa'
                  : null)
          .whereType<String>()
          .toList();
      return [
        AppVersion(
          version: Version.parse(versionStr),
          name: versionStr,
          description: '',
          date: dateStr != null ? DateTime.tryParse(dateStr) : null,
          binaries: binaries.isEmpty ? null : binaries,
        ),
      ];
    } on PickException catch (e) {
      throw AppUpdaterException(
        requestOptions: response.requestOptions,
        response: response,
        error: e,
      );
    }
  }

  /// Retrieves versions which are newer than the currently installed one.
  ///
  /// If the app was installed via a store,
  /// versions newer than 7 days will be ignored.
  Future<List<AppVersion>> getNewVersions({
    bool force = false,
    bool beta = false,
  }) async {
    List<AppVersion> versions = await getVersions(force: force);
    AppVersion current = AppVersion(
      version: Version.parse('${info.version}+${info.buildNumber}'),
    );

    versions.removeWhere(
      (e) =>
          e.version.compareTo(current.version) < 1 ||
          (!beta && Version.prioritize(e.version, current.version) < 1),
    );

    String? binary;
    if (Platform.isAndroid) {
      binary = 'apk';
    } else if (Platform.isIOS) {
      binary = 'ipa';
    }
    if (binary != null) {
      versions.removeWhere((e) => !(e.binaries?.contains(binary) ?? false));
    }

    if (info.source.isFromStore) {
      versions.removeWhere(
        (e) =>
            (e.date?.isBefore(
              DateTime.now().subtract(const Duration(days: 7)),
            )) ??
            false,
      );
    }

    return versions;
  }

  /// Returns the download URL for the current platform, or null if not available.
  Future<String?> getDownloadUrl() async {
    try {
      final response = await _dio.get(
        '$_openlystBase/apps/$_appSlug/latest',
        options: ClientCacheConfig(
          store: cache,
          policy: CachePolicy.request,
        ).toOptions(),
      );
      final root = pick(response.data);
      final downloads = root('data')('downloads');
      if (Platform.isAndroid) {
        final url = downloads('Android')('apk').asStringOrNull();
        if (url != null && url.isNotEmpty) return url;
      }
      if (Platform.isIOS) {
        final url = downloads('iOS').asStringOrNull();
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (_) {}
    return null;
  }
}

class AppVersion {
  /// Represents an App version with name, description and version number.
  AppVersion({
    required this.version,
    this.name,
    this.description,
    this.date,
    this.binaries,
  });

  /// Name of this version.
  final String? name;

  /// Description of this version.
  final String? description;

  /// The version. Should follow pub.dev semver standards.
  final Version version;

  /// Date of the release.
  final DateTime? date;

  /// List of file extensions of available binaries.
  final List<String>? binaries;
}

typedef AppUpdaterException = DioException;
