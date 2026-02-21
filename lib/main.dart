import 'package:flutter/cupertino.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'data/services/services.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit for desktop video playback
  MediaKit.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  // Initialize settings first to get proxy config
  final settingsProvider = SettingsProvider(storageService: storageService);
  await settingsProvider.initialize();

  // Create API service with proxy configuration and initial host
  final apiService = ApiService(
    baseUrl: settingsProvider.host,
    proxyConfig: settingsProvider.proxyConfig,
  );

  // Listen for proxy changes and update API service
  settingsProvider.onProxyChanged = (config) {
    apiService.setProxyConfig(config);
  };

  final authService = AuthService(
    apiService: apiService,
    storageService: storageService,
  );

  final authProvider = AuthProvider(authService: authService);
  // Allow auth provider to control API service and initialize authentication
  authProvider.setApiService(apiService);
  await authProvider.initialize();
  final postsProvider = PostsProvider(apiService: apiService);

  // Listen for host changes - update API service and clear cached posts
  settingsProvider.onHostChanged = (host) {
    apiService.setBaseUrl(host);
    postsProvider.clearAllPosts();
  };

  // Listen for score threshold changes - reload latest posts with new threshold
  settingsProvider.onScoreThresholdChanged = (threshold) {
    postsProvider.loadLatestPosts(
      refresh: true,
      safeMode: settingsProvider.safeMode,
      scoreThreshold: threshold,
    );
  };

  // Sync blacklist from settings to posts provider
  postsProvider.updateBlacklist(
    settingsProvider.blacklistLines,
    settingsProvider.blacklistEnabled,
  );

  // Listen for settings changes to update blacklist in posts provider
  settingsProvider.addListener(() {
    postsProvider.updateBlacklist(
      settingsProvider.blacklistLines,
      settingsProvider.blacklistEnabled,
    );
  });

  // Create navigation provider for shared navigation state
  final navigationProvider = NavigationProvider();
  final feedsProvider = FeedsProvider(storageService: storageService);

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<PostsProvider>.value(value: postsProvider),
        ChangeNotifierProvider<FeedsProvider>.value(value: feedsProvider),
        ChangeNotifierProvider<NavigationProvider>.value(
          value: navigationProvider,
        ),
      ],
      child: const KlitApp(),
    ),
  );
}
