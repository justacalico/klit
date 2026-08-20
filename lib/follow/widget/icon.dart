// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/follow/follow.dart';

extension FollowIcon on FollowType {
  Widget get icon {
    switch (this) {
      case FollowType.notify:
        return const Icon(Icons.notifications_active);
      case FollowType.update:
        return const Icon(Icons.person_add);
      case FollowType.bookmark:
        return const Icon(Icons.bookmark);
    }
  }
}
