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
          theme: _getTheme(settings.themeMode, null),
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
          builder: (context, child) {
            // For system theme, we need to rebuild with actual brightness
            if (settings.themeMode == 0) {
              final brightness = MediaQuery.platformBrightnessOf(context);
              return CupertinoTheme(
                data: brightness == Brightness.dark
                    ? AppTheme.darkTheme
                    : AppTheme.lightTheme,
                child: child!,
              );
            }
            return child!;
          },
        );
      },
    );
  }

  CupertinoThemeData _getTheme(int themeMode, Brightness? platformBrightness) {
    switch (themeMode) {
      case 1:
        return AppTheme.lightTheme;
      case 2:
        return AppTheme.darkTheme;
      case 0:
      default:
        // System theme - determined by platform brightness
        if (platformBrightness == Brightness.dark) {
          return AppTheme.darkTheme;
        }
        return AppTheme.lightTheme;
    }
  }
}
