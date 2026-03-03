import 'package:klit/client/client.dart';
import 'package:klit/identity/identity.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';

class UserDrawerHeader extends StatelessWidget {
  const UserDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Client>(
      builder: (context, client, child) =>
          const DrawerHeader(child: Center(child: CurrentIdentityTile())),
    );
  }
}
