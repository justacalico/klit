import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'theme.dart';
import '../presentation/providers/providers.dart';

/// Main application widget
class KlitApp extends StatelessWidget {
  const KlitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return CupertinoApp(
          title: 'Klit',
          debugShowCheckedModeBanner: false,
          theme: _getTheme(settings.themeMode),
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: AppRoutes.login,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
          ],
        );
      },
    );
  }

  CupertinoThemeData _getTheme(int themeMode) {
    switch (themeMode) {
      case 1:
        return AppTheme.lightTheme;
      case 2:
        return AppTheme.darkTheme;
      default:
        // System theme - use light as default, actual will be determined by MediaQuery
        return AppTheme.lightTheme;
    }
  }
}
