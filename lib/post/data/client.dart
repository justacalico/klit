// SPDX-License-Identifier: AGPL-3.0

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/pool/pool.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';

class PostClient {
  PostClient({
    required this.dio,
    required this.identity,
    required this.poolsService,
  });

  final Dio dio;
  final Identity identity;
  final PoolClient poolsService;

  Map<String, dynamic> _withV2(Map<String, dynamic>? params) {
    return {'v2': true, 'mode': 'extended', ...?params};
  }

  Future<Post> get({required int id, bool? force, CancelToken? cancelToken}) =>
      dio
          .get(
            '/posts/$id.json',
            queryParameters: _withV2(null),
            options: forceOptions(force),
            cancelToken: cancelToken,
          )
          .then((response) => E621Post.fromJson(response.data));

  Future<List<Post>> page({
    int? page,
    int? limit,
    QueryMap? query,
    // This needs to be rearchitected.
    // - maybe extra function, e.g. pageOrdered?
    // - maybe extra PostPageOrder class?
    // - maybe special query parameters?
    bool? ordered,
    bool? orderPoolsByOldest,
    bool? orderFavoritesByAdded,
    bool? force,
    CancelToken? cancelToken,
  }) async {
    ordered ??= true;
    final tags = query?['tags'];
    if (ordered && tags != null) {
      final redirects = <RegExp, Future<List<Post>> Function(RegExpMatch match)>{
        poolRegex(): (match) => byPool(
          id: int.parse(match.namedGroup('id')!),
          page: page,
          orderByOldest: orderPoolsByOldest ?? true,
          force: force,
          cancelToken: cancelToken,
        ),
        if ((orderFavoritesByAdded ?? false) && identity.username != null)
          favRegex(identity.username!): (match) =>
              favorites(page: page, limit: limit, force: force),
      };

      for (final entry in redirects.entries) {
        final match = entry.key.firstMatch(tags);
        if (match != null) {
          return entry.value(match);
        }
      }
    }

    return dio
        .get(
          '/posts.json',
          queryParameters: _withV2({'page': page, 'limit': limit, ...?query}),
          options: forceOptions(force),
          cancelToken: cancelToken,
        )
        .then(
          (response) => (response.data as List<dynamic>)
              .map<Post>(E621Post.fromJson)
              .whereNot(
                (e) => (e.file == null && !e.isDeleted) || e.ext == 'swf',
              )
              .toList(),
        );
  }

  Future<List<Post>> byHot({
    int? page,
    int? limit,
    QueryMap? query,
    bool? force,
    CancelToken? cancelToken,
  }) {
    return this.page(
      page: page,
      query: {
        ...?query,
        'tags': (TagMap(query?['tags'])..['order'] = 'rank').toString(),
      },
      limit: limit,
      force: force,
      cancelToken: cancelToken,
    );
  }

  Future<List<Post>> byPopular({
    required String scale,
    String? date,
    bool? force,
    CancelToken? cancelToken,
  }) {
    return dio
        .get(
          '/popular.json',
          queryParameters: _withV2({
            'scale': scale,
            'date': ?date,
          }),
          options: forceOptions(force),
          cancelToken: cancelToken,
        )
        .then(
          (response) => (response.data as List<dynamic>)
              .map<Post>(E621Post.fromJson)
              .whereNot(
                (e) => (e.file == null && !e.isDeleted) || e.ext == 'swf',
              )
              .toList(),
        );
  }

  Future<List<Post>> byIds({
    required List<int> ids,
    int? limit,
    bool? force,
    CancelToken? cancelToken,
  }) async {
    limit = max(0, min(limit ?? 75, 100));

    final chunks = <List<int>>[];
    for (var i = 0; i < ids.length; i += limit) {
      chunks.add(ids.sublist(i, min(i + limit, ids.length)));
    }

    final result = <Post>[];
    for (final chunk in chunks) {
      if (chunk.isEmpty) continue;
      final filter = 'id:${chunk.join(',')}';
      var part = await page(
        query: {'tags': filter},
        limit: limit,
        ordered: false,
        force: force,
        cancelToken: cancelToken,
      );
      final table = <int, Post>{for (final Post e in part) e.id: e};
      part =
          (chunk.map((e) => table[e]).toList()..removeWhere((e) => e == null))
              .cast<Post>();
      result.addAll(part);
    }
    return result;
  }

