import 'package:klit/account/account.dart';
import 'package:klit/app/app.dart';
import 'package:klit/app/app_bindings.dart';
import 'package:klit/app/routes/app_pages.dart';
import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/app/widget/initialize.dart';
import 'package:klit/feed/feed.dart';
import 'package:klit/follow/follow.dart';
import 'package:klit/logs/logs.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:get/get.dart';
import 'package:relative_time/relative_time.dart';

class App extends StatelessWidget {
  const App({super.key});

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
          if (!Get.isRegistered<SettingsController>()) {
            Get.put(
              SettingsController(context.read<Settings>()),
              permanent: true,
            );
          }
          return ValueListenableBuilder<AppTheme>(
            valueListenable: context.watch<Settings>().theme,
            builder: (context, value, child) => ExcludeSemantics(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value:
                    value.data.appBarTheme.systemOverlayStyle ??
                    const SystemUiOverlayStyle(),
                child: SubValue<GlobalKey<NavigatorState>>(
                  create: () => GlobalKey<NavigatorState>(),
                  builder: (context, navigatorKey) => GetCupertinoApp(
                    title: AppInfo.instance.appName,
                    theme: value.cupertino,
                    localizationsDelegates: const [
                      GlobalWidgetsLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                      RelativeTimeLocalizations.delegate,
                    ],
                    navigatorKey: navigatorKey,
                    initialBinding: AppBindings(),
                    initialRoute: AppRoutes.home,
                    getPages: AppPages.routes,
                    navigatorObservers: [
                      context.watch<AnyRouteObserver>(),
                      RouteLoggerObserver(),
                      MaterialApp.createMaterialHeroController(),
                    ],
                    builder: (context, child) => Theme(
                      data: value.data,
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
              ),
            ),
          );
        },
      ),
    );
  }
}
