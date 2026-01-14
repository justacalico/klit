import 'package:flutter/cupertino.dart';
import '../../../app/routes.dart';
import '../../desktop/pages/desktop_favorites_page.dart';
import '../../desktop/responsive_layout.dart';
import 'favorites_page.dart';

/// Responsive wrapper that switches between mobile and desktop favorites views
/// based on screen size. This allows live switching when resizing the window.
class ResponsiveFavoritesPage extends StatelessWidget {
  const ResponsiveFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use desktop layout for screens wider than desktop breakpoint
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return DesktopFavoritesPage(
            onPostTap: (args) {
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.postDetail, arguments: args);
            },
          );
        }

        // Use mobile layout for smaller screens
        return const FavoritesPage();
      },
    );
  }
}
