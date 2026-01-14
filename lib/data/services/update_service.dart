import 'package:dio/dio.dart';

/// Response model for the Openlyst API latest version endpoint
class LatestVersionResponse {
  final bool success;
  final String? appName;
  final String? appSlug;
  final VersionData? data;
  final String? error;

  LatestVersionResponse({
    required this.success,
    this.appName,
    this.appSlug,
    this.data,
    this.error,
  });

  factory LatestVersionResponse.fromJson(Map<String, dynamic> json) {
    return LatestVersionResponse(
      success: json['success'] ?? false,
      appName: json['appName'],
      appSlug: json['appSlug'],
      data: json['data'] != null ? VersionData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

/// Version data from the API
class VersionData {
  final String version;
  final String? date;
  final List<String>? platforms;
  final Map<String, dynamic>? downloads;
  final String? sourceCode;

  VersionData({
    required this.version,
    this.date,
    this.platforms,
    this.downloads,
    this.sourceCode,
  });

  factory VersionData.fromJson(Map<String, dynamic> json) {
    return VersionData(
      version: json['version'] ?? '',
      date: json['date'],
      platforms: json['platforms'] != null 
          ? List<String>.from(json['platforms']) 
          : null,
      downloads: json['downloads'],
      sourceCode: json['sourceCode'],
    );
  }
}

/// Update check result
class UpdateCheckResult {
  final bool updateAvailable;
  final String currentVersion;
  final String? latestVersion;
  final String? error;
  final VersionData? versionData;

  UpdateCheckResult({
    required this.updateAvailable,
    required this.currentVersion,
    this.latestVersion,
    this.error,
    this.versionData,
  });
}

/// Service for checking app updates using the Openlyst API
class UpdateService {
  static const String _baseUrl = 'https://openlyst.ink/api/v1';
  static const String _appSlug = 'klit';
  
  final Dio _dio;

  UpdateService() : _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// Check for updates by comparing current version with latest from API
  Future<UpdateCheckResult> checkForUpdate(String currentVersion) async {
    try {
      final response = await _dio.get('/apps/$_appSlug/latest');
      
      if (response.statusCode == 200) {
        final data = LatestVersionResponse.fromJson(response.data);
        
        if (data.success && data.data != null) {
          final latestVersion = data.data!.version;
          final updateAvailable = _isNewerVersion(latestVersion, currentVersion);
          
          return UpdateCheckResult(
            updateAvailable: updateAvailable,
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            versionData: data.data,
          );
        } else {
          return UpdateCheckResult(
            updateAvailable: false,
            currentVersion: currentVersion,
            error: data.error ?? 'Invalid response from server',
          );
        }
      } else {
        return UpdateCheckResult(
          updateAvailable: false,
          currentVersion: currentVersion,
          error: 'Server returned status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      } else {
        errorMessage = 'Failed to check for updates: ${e.message}';
      }
      
      return UpdateCheckResult(
        updateAvailable: false,
        currentVersion: currentVersion,
        error: errorMessage,
      );
    } catch (e) {
      return UpdateCheckResult(
        updateAvailable: false,
        currentVersion: currentVersion,
        error: 'Unexpected error: $e',
      );
    }
  }

  /// Compare version strings to determine if latest is newer than current
  /// Supports semantic versioning (major.minor.patch)
  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();
      
      // Pad shorter version with zeros
      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      
      // Compare major, minor, patch
      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      
      return false; // Versions are equal
    } catch (e) {
      // If parsing fails, do string comparison
      return latest != current;
    }
  }
}
