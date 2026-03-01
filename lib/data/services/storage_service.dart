import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_service_platform_stub.dart'
    if (dart.library.io) 'storage_service_platform_io.dart' as platform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/constants.dart';
import '../models/models.dart';
import 'storage_parsing.dart';

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

  /// Init storage; uses SharedPreferences fallback on Linux if libsecret fails.
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    // Test if secure storage works on Linux by doing a write+read cycle
    if (platform.isLinuxPlatform) {
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

  // Account management

  Future<List<Account>> getAccounts() async {
    final accountsJson = await _secureRead(AppConstants.accountsKey);
    if (accountsJson == null) return [];
    return compute(parseAccountsJson, accountsJson);
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    final accountsJson = json.encode(accounts.map((e) => e.toJson()).toList());
    await _secureWrite(AppConstants.accountsKey, accountsJson);
  }

  Future<Account> addAccount({
    required String username,
    required String apiKey,
    required String host,
  }) async {
    final accounts = await getAccounts();
    final newId = const Uuid().v4();
    final account = Account(
      id: newId,
      username: username,
      apiKey: apiKey,
      host: host,
      createdAt: DateTime.now(),
      isActive: true,
    );

    accounts.add(account);
    try {
      await saveAccounts(accounts);
    } catch (e, _) {
      rethrow;
    }

    try {
      await setActiveAccountId(account.id);
    } catch (e, _) {
      rethrow;
    }

    return account;
  }

  Future<void> removeAccount(String accountId) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == accountId);
    await saveAccounts(accounts);

    final activeId = await getActiveAccountId();
    if (activeId == accountId) {
      await setActiveAccountId(accounts.isNotEmpty ? accounts.first.id : null);
    }
  }

  Future<String?> getActiveAccountId() async {
    return await _secureRead(AppConstants.activeAccountKey);
  }

  Future<void> setActiveAccountId(String? accountId) async {
    if (accountId == null) {
      await _secureDelete(AppConstants.activeAccountKey);
    } else {
      await _secureWrite(AppConstants.activeAccountKey, accountId);
    }
  }

  Future<Account?> getActiveAccount() async {
    final activeId = await getActiveAccountId();
    if (activeId == null) return null;

    final accounts = await getAccounts();
    return accounts.where((a) => a.id == activeId).firstOrNull;
  }

  Future<String> _accountScope() async =>
      (await getActiveAccountId()) ?? 'guest';

  // Preferences

  String getHost() {
    return _prefs.getString(AppConstants.hostKey) ?? ApiConstants.defaultHost;
  }

  Future<void> setHost(String host) async {
    await _prefs.setString(AppConstants.hostKey, host);
  }

  int getGridSize() {
    return _prefs.getInt(AppConstants.gridSizeKey) ??
        AppConstants.defaultGridColumns;
  }

  Future<void> setGridSize(int size) async {
    await _prefs.setInt(AppConstants.gridSizeKey, size);
  }

  double getGridSpacing() {
    return _prefs.getDouble(AppConstants.gridSpacingKey) ??
        AppConstants.defaultGridSpacing;
  }

  Future<void> setGridSpacing(double spacing) async {
    await _prefs.setDouble(AppConstants.gridSpacingKey, spacing);
  }

  double getGridPadding() {
    return _prefs.getDouble(AppConstants.gridPaddingKey) ??
        AppConstants.defaultGridPadding;
  }

  Future<void> setGridPadding(double padding) async {
    await _prefs.setDouble(AppConstants.gridPaddingKey, padding);
  }

  bool getGridAutoMode() {
    return _prefs.getBool(AppConstants.gridAutoModeKey) ?? true;
  }

  Future<void> setGridAutoMode(bool enabled) async {
    await _prefs.setBool(AppConstants.gridAutoModeKey, enabled);
  }

  bool getSafeMode() {
    return _prefs.getBool(AppConstants.safeModeKey) ?? false;
  }

  Future<void> setSafeMode(bool enabled) async {
    await _prefs.setBool(AppConstants.safeModeKey, enabled);
  }

  bool getLeftHandedMode() {
    return _prefs.getBool(AppConstants.leftHandedModeKey) ?? false;
  }

  Future<void> setLeftHandedMode(bool enabled) async {
    await _prefs.setBool(AppConstants.leftHandedModeKey, enabled);
  }

  bool getUpvoteWhenFavorited() {
    return _prefs.getBool(AppConstants.upvoteWhenFavoritedKey) ?? true;
  }

  Future<void> setUpvoteWhenFavorited(bool enabled) async {
    await _prefs.setBool(AppConstants.upvoteWhenFavoritedKey, enabled);
  }

  bool getConfettiOnFavorite() {
    return _prefs.getBool(AppConstants.confettiOnFavoriteKey) ?? true;
  }

  Future<void> setConfettiOnFavorite(bool enabled) async {
    await _prefs.setBool(AppConstants.confettiOnFavoriteKey, enabled);
  }

  static const List<int> _defaultMobileNavOrder = [0, 4, 5, 8, 3];
  static const List<int> _legacyMobileNavOrder = [0, 1, 2, 3, 4];
  static const List<int> _legacyMobileNavOrderWithFeeds = [0, 1, 2, 4, 5, 6, 7];
  static const List<int> _legacyMobileNavOrderNoSettings = [0, 1, 2, 4, 5, 7];
  static const List<int> _legacyMobileNavOrderFull = [0, 1, 2, 4, 5, 7, 3];
  static const List<int> _legacyMobileNavOrderFour = [0, 4, 5, 3];

  List<int> getMobileNavOrder() {
    final orderJson = _prefs.getString(AppConstants.mobileNavOrderKey);
    if (orderJson == null) return List.from(_defaultMobileNavOrder);
    final List<int> order = (json.decode(orderJson) as List<dynamic>).cast<int>();
    if (_listEquals(order, _legacyMobileNavOrder) ||
        _listEquals(order, _legacyMobileNavOrderWithFeeds) ||
        _listEquals(order, _legacyMobileNavOrderNoSettings) ||
        _listEquals(order, _legacyMobileNavOrderFull) ||
        _listEquals(order, _legacyMobileNavOrderFour)) {
      setMobileNavOrder(_defaultMobileNavOrder);
      return List.from(_defaultMobileNavOrder);
    }
    return order;
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> setMobileNavOrder(List<int> order) async {
    await _prefs.setString(AppConstants.mobileNavOrderKey, json.encode(order));
  }

  List<int> getDesktopNavOrder() {
    final orderJson = _prefs.getString(AppConstants.desktopNavOrderKey);
    if (orderJson == null) return [0, 1, 2, 4, 5, 6, 7];
    final List<dynamic> order = json.decode(orderJson);
    return order.cast<int>();
  }

  Future<void> setDesktopNavOrder(List<int> order) async {
    await _prefs.setString(AppConstants.desktopNavOrderKey, json.encode(order));
  }

  int getThemeMode() {
    return _prefs.getInt(AppConstants.themeKey) ?? 0;
  }

  Future<void> setThemeMode(int mode) async {
    await _prefs.setInt(AppConstants.themeKey, mode);
  }

  int getUIStyle() {
    return _prefs.getInt(AppConstants.uiStyleKey) ?? 1;
  }

  Future<void> setUIStyle(int style) async {
    await _prefs.setInt(AppConstants.uiStyleKey, style);
  }

  // Search history (scoped by account)

  Future<List<SearchHistoryItem>> getSearchHistory() async {
    final scope = await _accountScope();
    final key = '${AppConstants.searchHistoryKey}_$scope';
    String? historyJson = _prefs.getString(key);
    if (historyJson == null) {
      // Migrate from legacy key
      historyJson = _prefs.getString(AppConstants.searchHistoryKey);
      if (historyJson != null) {
        await _prefs.setString(key, historyJson);
        await _prefs.remove(AppConstants.searchHistoryKey);
      } else {
        return [];
      }
    }
    return compute(parseSearchHistoryJson, historyJson);
  }

  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    var history = await getSearchHistory();
    history.removeWhere((h) => h.query == query);
    history.insert(
      0,
      SearchHistoryItem(query: query, timestamp: DateTime.now()),
    );

    if (history.length > AppConstants.maxSearchHistoryItems) {
      history = history.take(AppConstants.maxSearchHistoryItems).toList();
    }

    final scope = await _accountScope();
    final key = '${AppConstants.searchHistoryKey}_$scope';
    final historyJson = json.encode(history.map((e) => e.toJson()).toList());
    await _prefs.setString(key, historyJson);
  }

  Future<void> clearSearchHistory() async {
    final scope = await _accountScope();
    final key = '${AppConstants.searchHistoryKey}_$scope';
    await _prefs.remove(key);
  }

  bool getSearchHistoryEnabled() {
    return _prefs.getBool(AppConstants.searchHistoryEnabledKey) ?? true;
  }

  Future<void> setSearchHistoryEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.searchHistoryEnabledKey, enabled);
  }

  // Feeds (global: same list for all accounts)

  /// Returns feeds from global key. On first run migrates from all scoped keys into global.
  Future<List<Feed>> getFeedsGlobal() async {
    String? feedsJson = _prefs.getString(AppConstants.feedsKey);
    if (feedsJson != null && feedsJson.isNotEmpty) {
      return compute(parseFeedsJson, feedsJson);
    }
    // Migration: merge from all scoped keys into global
    final accounts = await getAccounts();
    final scopes = <String>['guest', ...accounts.map((a) => a.id)];
    final seenIds = <String>{};
    final merged = <Feed>[];
    for (final scope in scopes) {
      final key = '${AppConstants.feedsKey}_$scope';
      final scopeJson = _prefs.getString(key);
      if (scopeJson == null) continue;
      try {
        final list = parseFeedsJson(scopeJson);
        for (final f in list) {
          if (seenIds.add(f.id)) merged.add(f);
        }
      } catch (_) {}
    }
    if (merged.isNotEmpty) {
      final list = merged.map((e) => e.toJson()).toList();
      await _prefs.setString(AppConstants.feedsKey, json.encode(list));
    }
    return merged;
  }

  Future<void> setFeedsGlobal(List<Feed> feeds) async {
    final list = feeds.map((e) => e.toJson()).toList();
    await _prefs.setString(AppConstants.feedsKey, json.encode(list));
  }

  /// Legacy account-scoped get/set (kept for reference; FeedsProvider uses global).
  Future<List<Feed>> getFeeds() async {
    final scope = await _accountScope();
    final key = '${AppConstants.feedsKey}_$scope';
    String? feedsJson = _prefs.getString(key);
    if (feedsJson == null) {
      feedsJson = _prefs.getString(AppConstants.feedsKey);
      if (feedsJson != null) {
        await _prefs.setString(key, feedsJson);
        await _prefs.remove(AppConstants.feedsKey);
      } else {
        return [];
      }
    }
    return compute(parseFeedsJson, feedsJson);
  }

  Future<void> setFeeds(List<Feed> feeds) async {
    final scope = await _accountScope();
    final key = '${AppConstants.feedsKey}_$scope';
    final list = feeds.map((e) => e.toJson()).toList();
    await _prefs.setString(key, json.encode(list));
  }

  // Proxy

  ProxyConfig getProxyConfig() {
    final proxyJson = _prefs.getString(AppConstants.proxyConfigKey);
    if (proxyJson == null) return const ProxyConfig();
    try {
      return ProxyConfig.fromJsonString(proxyJson);
    } catch (e) {
      return const ProxyConfig();
    }
  }

  Future<void> setProxyConfig(ProxyConfig config) async {
    await _prefs.setString(AppConstants.proxyConfigKey, config.toJsonString());
  }

  // Blacklist

  String getBlacklist() {
    return _prefs.getString(AppConstants.blacklistKey) ?? '';
  }

  Future<void> setBlacklist(String blacklist) async {
    await _prefs.setString(AppConstants.blacklistKey, blacklist);
  }

  bool getBlacklistEnabled() {
    return _prefs.getBool(AppConstants.blacklistEnabledKey) ?? true;
  }

  Future<void> setBlacklistEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.blacklistEnabledKey, enabled);
  }

  bool getVideoAutoPlay() {
    return _prefs.getBool(AppConstants.videoAutoPlayKey) ?? true;
  }

  Future<void> setVideoAutoPlay(bool enabled) async {
    await _prefs.setBool(AppConstants.videoAutoPlayKey, enabled);
  }

  bool getVideoMuteByDefault() {
    return _prefs.getBool(AppConstants.videoMuteByDefaultKey) ?? true;
  }

  Future<void> setVideoMuteByDefault(bool enabled) async {
    await _prefs.setBool(AppConstants.videoMuteByDefaultKey, enabled);
  }

  bool getGifAutoplay() {
    return _prefs.getBool(AppConstants.gifAutoplayKey) ?? true;
  }

  Future<void> setGifAutoplay(bool enabled) async {
    await _prefs.setBool(AppConstants.gifAutoplayKey, enabled);
  }

  int getScoreThreshold() {
    return _prefs.getInt(AppConstants.scoreThresholdKey) ??
        AppConstants.defaultScoreThreshold;
  }

  Future<void> setScoreThreshold(int threshold) async {
    await _prefs.setInt(AppConstants.scoreThresholdKey, threshold);
  }

  // I finished

  bool getIFinishedEnabled() {
    return _prefs.getBool(AppConstants.iFinishedEnabledKey) ?? false;
  }

  Future<void> setIFinishedEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.iFinishedEnabledKey, enabled);
  }

  List<IFinishedEntry> getIFinishedEntries() {
    final jsonStr = _prefs.getString(AppConstants.iFinishedPostIdsKey);
    if (jsonStr == null) return [];
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is List) {
        if (decoded.isEmpty) return [];
        final first = decoded.first;
        if (first is int) {
          return decoded
              .whereType<int>()
              .map((id) => IFinishedEntry(postId: id, imagePath: null))
              .toList();
        }
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(IFinishedEntry.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> setIFinishedEntries(List<IFinishedEntry> entries) async {
    final list =
        entries.map((e) => e.toJson()).toList();
    await _prefs.setString(
        AppConstants.iFinishedPostIdsKey, json.encode(list));
  }

  bool getIFinishedAnimationEnabled() {
    return _prefs.getBool(AppConstants.iFinishedAnimationEnabledKey) ?? true;
  }

  Future<void> setIFinishedAnimationEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.iFinishedAnimationEnabledKey, enabled);
  }

  bool getIFinishedAskPhotoEnabled() {
    return _prefs.getBool(AppConstants.iFinishedAskPhotoEnabledKey) ?? false;
  }

  Future<void> setIFinishedAskPhotoEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.iFinishedAskPhotoEnabledKey, enabled);
  }

  // Cache

  Future<void> clearPreferences() async {
    await _prefs.clear();
  }

  Future<void> clearAll() async {
    await _prefs.clear();
    await _secureDeleteAll();
  }
}