  Future<List<Post>> byTags({
    required List<String> tags,
    int? page,
    int? limit,
    bool? force,
    CancelToken? cancelToken,
  }) async {
    page ??= 1;
    tags.removeWhere((e) => e.contains(' ') || e.contains(':'));
    if (tags.isEmpty) return [];
    const max = 40;
    final pages = (tags.length / max).ceil();
    final chunkSize = (tags.length / pages).ceil();

    final tagPage = page % pages != 0 ? page % pages : pages;
    final sitePage = (page / pages).ceil();

    final chunk = tags
        .sublist((tagPage - 1) * chunkSize)
        .take(chunkSize)
        .toList();
    final filter = chunk.map((e) => '~$e').join(' ');
    return this.page(
      page: sitePage,
      query: {'tags': filter},
      limit: limit,
      ordered: false,
      force: force,
      cancelToken: cancelToken,
    );
  }

  Future<List<Post>> byFavoriter({
    required String username,
    int? page,
    int? limit,
    bool? force,
    CancelToken? cancelToken,
  }) => this.page(
    page: page,
    query: {'tags': 'fav:$username'},
    limit: limit,
    ordered: false,
    force: force,
    cancelToken: cancelToken,
  );

  Future<List<Post>> byUploader({
    required String username,
    int? page,
    int? limit,
    bool? force,
    CancelToken? cancelToken,
  }) => this.page(
    page: page,
    query: {'tags': 'user:$username'},
    limit: limit,
    ordered: false,
    force: force,
    cancelToken: cancelToken,
  );

  Future<List<Post>> byPool({
    required int id,
    int? page,
    int? limit,
    bool orderByOldest = true,
    bool? force,
    CancelToken? cancelToken,
  }) async {
    page ??= 1;
    const limit = 75;
    final pool = await poolsService.get(
      id: id,
      force: force,
      cancelToken: cancelToken,
    );
    var ids = pool.postIds;
    if (!orderByOldest) ids = ids.reversed.toList();
    final lower = (page - 1) * limit;
    if (lower > ids.length) return [];
    ids = ids.sublist(lower).take(limit).toList();
    return byIds(
      ids: ids,
      limit: limit,
      force: force,
      cancelToken: cancelToken,
    );
  }

  Future<void> update(int postId, Map<String, String?> body) async {
    await dio.cache?.deleteFromPath(
      RegExp(RegExp.escape('/posts/$postId.json')),
    );
    await dio.put('/posts/$postId.json', data: FormData.fromMap(body));
  }

  Future<void> vote(int postId, bool upvote, bool replace) async {
    await dio.cache?.deleteFromPath(
      RegExp(RegExp.escape('/posts/$postId.json')),
    );
    await dio.post(
      '/posts/$postId/votes.json',
      queryParameters: {'score': upvote ? 1 : -1, 'no_unvote': replace},
    );
  }

  Future<List<Post>> favorites({
    int? page,
    int? limit,
    QueryMap? query,
    bool? orderByAdded,
    bool? force,
    CancelToken? cancelToken,
  }) async {
    if (identity.username == null) {
      throw NoUserLoginException();
    }
    orderByAdded ??= true;
    final tags = query?['tags'] ?? '';
    if (tags.isEmpty && orderByAdded) {
      final body = await dio
          .get(
            '/favorites.json',
            queryParameters: _withV2({'page': page, 'limit': limit, ...?query}),
            options: forceOptions(force),
            cancelToken: cancelToken,
          )
          .then((response) => response.data);
      final result = List<Post>.from(body.map(E621Post.fromJson));
      result.removeWhere((e) => e.isDeleted || e.file == null);
      return result;
    } else {
      return this.page(
        page: page,
        query: {
          ...?query,
          'tags': (TagMap(tags)..['fav'] = identity.username).toString(),
        },
        ordered: false,
        force: force,
        cancelToken: cancelToken,
      );
    }
  }

  Future<void> addFavorite(int postId) async {
    await dio.cache?.deleteFromPath(
      RegExp(RegExp.escape('/posts/$postId.json')),
    );
    await dio.post('/favorites.json', queryParameters: {'post_id': postId});
  }

  Future<void> removeFavorite(int postId) async {
    await dio.cache?.deleteFromPath(
      RegExp(RegExp.escape('/posts/$postId.json')),
    );
    await dio.delete('/favorites/$postId.json');
  }
}
