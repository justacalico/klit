import 'package:go_router/go_router.dart';
import 'package:kilt/account/account.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/app/widget/initialize.dart';
import 'package:kilt/feed/feed.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:relative_time/relative_time.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.navigatorKey,
    required this.goRouter,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GoRouter goRouter;

  @override
  Widget build(BuildContext context) {
    return AppInit(
      child: MultiProvider(
        providers: [
          const WindowProvider(),
          AppInfoClientProvider(),
          ClientFactoryProvider(),
          SettingsProvider(),
          VideoServiceProvider(),
          AdaptiveScaffoldScope(),
          DefaultRouteObserver(),
          ChangeNotifierProvider(create: (_) => FeedsProvider()),
        ],
        builder: (context, child) {
          final settings = context.watch<Settings>();
          return ValueListenableBuilder<AppTheme>(
            valueListenable: settings.theme,
            builder: (context, value, child) =>
                ValueListenableBuilder<String>(
                  valueListenable: settings.accentColorHex,
                  builder: (context, accentHex, _) {
                    final accent = colorFromHex(accentHex);
                    final materialTheme = value.dataForAccent(accent);
                    final cupertinoTheme = value.cupertinoForAccent(accent);
                    return ExcludeSemantics(
                      child: AnnotatedRegion<SystemUiOverlayStyle>(
                        value:
                            materialTheme.appBarTheme.systemOverlayStyle ??
                            const SystemUiOverlayStyle(),
                        child: ValueListenableBuilder<String?>(
                          valueListenable: settings.localeTag,
                          builder: (context, localeTag, _) {
                            return CupertinoApp.router(
                              title: AppInfo.instance.appName,
                              theme: cupertinoTheme,
                              scrollBehavior: AndroidStretchScrollBehaviour(),
                              locale: _localeFromTag(localeTag),
                              supportedLocales: AppLocalizations.supportedLocales,
                              localizationsDelegates: const [
                                AppLocalizations.delegate,
                                GlobalWidgetsLocalizations.delegate,
                                GlobalMaterialLocalizations.delegate,
                                GlobalCupertinoLocalizations.delegate,
                                RelativeTimeLocalizations.delegate,
                              ],
                              routerConfig: goRouter,
                              builder: (context, child) => Theme(
                                data: materialTheme,
                                child: ScaffoldMessenger(
                                  child: WindowFrame(
                                    child: WindowShortcuts(
                                      navigatorKey: navigatorKey,
                                      child: SecureDisplay(
                                        child: LockScreen(
                                          child: LoadingShell(
                                            child: MultiProvider(
                                              providers: [
                                                IdentityClientProvider(),
                                                TraitsClientProvider(),
                                                ClientProvider(),
                                                CacheManagerProvider(),
                                              ],
                                              child: LoadingCore(
                                                child: ErrorNotifier(
                                                  navigatorKey: navigatorKey,
                                                  child: AccountConnector(
                                                    navigatorKey: navigatorKey,
                                                    child: FollowConnector(
                                                        child: AppLinkHandler(
                                                          navigatorKey: navigatorKey,
                                                        child: NotificationHandler(
                                                          navigatorKey: navigatorKey,
                                                          goRouter: goRouter,
                                                          child: child!,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
          );
        },
      ),
    );
  }
}

Locale? _localeFromTag(String? tag) {
  if (tag == null || tag.isEmpty) return null;
  final parts = tag.split(RegExp(r'[-_]'));
  if (parts.isEmpty) return null;
  final languageCode = parts[0];
  final countryCode = parts.length >= 2 ? parts[1] : null;
  return Locale(languageCode, countryCode);
}
