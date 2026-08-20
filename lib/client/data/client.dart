// SPDX-License-Identifier: AGPL-3.0

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kilt/account/account.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/comment/comment.dart';
import 'package:kilt/finish/finish.dart';
import 'package:kilt/flag/flag.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/pool/pool.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/reply/reply.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:kilt/ticket/ticket.dart';
import 'package:kilt/topic/topic.dart';
import 'package:kilt/traits/traits.dart';
import 'package:kilt/user/user.dart';
import 'package:kilt/wiki/wiki.dart';

export 'package:dio/dio.dart' show CancelToken;

/// A facade around [ClientServices] for a single identity.
///
/// [Client] owns the network [Dio] instance and the collection of services,
/// but the construction and disposal of individual service clients is handled
/// by [ClientServices].
class Client with Disposable {
  Client({required this.identity, required this.traits, required this.storage})
    : dio = createDefaultDio(identity, cache: storage.httpCache) {
    services = ClientServices(
      dio: dio,
      storage: storage,
      identity: identity,
      traits: traits,
    );
  }

  final Dio dio;
  final AppStorage storage;
  final Identity identity;
  final ValueNotifier<Traits> traits;
  late final ClientServices services;

  AccountClient get accounts => services.accounts;
  UserClient get users => services.users;
  PostClient get posts => services.posts;
  TagClient get tags => services.tags;
  WikiClient get wikis => services.wikis;
  CommentClient get comments => services.comments;
  PoolClient get pools => services.pools;
  TopicClient get topics => services.topics;
  ReplyClient get replies => services.replies;
  FlagClient get flags => services.flags;
  TicketClient get tickets => services.tickets;
  FollowClient get follows => services.follows;
  FollowServer get followServer => services.followServer;
  HistoryServer get historyServer => services.historyServer;
  HistoryClient get histories => services.histories;
  FinishServer get finishes => services.finishes;

  @override
  void dispose() {
    dio.close();
    services.dispose();
    super.dispose();
  }
}

extension ClientExtension on Client {
  String get host => identity.host;
  bool get hasLogin => identity.username != null;
  String withHost(String path) => identity.withHost(path);
}
