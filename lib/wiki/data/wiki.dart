// SPDX-License-Identifier: AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'wiki.freezed.dart';
part 'wiki.g.dart';

@freezed
abstract class Wiki with _$Wiki {
  const factory Wiki({
    required int id,
    required String title,
    required String body,
    required DateTime createdAt,
    DateTime? updatedAt,
    List<String>? otherNames,
    bool? isLocked,
  }) = _Wiki;

  factory Wiki.fromJson(Map<String, dynamic> json) => _$WikiFromJson(json);
}
