// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/topic/topic.dart';

extension Link on Topic {
  String get link => '/forum_topics/$id';
}
