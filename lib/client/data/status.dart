// SPDX-License-Identifier: AGPL-3.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kilt/traits/traits.dart';

part 'status.freezed.dart';
part 'status.g.dart';

@freezed
abstract class ClientSyncStatus with _$ClientSyncStatus {
  const factory ClientSyncStatus({DenyListSyncStatus? denyList}) =
      _ClientSyncStatus;

  factory ClientSyncStatus.fromJson(Map<String, dynamic> json) =>
      _$ClientSyncStatusFromJson(json);
}
