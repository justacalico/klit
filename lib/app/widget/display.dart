import 'package:klit/app/app.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:secure_app_switcher/secure_app_switcher.dart';

class SecureDisplay extends StatelessWidget {
  const SecureDisplay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SubValueListener(
      initialize: true,
      listenable: context.watch<Settings>().secureDisplay,
      listener: (value) {
        if (!PlatformCapabilities.hasSecureDisplay) return;
        if (value) {
          SecureAppSwitcher.on();
        } else {
          SecureAppSwitcher.off();
        }
      },
      builder: (context, value) => child,
    );
  }
}
