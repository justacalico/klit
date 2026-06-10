import 'package:dio/dio.dart';
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
import 'package:flutter/foundation.dart';

export 'package:dio/dio.dart' show CancelToken;

class Client with Disposable {
  Client({required this.identity, required this.traits, required this.storage})
    : dio = createDefaultDio(identity, cache: storage.httpCache);

  final Dio dio;
  final AppStorage storage;
  final Identity identity;
  final ValueNotifier<Traits> traits;

  late final AccountClient accounts = AccountClient(
    dio: dio,
    identity: identity,
    traits: traits,
    postsService: posts,
  );
  late final UserClient users = UserClient(dio: dio);

  late final PostClient posts = PostClient(
    dio: dio,
    identity: identity,
    poolsService: pools,
  );

  late final TagClient tags = TagClient(dio: dio);
  late final WikiClient wikis = WikiClient(dio: dio);

  late final CommentClient comments = CommentClient(dio: dio);

  late final PoolClient pools = PoolClient(dio: dio);
  // TODO: add Sets

  late final TopicClient topics = TopicClient(dio: dio);
  late final ReplyClient replies = ReplyClient(dio: dio);

  late final FlagClient flags = FlagClient(dio: dio);
  late final TicketClient tickets = TicketClient(dio: dio);

  late final FollowClient follows = FollowClient(
    database: storage.sqlite,
    identity: identity,
  );

  late final FollowServer followServer = FollowServer(
    database: storage.sqlite,
    identity: identity,
    traits: traits,
    postsClient: posts,
    poolsClient: pools,
    tagsClient: tags,
  );

  late final HistoryServer historyServer = HistoryServer(
    database: storage.sqlite,
    identity: identity,
    traits: traits,
  );

  late final HistoryClient histories = HistoryClient(server: historyServer);

  late final FinishServer finishes = FinishServer(
    database: storage.sqlite,
    identity: identity,
  );

  @override
  void dispose() {
    dio.close();
    for (final client in [
      accounts,
      users,
      posts,
      tags,
      wikis,
      comments,
      pools,
      topics,
      replies,
      flags,
      tickets,
      follows,
      followServer,
      historyServer,
      histories,
      finishes,
    ]) {
      Disposable.tryDispose(client);
    }
    super.dispose();
  }
}

extension ClientExtension on Client {
  String get host => identity.host;
  bool get hasLogin => identity.username != null;
  String withHost(String path) => identity.withHost(path);
}
