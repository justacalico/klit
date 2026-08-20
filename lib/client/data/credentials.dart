// SPDX-License-Identifier: AGPL-3.0

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'credentials.freezed.dart';

part 'credentials.g.dart';

@freezed
abstract class Credentials with _$Credentials {
  const factory Credentials({
    required String username,
    required String password,
  }) = _Credentials;

  const Credentials._();

  factory Credentials.fromJson(Map<String, dynamic> json) => _$CredentialsFromJson(json);

  String get basicAuth =>
      'Basic ${base64Encode(utf8.encode('$username:$password'))}';

  static Credentials? parse(String auth) {
    final fullBasicMatch = RegExp(
      r'Basic (?<encoded>[A-Za-z\d/=]+)',
    ).firstMatch(auth);
    if (fullBasicMatch == null) return null;
    final credentialMatch = RegExp('(?<username>.+):(?<password>.+)')
        .firstMatch(
          utf8.decode(base64Decode(fullBasicMatch.namedGroup('encoded')!)),
        );
    if (credentialMatch == null) return null;
    return Credentials(
      username: credentialMatch.namedGroup('username')!,
      password: credentialMatch.namedGroup('password')!,
    );
  }
}
