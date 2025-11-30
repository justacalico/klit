import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'data/services/services.dart';
import 'presentation/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final apiService = ApiService();
  final authService = AuthService(
    apiService: apiService,
    storageService: storageService,
  );

  // Initialize providers
  final settingsProvider = SettingsProvider(storageService: storageService);
  await settingsProvider.initialize();

  final authProvider = AuthProvider(authService: authService);
  final postsProvider = PostsProvider(apiService: apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<PostsProvider>.value(value: postsProvider),
      ],
      child: const KlitApp(),
    ),
  );
}
