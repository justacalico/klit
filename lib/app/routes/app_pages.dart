import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/app/widget/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.home, page: () => const MainShell()),
    GetPage(
      name: AppRoutes.hot,
      page: () => _RedirectToShell(AppRoutes.hot),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => _RedirectToShell(AppRoutes.search),
    ),
    GetPage(
      name: AppRoutes.feeds,
      page: () => _RedirectToShell(AppRoutes.feeds),
    ),
    GetPage(
      name: AppRoutes.favorites,
      page: () => _RedirectToShell(AppRoutes.profile),
    ),
    GetPage(
      name: AppRoutes.timeline,
      page: () => _RedirectToShell(AppRoutes.timeline),
    ),
    GetPage(
      name: AppRoutes.subscriptions,
      page: () => _RedirectToShell(AppRoutes.subscriptions),
    ),
    GetPage(
      name: AppRoutes.bookmarks,
      page: () => _RedirectToShell(AppRoutes.home),
    ),
    GetPage(
      name: AppRoutes.pools,
      page: () => _RedirectToShell(AppRoutes.pools),
    ),
    GetPage(
      name: AppRoutes.forum,
      page: () => _RedirectToShell(AppRoutes.forum),
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => _RedirectToShell(AppRoutes.history),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => _RedirectToShell(AppRoutes.profile),
    ),
    GetPage(
      name: AppRoutes.blacklist,
      page: () => _RedirectToShell(AppRoutes.blacklist),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => _RedirectToShell(AppRoutes.settings),
    ),
  ];
}

class _RedirectToShell extends StatefulWidget {
  const _RedirectToShell(this.path);

  final String path;

  @override
  State<_RedirectToShell> createState() => _RedirectToShellState();
}

class _RedirectToShellState extends State<_RedirectToShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(AppRoutes.home, arguments: {'path': widget.path});
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
