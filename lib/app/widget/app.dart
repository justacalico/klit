import 'package:go_router/go_router.dart';
import 'package:klit/account/account.dart';
import 'package:klit/app/app.dart';
import 'package:klit/app/widget/initialize.dart';
import 'package:klit/feed/feed.dart';
import 'package:klit/follow/follow.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
          return ValueListenableBuilder<AppTheme>(
            valueListenable: context.watch<Settings>().theme,
            builder: (context, value, child) =>
                ValueListenableBuilder<String>(
                  valueListenable: context.watch<Settings>().accentColorHex,
                  builder: (context, accentHex, _) {
                    final accent = colorFromHex(accentHex);
                    final materialTheme = value.dataForAccent(accent);
                    final cupertinoTheme = value.cupertinoForAccent(accent);
                    return ExcludeSemantics(
                      child: AnnotatedRegion<SystemUiOverlayStyle>(
                        value:
                            materialTheme.appBarTheme.systemOverlayStyle ??
                            const SystemUiOverlayStyle(),
                        child: CupertinoApp.router(
                          title: AppInfo.instance.appName,
                          theme: cupertinoTheme,
                          scrollBehavior: AndroidStretchScrollBehaviour(),
                          localizationsDelegates: const [
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
