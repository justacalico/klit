import 'package:flutter/cupertino.dart';

import '../../presentation/desktop/pages/desktop_settings_page.dart';

/// Unified settings page - uses desktop layout for both.
class UiSettingsPage extends StatelessWidget {
  final void Function(String route)? onNavigate;

  const UiSettingsPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return DesktopSettingsPage(
      onNavigate: onNavigate ?? ((r) => Navigator.of(context).pushNamed(r)),
    );
  }
}
