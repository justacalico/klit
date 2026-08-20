// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/shared/shared.dart';

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
