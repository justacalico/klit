import 'package:dio/dio.dart';
import 'package:klit/account/account.dart';
import 'package:klit/app/app.dart';
import 'package:klit/client/client.dart';
import 'package:klit/comment/comment.dart';
import 'package:klit/flag/flag.dart';
import 'package:klit/follow/follow.dart';
import 'package:klit/history/history.dart';
import 'package:klit/identity/identity.dart';
import 'package:klit/pool/pool.dart';
import 'package:klit/post/post.dart';
import 'package:klit/reply/reply.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/tag/tag.dart';
import 'package:klit/ticket/ticket.dart';
import 'package:klit/topic/topic.dart';
import 'package:klit/traits/traits.dart';
import 'package:klit/user/user.dart';
import 'package:klit/wiki/wiki.dart';
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
