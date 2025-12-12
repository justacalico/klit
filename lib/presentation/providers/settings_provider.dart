import 'package:flutter/cupertino.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';

/// Callback type for when proxy configuration changes
typedef ProxyChangeCallback = void Function(ProxyConfig config);

/// Provider for app settings
class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;

  int _themeMode = 0; // 0 = system, 1 = light, 2 = dark
  int _gridSize = AppConstants.defaultGridColumns;
  bool _safeMode = false;
  bool _leftHandedMode = false;
  bool _upvoteWhenFavorited = true;
  String _host = ApiConstants.defaultHost;
  List<SearchHistoryItem> _searchHistory = [];
  ProxyConfig _proxyConfig = const ProxyConfig();
  String _blacklist = '';
  bool _blacklistEnabled = true;

  /// Callback to notify when proxy configuration changes
  ProxyChangeCallback? onProxyChanged;

  SettingsProvider({required StorageService storageService})
      : _storageService = storageService;

  // Getters
  int get themeMode => _themeMode;
  int get gridSize => _gridSize;
  bool get safeMode => _safeMode;
  bool get leftHandedMode => _leftHandedMode;
  bool get upvoteWhenFavorited => _upvoteWhenFavorited;
  String get host => _host;
  List<SearchHistoryItem> get searchHistory => _searchHistory;
  ProxyConfig get proxyConfig => _proxyConfig;
  String get blacklist => _blacklist;
  bool get blacklistEnabled => _blacklistEnabled;

  /// Get blacklist as a list of tag queries (each line is a filter)
  List<String> get blacklistLines {
    if (_blacklist.isEmpty) return [];
    return _blacklist
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
  }

  /// Initialize settings from storage
  Future<void> initialize() async {
    _themeMode = _storageService.getThemeMode();
    _gridSize = _storageService.getGridSize();
    _safeMode = _storageService.getSafeMode();
    _leftHandedMode = _storageService.getLeftHandedMode();
    _upvoteWhenFavorited = _storageService.getUpvoteWhenFavorited();
    _host = _storageService.getHost();
    _searchHistory = _storageService.getSearchHistory();
    _proxyConfig = _storageService.getProxyConfig();
    _blacklist = _storageService.getBlacklist();
    _blacklistEnabled = _storageService.getBlacklistEnabled();
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(int mode) async {
    _themeMode = mode;
    await _storageService.setThemeMode(mode);
    notifyListeners();
  }

  /// Set grid size
  Future<void> setGridSize(int size) async {
    _gridSize = size.clamp(
      AppConstants.minGridColumns,
      AppConstants.maxGridColumns,
    );
    await _storageService.setGridSize(_gridSize);
    notifyListeners();
  }

  /// Toggle safe mode
  Future<void> setSafeMode(bool enabled) async {
    _safeMode = enabled;
    await _storageService.setSafeMode(enabled);
    notifyListeners();
  }

  /// Toggle left-handed mode
  Future<void> setLeftHandedMode(bool enabled) async {
    _leftHandedMode = enabled;
    await _storageService.setLeftHandedMode(enabled);
    notifyListeners();
  }

  /// Toggle upvote when favorited
  Future<void> setUpvoteWhenFavorited(bool enabled) async {
    _upvoteWhenFavorited = enabled;
    await _storageService.setUpvoteWhenFavorited(enabled);
    notifyListeners();
  }

  /// Set API host
  Future<void> setHost(String host) async {
    _host = host;
    await _storageService.setHost(host);
    notifyListeners();
  }

  /// Add to search history
  Future<void> addToSearchHistory(String query) async {
    await _storageService.addToSearchHistory(query);
    _searchHistory = _storageService.getSearchHistory();
    notifyListeners();
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    await _storageService.clearSearchHistory();
    _searchHistory = [];
    notifyListeners();
  }

  /// Set proxy configuration
  Future<void> setProxyConfig(ProxyConfig config) async {
    _proxyConfig = config;
    await _storageService.setProxyConfig(config);
    onProxyChanged?.call(config);
    notifyListeners();
  }

  /// Enable/disable proxy
  Future<void> setProxyEnabled(bool enabled) async {
    await setProxyConfig(_proxyConfig.copyWith(enabled: enabled));
  }

  /// Set proxy host
  Future<void> setProxyHost(String host) async {
    await setProxyConfig(_proxyConfig.copyWith(host: host));
  }

  /// Set proxy port
  Future<void> setProxyPort(int port) async {
    await setProxyConfig(_proxyConfig.copyWith(port: port));
  }

  /// Set proxy authentication
  Future<void> setProxyAuthentication({
    required bool useAuthentication,
    String? username,
    String? password,
  }) async {
    await setProxyConfig(_proxyConfig.copyWith(
      useAuthentication: useAuthentication,
      username: username,
      password: password,
    ));
  }

  /// Set blacklist (raw string with newlines)
  Future<void> setBlacklist(String blacklist) async {
    _blacklist = blacklist;
    await _storageService.setBlacklist(blacklist);
    notifyListeners();
  }

  /// Set blacklist enabled
  Future<void> setBlacklistEnabled(bool enabled) async {
    _blacklistEnabled = enabled;
    await _storageService.setBlacklistEnabled(enabled);
    notifyListeners();
  }

  /// Clear all preferences (not accounts)
  Future<void> clearPreferences() async {
    await _storageService.clearPreferences();
    await initialize();
  }
}
