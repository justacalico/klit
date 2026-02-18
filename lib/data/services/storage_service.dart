import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/constants.dart';
import '../models/models.dart';

/// Service for secure storage operations
/// Falls back to SharedPreferences on Linux if libsecret fails
class StorageService {
  final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;
  bool _initialized = false;
  bool _useSecureStorageFallback = false;

  // Prefix for fallback storage keys to avoid conflicts
  static const String _fallbackPrefix = 'secure_fallback_';

  StorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialize the storage service
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    // Test if secure storage works on Linux by doing a write+read cycle
    // Reading alone may not detect libsecret failures
    if (Platform.isLinux) {
      try {
        const testKey = '_klit_secure_storage_test_';
        const testValue = 'test_value';
        await _secureStorage.write(key: testKey, value: testValue);
        final readValue = await _secureStorage.read(key: testKey);
        await _secureStorage.delete(key: testKey);
        // If write succeeded but read returned different value, storage is broken
        if (readValue != testValue) {
          _useSecureStorageFallback = true;
        }
      } catch (e) {
        // Any error (PlatformException, etc.) means libsecret failed
        _useSecureStorageFallback = true;
      }
    }

    _initialized = true;
  }

  /// Read from secure storage with fallback
  Future<String?> _secureRead(String key) async {
    if (_useSecureStorageFallback) {
      return _prefs.getString('$_fallbackPrefix$key');
    }
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      // Fallback for unexpected failures (PlatformException, etc.)
      _useSecureStorageFallback = true;
      return _prefs.getString('$_fallbackPrefix$key');
    }
  }

  /// Write to secure storage with fallback
  Future<void> _secureWrite(String key, String value) async {
    if (_useSecureStorageFallback) {
      await _prefs.setString('$_fallbackPrefix$key', value);
      return;
    }
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      // Fallback for unexpected failures (PlatformException, etc.)
      _useSecureStorageFallback = true;
      await _prefs.setString('$_fallbackPrefix$key', value);
    }
  }

  /// Delete from secure storage with fallback
  Future<void> _secureDelete(String key) async {
    if (_useSecureStorageFallback) {
      await _prefs.remove('$_fallbackPrefix$key');
      return;
    }
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      // Fallback for unexpected failures (PlatformException, etc.)
      _useSecureStorageFallback = true;
      await _prefs.remove('$_fallbackPrefix$key');
    }
  }

  /// Delete all from secure storage with fallback
  Future<void> _secureDeleteAll() async {
    if (_useSecureStorageFallback) {
      final keys = _prefs
          .getKeys()
          .where((k) => k.startsWith(_fallbackPrefix))
          .toList();
      for (final key in keys) {
        await _prefs.remove(key);
      }
      return;
    }
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      // Fallback for unexpected failures (PlatformException, etc.)
      _useSecureStorageFallback = true;
      final keys = _prefs
          .getKeys()
          .where((k) => k.startsWith(_fallbackPrefix))
          .toList();
      for (final key in keys) {
        await _prefs.remove(key);
      }
    }
  }

  // ==================== Account Management ====================

  /// Get all stored accounts
  Future<List<Account>> getAccounts() async {
    final accountsJson = await _secureRead(AppConstants.accountsKey);
    if (accountsJson == null) return [];

    final List<dynamic> accountsList = json.decode(accountsJson);
    return accountsList
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Save accounts to secure storage
  Future<void> saveAccounts(List<Account> accounts) async {
    final accountsJson = json.encode(accounts.map((e) => e.toJson()).toList());
    await _secureWrite(AppConstants.accountsKey, accountsJson);
  }

  /// Add a new account
  Future<Account> addAccount({
    required String username,
    required String apiKey,
    required String host,
  }) async {
    if (kDebugMode) {
      print('\n---------- StorageService.addAccount START ----------');
      print('StorageService.addAccount: username=$username');
      print('StorageService.addAccount: host=$host');
      print('StorageService.addAccount: Getting existing accounts...');
    }
    final accounts = await getAccounts();
    if (kDebugMode) {
      print('StorageService.addAccount: Existing accounts count=${accounts.length}');
      for (var i = 0; i < accounts.length; i++) {
        print('StorageService.addAccount: Existing[$i]: id=${accounts[i].id}, username=${accounts[i].username}');
      }
    }

    final newId = const Uuid().v4();
    if (kDebugMode) {
      print('StorageService.addAccount: Generated new account ID=$newId');
    }

    final account = Account(
      id: newId,
      username: username,
      apiKey: apiKey,
      host: host,
      createdAt: DateTime.now(),
      isActive: true,
    );

    accounts.add(account);
    if (kDebugMode) {
      print('StorageService.addAccount: Accounts list now has ${accounts.length} accounts');
      print('StorageService.addAccount: Saving accounts to storage...');
    }

    try {
      await saveAccounts(accounts);
      if (kDebugMode) {
        print('StorageService.addAccount: saveAccounts completed!');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('StorageService.addAccount: ERROR in saveAccounts!');
        print('StorageService.addAccount: Exception=$e');
        print('StorageService.addAccount: StackTrace=$stackTrace');
      }
      rethrow;
    }

    // Always set new account as active
    if (kDebugMode) {
      print('StorageService.addAccount: Setting active account ID=${account.id}');
    }
    try {
      await setActiveAccountId(account.id);
      if (kDebugMode) {
        print('StorageService.addAccount: setActiveAccountId completed!');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('StorageService.addAccount: ERROR in setActiveAccountId!');
        print('StorageService.addAccount: Exception=$e');
        print('StorageService.addAccount: StackTrace=$stackTrace');
      }
      rethrow;
    }

    // Verify the save worked
    if (kDebugMode) {
      print('StorageService.addAccount: Verifying save...');
      final verifyAccounts = await getAccounts();
      print('StorageService.addAccount: Verified accounts count=${verifyAccounts.length}');
      final verifyActiveId = await getActiveAccountId();
      print('StorageService.addAccount: Verified active ID=$verifyActiveId');
      print('---------- StorageService.addAccount END ----------\n');
    }

    return account;
  }

  /// Remove an account
  Future<void> removeAccount(String accountId) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == accountId);
    await saveAccounts(accounts);

    final activeId = await getActiveAccountId();
    if (activeId == accountId) {
      await setActiveAccountId(accounts.isNotEmpty ? accounts.first.id : null);
    }
  }

  /// Get the active account ID
  Future<String?> getActiveAccountId() async {
    return await _secureRead(AppConstants.activeAccountKey);
  }

  /// Set the active account ID
  Future<void> setActiveAccountId(String? accountId) async {
    if (accountId == null) {
      await _secureDelete(AppConstants.activeAccountKey);
    } else {
      await _secureWrite(AppConstants.activeAccountKey, accountId);
    }
  }

  /// Get the active account
  Future<Account?> getActiveAccount() async {
    final activeId = await getActiveAccountId();
    if (activeId == null) return null;

    final accounts = await getAccounts();
    return accounts.where((a) => a.id == activeId).firstOrNull;
  }

  // ==================== Preferences ====================

  /// Get the API host
  String getHost() {
    return _prefs.getString(AppConstants.hostKey) ?? ApiConstants.defaultHost;
  }

  /// Set the API host
  Future<void> setHost(String host) async {
    await _prefs.setString(AppConstants.hostKey, host);
  }

  /// Get grid size
  int getGridSize() {
    return _prefs.getInt(AppConstants.gridSizeKey) ??
        AppConstants.defaultGridColumns;
  }

  /// Set grid size
  Future<void> setGridSize(int size) async {
    await _prefs.setInt(AppConstants.gridSizeKey, size);
  }

  /// Get grid spacing
  double getGridSpacing() {
    return _prefs.getDouble(AppConstants.gridSpacingKey) ??
        AppConstants.defaultGridSpacing;
  }

  /// Set grid spacing
  Future<void> setGridSpacing(double spacing) async {
    await _prefs.setDouble(AppConstants.gridSpacingKey, spacing);
  }

  /// Get grid padding
  double getGridPadding() {
    return _prefs.getDouble(AppConstants.gridPaddingKey) ??
        AppConstants.defaultGridPadding;
  }

  /// Set grid padding
  Future<void> setGridPadding(double padding) async {
    await _prefs.setDouble(AppConstants.gridPaddingKey, padding);
  }

  /// Get grid auto mode
  bool getGridAutoMode() {
    return _prefs.getBool(AppConstants.gridAutoModeKey) ?? true;
  }

  /// Set grid auto mode
  Future<void> setGridAutoMode(bool enabled) async {
    await _prefs.setBool(AppConstants.gridAutoModeKey, enabled);
  }

  /// Get safe mode setting
  bool getSafeMode() {
    return _prefs.getBool(AppConstants.safeModeKey) ?? false;
  }

  /// Set safe mode setting
  Future<void> setSafeMode(bool enabled) async {
    await _prefs.setBool(AppConstants.safeModeKey, enabled);
  }

  /// Get left-handed mode setting
  bool getLeftHandedMode() {
    return _prefs.getBool(AppConstants.leftHandedModeKey) ?? false;
  }

  /// Set left-handed mode setting
  Future<void> setLeftHandedMode(bool enabled) async {
    await _prefs.setBool(AppConstants.leftHandedModeKey, enabled);
  }

  /// Get upvote when favorited setting
  bool getUpvoteWhenFavorited() {
    return _prefs.getBool(AppConstants.upvoteWhenFavoritedKey) ?? true;
  }

  /// Set upvote when favorited setting
  Future<void> setUpvoteWhenFavorited(bool enabled) async {
    await _prefs.setBool(AppConstants.upvoteWhenFavoritedKey, enabled);
  }

  /// Get confetti on favorite setting
  bool getConfettiOnFavorite() {
    return _prefs.getBool(AppConstants.confettiOnFavoriteKey) ?? true;
  }

  /// Set confetti on favorite setting
  Future<void> setConfettiOnFavorite(bool enabled) async {
    await _prefs.setBool(AppConstants.confettiOnFavoriteKey, enabled);
  }

  /// Get mobile navigation order (list of tab IDs)
  /// Default order: [0, 1, 2, 3, 4] = [Home, Hot, Popular, Profile, Settings]
  List<int> getMobileNavOrder() {
    final orderJson = _prefs.getString(AppConstants.mobileNavOrderKey);
    if (orderJson == null) return [0, 1, 2, 3, 4];
    final List<dynamic> order = json.decode(orderJson);
    return order.cast<int>();
  }

  /// Set mobile navigation order
  Future<void> setMobileNavOrder(List<int> order) async {
    await _prefs.setString(AppConstants.mobileNavOrderKey, json.encode(order));
  }

  /// Get desktop navigation order (list of tab IDs)
  /// Default order: [0, 1, 2, 4, 5, 6] = [Home, Hot, Popular, Search, Profile, Favorites]
  List<int> getDesktopNavOrder() {
    final orderJson = _prefs.getString(AppConstants.desktopNavOrderKey);
    if (orderJson == null) return [0, 1, 2, 4, 5, 6];
    final List<dynamic> order = json.decode(orderJson);
    return order.cast<int>();
  }

  /// Set desktop navigation order
  Future<void> setDesktopNavOrder(List<int> order) async {
    await _prefs.setString(AppConstants.desktopNavOrderKey, json.encode(order));
  }

  /// Get theme mode (0 = system, 1 = light, 2 = dark)
  int getThemeMode() {
    return _prefs.getInt(AppConstants.themeKey) ?? 0;
  }

  /// Set theme mode
  Future<void> setThemeMode(int mode) async {
    await _prefs.setInt(AppConstants.themeKey, mode);
  }

  /// Get UI style (0 = liquid glass, 1 = material)
  int getUIStyle() {
    return _prefs.getInt(AppConstants.uiStyleKey) ?? 1;
  }

  /// Set UI style
  Future<void> setUIStyle(int style) async {
    await _prefs.setInt(AppConstants.uiStyleKey, style);
  }

  // ==================== Search History ====================

  /// Get search history
  List<SearchHistoryItem> getSearchHistory() {
    final historyJson = _prefs.getString(AppConstants.searchHistoryKey);
    if (historyJson == null) return [];

    final List<dynamic> historyList = json.decode(historyJson);
    return historyList
        .map((e) => SearchHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Add to search history
  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    var history = getSearchHistory();
    history.removeWhere((h) => h.query == query);
    history.insert(
      0,
      SearchHistoryItem(query: query, timestamp: DateTime.now()),
    );

    if (history.length > AppConstants.maxSearchHistoryItems) {
      history = history.take(AppConstants.maxSearchHistoryItems).toList();
    }

    final historyJson = json.encode(history.map((e) => e.toJson()).toList());
    await _prefs.setString(AppConstants.searchHistoryKey, historyJson);
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    await _prefs.remove(AppConstants.searchHistoryKey);
  }

  /// Get search history enabled
  bool getSearchHistoryEnabled() {
    return _prefs.getBool(AppConstants.searchHistoryEnabledKey) ?? true;
  }

  /// Set search history enabled
  Future<void> setSearchHistoryEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.searchHistoryEnabledKey, enabled);
  }

  // ==================== Proxy Configuration ====================

  /// Get proxy configuration
  ProxyConfig getProxyConfig() {
    final proxyJson = _prefs.getString(AppConstants.proxyConfigKey);
    if (proxyJson == null) return const ProxyConfig();
    try {
      return ProxyConfig.fromJsonString(proxyJson);
    } catch (e) {
      return const ProxyConfig();
    }
  }

  /// Set proxy configuration
  Future<void> setProxyConfig(ProxyConfig config) async {
    await _prefs.setString(AppConstants.proxyConfigKey, config.toJsonString());
  }

  // ==================== Blacklist Configuration ====================

  /// Get user blacklist (raw string with newlines)
  String getBlacklist() {
    return _prefs.getString(AppConstants.blacklistKey) ?? '';
  }

  /// Set user blacklist
  Future<void> setBlacklist(String blacklist) async {
    await _prefs.setString(AppConstants.blacklistKey, blacklist);
  }

  /// Get whether blacklist is enabled
  bool getBlacklistEnabled() {
    return _prefs.getBool(AppConstants.blacklistEnabledKey) ?? true;
  }

  /// Set whether blacklist is enabled
  Future<void> setBlacklistEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.blacklistEnabledKey, enabled);
  }

  /// Get video auto play setting
  bool getVideoAutoPlay() {
    return _prefs.getBool(AppConstants.videoAutoPlayKey) ?? true;
  }

  /// Set video auto play setting
  Future<void> setVideoAutoPlay(bool enabled) async {
    await _prefs.setBool(AppConstants.videoAutoPlayKey, enabled);
  }

  /// Get video mute by default setting
  bool getVideoMuteByDefault() {
    return _prefs.getBool(AppConstants.videoMuteByDefaultKey) ?? true;
  }

  /// Set video mute by default setting
  Future<void> setVideoMuteByDefault(bool enabled) async {
    await _prefs.setBool(AppConstants.videoMuteByDefaultKey, enabled);
  }

  /// Get score threshold for latest posts
  int getScoreThreshold() {
    return _prefs.getInt(AppConstants.scoreThresholdKey) ??
        AppConstants.defaultScoreThreshold;
  }

  /// Set score threshold for latest posts
  Future<void> setScoreThreshold(int threshold) async {
    await _prefs.setInt(AppConstants.scoreThresholdKey, threshold);
  }

  // ==================== Cache Management ====================

  /// Clear all preferences (not secure storage)
  Future<void> clearPreferences() async {
    await _prefs.clear();
  }

  /// Clear all data including accounts
  Future<void> clearAll() async {
    await _prefs.clear();
    await _secureDeleteAll();
  }
}
