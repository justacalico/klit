import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/traits/traits.dart';
import 'package:flutter/foundation.dart';

class ClientConfig {
  ClientConfig({
    required this.identity,
    required this.traits,
    required this.storage,
  });

  final Identity identity;
  final ValueNotifier<Traits> traits;
  final AppStorage storage;
}

const String _e621Host = 'https://e621.net';
const String _e926Host = 'https://e926.net';

class ClientFactory {
  Client create(ClientConfig config) => Client(
    identity: config.identity,
    traits: config.traits,
    storage: config.storage,
  );

  IdentityRequest createDefaultIdentity() {
    return const IdentityRequest(host: _e926Host);
  }

  TraitsRequest createDefaultTraits(Identity identity) {
    return switch (normalizeHostUrl(identity.host)) {
      _e621Host || _e926Host => TraitsRequest(
        identity: identity.id,
        denylist: [
          'gore',
          'blood',
          'feces',
          'gun',
          'weapon',
          'knife',
          'scat',
          'poop',
        ],
        homeTags: 'score:>=20',
        writeHistory: false,
      ),
      _ => TraitsRequest(identity: identity.id),
    };
  }

  String? registrationUrl(String host) {
    final base = normalizeHostUrl(host);
    return base.isNotEmpty ? '$base/users/new' : null;
  }

  String? apiKeysUrl(String host, String username) {
    if (username.isEmpty) return null;
    final base = normalizeHostUrl(host);
    return base.isNotEmpty ? '$base/users/$username/api_key' : null;
  }

  String? unsafeHostUrl(String host) {
    return switch (normalizeHostUrl(host)) {
      _e926Host => _e621Host,
      _ => null,
    };
  }
}
