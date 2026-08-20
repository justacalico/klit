// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/user/user.dart';

extension Linking on User {
  String get link => '/users/$name';
}
