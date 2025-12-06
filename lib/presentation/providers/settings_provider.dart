import 'package:flutter/cupertino.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';

/// Provider for app settings
class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;

  int _themeMode = 0; // 0 = system, 1 = light, 2 = dark
  int _gridSize = AppConstants.defaultGridColumns;
  bool _safeMode = false;
  bool _leftHandedMode = false;
  bool _upvoteWhenFavorited = false;
  String _host = ApiConstants.defaultHost;
  List<SearchHistoryItem> _searchHistory = [];

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

  /// Initialize settings from storage
  Future<void> initialize() async {
    _themeMode = _storageService.getThemeMode();
    _gridSize = _storageService.getGridSize();
    _safeMode = _storageService.getSafeMode();
    _leftHandedMode = _storageService.getLeftHandedMode();
    _upvoteWhenFavorited = _storageService.getUpvoteWhenFavorited();
    _host = _storageService.getHost();
    _searchHistory = _storageService.getSearchHistory();
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

  /// Clear all preferences (not accounts)
  Future<void> clearPreferences() async {
    await _storageService.clearPreferences();
    await initialize();
  }
}
