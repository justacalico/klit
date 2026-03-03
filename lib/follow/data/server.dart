import 'dart:async';

import 'package:drift/drift.dart';
import 'package:klit/follow/follow.dart';
import 'package:klit/identity/identity.dart';
import 'package:klit/pool/pool.dart';
import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/tag/tag.dart';
import 'package:klit/traits/traits.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class FollowServer with Disposable {
  FollowServer({
    required GeneratedDatabase database,
    required this.identity,
    required this.traits,
    required this.postsClient,
    this.poolsClient,
    this.tagsClient,
  }) : repository = FollowRepository(database: database);

  final FollowRepository repository;
  final Identity identity;
  final ValueNotifier<Traits> traits;
  final PostClient postsClient;
  final PoolClient? poolsClient;
  final TagClient? tagsClient;

  final StreamController<FollowSync?> _syncStream =
      BehaviorSubject<FollowSync?>();

  Stream<FollowSync?> get syncStream => _syncStream.stream;

  FollowSync? get currentSync => _currentSync;
  FollowSync? _currentSync;

  Future<void> sync({bool? force}) async {
    if (_currentSync != null) return;
    final sync = FollowSync(
      repository: repository,
      identity: identity,
      traits: traits,
      postsClient: postsClient,
      poolsClient: poolsClient,
      tagsClient: tagsClient,
      force: force,
    );
    _currentSync = sync;
    _syncStream.add(sync);
    await sync.run();
    _currentSync = null;
    _syncStream.add(null);
  }

  Future<void> syncWith({
    required int id,
    List<Post>? posts,
    Pool? pool,
    bool? seen,
  }) =>
      ((repository.update(
        repository.followsTable,
      ))..where((tbl) => tbl.id.equals(id))).write(
        FollowCompanion(
          latest: posts?.isNotEmpty ?? false
              ? Value(posts!.first.id)
              : const Value.absent(),
          thumbnail: posts?.isNotEmpty ?? false
              ? Value(posts!.first.sample)
              : const Value.absent(),
          title: pool?.name != null
              ? Value(tagToName(pool!.name))
              : const Value.absent(),
          unseen: seen ?? true ? const Value(0) : const Value.absent(),
        ),
      );

  @override
  void dispose() {
    super.dispose();
    _currentSync?.cancel();
    _currentSync = null;
    _syncStream.add(_currentSync);
    _syncStream.close();
  }
}
