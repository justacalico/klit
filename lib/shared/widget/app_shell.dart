import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    this.appBar,
    this.endDrawer,
    this.floatingActionButton,
    this.showFavorites = true,
    this.showHistory = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final bool showFavorites;
  final bool showHistory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < mobileBreakpoint;
        final layoutWidth = constraints.maxWidth;
        return AdaptiveScaffold(
          appBar: appBar,
          extendBody: isMobile,
          body: isMobile
              ? body
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ResponsiveNavbar(
                      placement: NavbarPlacement.sidebar,
                      showFavorites: showFavorites,
                      showHistory: showHistory,
                      layoutWidth: layoutWidth,
                    ),
                    Expanded(child: body),
                  ],
                ),
          bottomNavigationBar: isMobile
              ? ResponsiveNavbar(
                  placement: NavbarPlacement.bottom,
                  showFavorites: showFavorites,
                  showHistory: showHistory,
                )
              : null,
          endDrawer: endDrawer,
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}
