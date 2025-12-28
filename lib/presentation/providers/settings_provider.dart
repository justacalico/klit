import 'package:flutter/cupertino.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/ui_style_manager.dart';
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
  bool _confettiOnFavorite = true;
  List<int> _mobileNavOrder = [0, 1, 2, 3, 4];
  List<int> _desktopNavOrder = [0, 1, 2, 4, 5, 6];
  String _host = ApiConstants.defaultHost;
  List<SearchHistoryItem> _searchHistory = [];
  ProxyConfig _proxyConfig = const ProxyConfig();
  String _blacklist = '';
  bool _blacklistEnabled = true;
  UIStyle _uiStyle = UIStyle.liquidGlass;

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
  bool get confettiOnFavorite => _confettiOnFavorite;
  List<int> get mobileNavOrder => _mobileNavOrder;
  List<int> get desktopNavOrder => _desktopNavOrder;
  String get host => _host;
  List<SearchHistoryItem> get searchHistory => _searchHistory;
  ProxyConfig get proxyConfig => _proxyConfig;
  String get blacklist => _blacklist;
  bool get blacklistEnabled => _blacklistEnabled;
  UIStyle get uiStyle => _uiStyle;

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
    _confettiOnFavorite = _storageService.getConfettiOnFavorite();
    _mobileNavOrder = _storageService.getMobileNavOrder();
    _desktopNavOrder = _storageService.getDesktopNavOrder();
    _host = _storageService.getHost();
    _searchHistory = _storageService.getSearchHistory();
    _proxyConfig = _storageService.getProxyConfig();
    _blacklist = _storageService.getBlacklist();
    _blacklistEnabled = _storageService.getBlacklistEnabled();
    _uiStyle = UIStyle.values[_storageService.getUIStyle().clamp(0, UIStyle.values.length - 1)];
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

  /// Toggle confetti on favorite
  Future<void> setConfettiOnFavorite(bool enabled) async {
    _confettiOnFavorite = enabled;
    await _storageService.setConfettiOnFavorite(enabled);
    notifyListeners();
  }

  /// Set mobile navigation order
  Future<void> setMobileNavOrder(List<int> order) async {
    _mobileNavOrder = order;
    await _storageService.setMobileNavOrder(order);
    notifyListeners();
  }

  /// Set desktop navigation order
  Future<void> setDesktopNavOrder(List<int> order) async {
    _desktopNavOrder = order;
    await _storageService.setDesktopNavOrder(order);
    notifyListeners();
  }

  /// Reset mobile navigation order to default
  Future<void> resetMobileNavOrder() async {
    await setMobileNavOrder([0, 1, 2, 3, 4]);
  }

  /// Reset desktop navigation order to default
  Future<void> resetDesktopNavOrder() async {
    await setDesktopNavOrder([0, 1, 2, 4, 5, 6]);
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

  /// Set UI style (liquid glass or material)
  Future<void> setUIStyle(UIStyle style) async {
    _uiStyle = style;
    await _storageService.setUIStyle(style.index);
    notifyListeners();
  }

  /// Clear all preferences (not accounts)
  Future<void> clearPreferences() async {
    await _storageService.clearPreferences();
    await initialize();
  }
}
