// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/wiki/wiki.dart';

extension Linking on Wiki {
  String get link => '/wiki_pages/$title';
}
