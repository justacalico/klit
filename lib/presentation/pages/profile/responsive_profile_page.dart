import 'package:flutter/cupertino.dart';
import '../../desktop/pages/desktop_profile_page.dart';
import '../../desktop/responsive_layout.dart';
import 'profile_page.dart';

/// Responsive wrapper that switches between mobile and desktop profile views
/// based on screen size. This allows live switching when resizing the window.
class ResponsiveProfilePage extends StatelessWidget {
  const ResponsiveProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use desktop layout for screens wider than desktop breakpoint
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return DesktopProfilePage(
            onNavigate: (route) {
              Navigator.of(context).pushNamed(route);
            },
          );
        }

        // Use mobile layout for smaller screens
        return const ProfilePage();
      },
    );
  }
}
