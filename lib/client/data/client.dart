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

class Client with Disposable {
  Client({required this.identity, required this.traits, required this.storage})
    : dio = createDefaultDio(identity, cache: storage.httpCache);

  final Dio dio;
  final AppStorage storage;
  final Identity identity;
  final ValueNotifier<Traits> traits;
  final List<Object?> _disposables = [];

  late final AccountClient accounts = _track(
    AccountClient(
      dio: dio,
      identity: identity,
      traits: traits,
      postsService: posts,
    ),
  );
  late final UserClient users = _track(UserClient(dio: dio));

  late final PostClient posts = _track(
    PostClient(
      dio: dio,
      identity: identity,
      poolsService: pools,
    ),
  );

  late final TagClient tags = _track(TagClient(dio: dio));
  late final WikiClient wikis = _track(WikiClient(dio: dio));

  late final CommentClient comments = _track(CommentClient(dio: dio));

  late final PoolClient pools = _track(PoolClient(dio: dio));
  // TODO: add Sets

  late final TopicClient topics = _track(TopicClient(dio: dio));
  late final ReplyClient replies = _track(ReplyClient(dio: dio));

  late final FlagClient flags = _track(FlagClient(dio: dio));
  late final TicketClient tickets = _track(TicketClient(dio: dio));

  late final FollowClient follows = _track(
    FollowClient(
      database: storage.sqlite,
      identity: identity,
    ),
  );

  late final FollowServer followServer = _track(
    FollowServer(
      database: storage.sqlite,
      identity: identity,
      traits: traits,
      postsClient: posts,
      poolsClient: pools,
      tagsClient: tags,
    ),
  );

  late final HistoryServer historyServer = _track(
    HistoryServer(
      database: storage.sqlite,
      identity: identity,
      traits: traits,
    ),
  );

  late final HistoryClient histories = _track(
    HistoryClient(server: historyServer),
  );

  late final FinishServer finishes = _track(
    FinishServer(
      database: storage.sqlite,
      identity: identity,
    ),
  );

  T _track<T>(T client) {
    _disposables.add(client);
    return client;
  }

  @override
  void dispose() {
    dio.close();
    _disposables.forEach(Disposable.tryDispose);
    super.dispose();
  }
}

extension ClientExtension on Client {
  String get host => identity.host;
  bool get hasLogin => identity.username != null;
  String withHost(String path) => identity.withHost(path);
}
