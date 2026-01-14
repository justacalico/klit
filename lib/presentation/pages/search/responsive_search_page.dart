import 'package:flutter/cupertino.dart';
import '../../../app/routes.dart';
import '../../desktop/pages/desktop_search_page.dart';
import '../../desktop/responsive_layout.dart';
import 'search_page.dart';

/// Responsive wrapper that switches between mobile and desktop search views
/// based on screen size. This allows live switching when resizing the window.
class ResponsiveSearchPage extends StatelessWidget {
  final String? initialQuery;

  const ResponsiveSearchPage({super.key, this.initialQuery});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use desktop layout for screens wider than desktop breakpoint
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return DesktopSearchPage(
            initialQuery: initialQuery,
            onPostTap: (args) {
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.postDetail, arguments: args);
            },
          );
        }

        // Use mobile layout for smaller screens
        return SearchPage(initialQuery: initialQuery);
      },
    );
  }
}
