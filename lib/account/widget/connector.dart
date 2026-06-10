import 'package:kilt/account/account.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';

class AccountConnector extends StatelessWidget {
  const AccountConnector({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final client = context.watch<Client>();
    return AvailabilityCheck(
      navigatorKey: navigatorKey,
      child: SubEffect(
        effect: () {
          client.accounts.pull(force: true);
          return null;
        },
        keys: [client],
        child: SubValueListener(
          listenable: client.traits,
          listener: (traits) => client.accounts.push(traits: traits),
          builder: (context, _) => child,
        ),
      ),
    );
  }
}
