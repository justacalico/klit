import 'package:flutter/cupertino.dart';

import '../../presentation/desktop/pages/desktop_profile_page.dart';

/// Unified profile page - uses desktop layout for both.
class UiProfilePage extends StatelessWidget {
  final void Function(String route)? onNavigate;

  const UiProfilePage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return DesktopProfilePage(
      onNavigate: onNavigate ?? ((r) => Navigator.of(context).pushNamed(r)),
    );
  }
}
