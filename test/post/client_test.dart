import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/pool/pool.dart';
import 'package:kilt/post/post.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockPoolClient extends Mock implements PoolClient {}

void main() {
  late MockDio dio;
  late MockPoolClient poolsService;
  late Identity identity;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    dio = MockDio();
    poolsService = MockPoolClient();
    identity = const Identity(
      id: 1,
      host: 'e621.net',
      username: 'testuser',
      headers: {},
    );
    when(() => dio.options).thenReturn(BaseOptions());
  });

  PostClient createClient() => PostClient(
        dio: dio,
        identity: identity,
        poolsService: poolsService,
      );

  Map<String, dynamic> postJson({
    int id = 1,
    String? fileUrl = 'https://example.com/image.jpg',
    String ext = 'jpg',
    bool deleted = false,
  }) =>
      {
        'id': id,
        'files': {
          'original': {
            'url': fileUrl,
            'width': 1000,
            'height': 800,
          },
          'sample': {'webp': 'https://example.com/sample.webp'},
          'preview': {'jpg': 'https://example.com/preview.jpg'},
          'meta': {'ext': ext, 'size': 500000},
        },
        'tags': {
          'general': ['fox', 'canine'],
          'species': ['dog'],
        },
        'uploader_id': 100,
        'uploader_name': 'uploader',
        'approver_id': null,
        'created_at': '2024-01-15T00:00:00Z',
        'updated_at': null,
        'change_seq': 12345,
        'stats': {
          'score': {'total': 50},
          'vote': null,
          'fav_count': 10,
          'is_favorited': false,
          'comment_count': 5,
        },
        'flags': {'deleted': deleted},
        'rating': 's',
        'description': 'A test post',
        'sources': ['https://example.com/source'],
        'locked_tags': null,
        'pools': [],
        'relationships': {'parent_id': null, 'children': []},
        'has': {'children': false, 'active_children': null},
      };

  group('PostClient.get', () {
    test('requests correct URL and parses response', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts/1.json'),
                data: postJson(id: 1),
              ));

      final client = createClient();
      final post = await client.get(id: 1);

      verify(() => dio.get(
            '/posts/1.json',
            queryParameters: {'v2': true, 'mode': 'extended'},
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      expect(post.id, 1);
      expect(post.file, 'https://example.com/image.jpg');
      expect(post.ext, 'jpg');
      expect(post.tags['general'], ['fox', 'canine']);
    });

    test('passes force option through', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts/1.json'),
                data: postJson(),
              ));

      final client = createClient();
      await client.get(id: 1, force: true);

      verify(() => dio.get(
            '/posts/1.json',
            queryParameters: {'v2': true, 'mode': 'extended'},
            options: any(named: 'options', that: isNotNull),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });

  group('PostClient.page', () {
    test('requests /posts.json with page, tags, v2 and mode params', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts.json'),
                data: [postJson(id: 1), postJson(id: 2)],
              ));

      final client = createClient();
      final posts = await client.page(page: 1, query: {'tags': 'fox'});

      final captured = verify(() => dio.get(
            '/posts.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['v2'], true);
      expect(params['mode'], 'extended');
      expect(params['page'], 1);
      expect(params['tags'], 'fox');

      expect(posts.length, 2);
      expect(posts[0].id, 1);
      expect(posts[1].id, 2);
    });

    test('filters out posts with null file and not deleted', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts.json'),
                data: [
                  postJson(id: 1),
                  postJson(id: 2, fileUrl: null, deleted: false),
                  postJson(id: 3, fileUrl: null, deleted: true),
                ],
              ));

      final client = createClient();
      final posts = await client.page(query: {'tags': 'fox'});

      expect(posts.length, 2);
      expect(posts.map((e) => e.id).toList(), [1, 3]);
    });

    test('filters out swf posts', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts.json'),
                data: [
                  postJson(id: 1, ext: 'jpg'),
                  postJson(id: 2, ext: 'swf'),
                ],
              ));

      final client = createClient();
      final posts = await client.page(query: {'tags': 'fox'});

      expect(posts.length, 1);
      expect(posts[0].id, 1);
    });

    test('redirects to byPool when tags contain pool:id', () async {
      final pool = Pool(
        id: 123,
        name: 'Test Pool',
        createdAt: DateTime.parse('2024-01-15T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-15T00:00:00Z'),
        description: 'A test pool',
        postIds: [1, 2],
        postCount: 2,
        active: true,
      );

      when(() => poolsService.get(
            id: any(named: 'id'),
            force: any(named: 'force'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => pool);

      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts.json'),
                data: [postJson(id: 1), postJson(id: 2)],
              ));

      final client = createClient();
      final posts = await client.page(query: {'tags': 'pool:123'});

      verify(() => poolsService.get(
            id: 123,
            force: any(named: 'force'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      expect(posts.length, 2);
      expect(posts[0].id, 1);
      expect(posts[1].id, 2);
    });
  });

  group('PostClient.byPopular', () {
    test('requests /popular.json with scale and date params', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/popular.json'),
                data: [postJson(id: 1)],
              ));

      final client = createClient();
      final posts = await client.byPopular(scale: 'day', date: '2024-01-15');

      final captured = verify(() => dio.get(
            '/popular.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['v2'], true);
      expect(params['mode'], 'extended');
      expect(params['scale'], 'day');
      expect(params['date'], '2024-01-15');

      expect(posts.length, 1);
      expect(posts[0].id, 1);
    });

    test('works without date', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/popular.json'),
                data: [postJson(id: 1)],
              ));

      final client = createClient();
      await client.byPopular(scale: 'week');

      final captured = verify(() => dio.get(
            '/popular.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params.containsKey('date'), isFalse);
      expect(params['scale'], 'week');
    });
  });

  group('PostClient.byHot', () {
    test('adds order:rank to tags and delegates to page', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts.json'),
                data: [postJson(id: 1)],
              ));

      final client = createClient();
      await client.byHot(page: 1, query: {'tags': 'fox'});

      final captured = verify(() => dio.get(
            '/posts.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['tags'], 'fox order:rank');
      expect(params['page'], 1);
    });
  });

  group('PostClient.vote', () {
    test('POSTs to /posts/{id}/votes.json with score', () async {
      when(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts/1/votes.json'),
                data: {},
              ));

      final client = createClient();
      await client.vote(1, true, false);

      verify(() => dio.post(
            '/posts/1/votes.json',
            queryParameters: {'score': 1, 'no_unvote': false},
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('sends score -1 for downvote', () async {
      when(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts/1/votes.json'),
                data: {},
              ));

      final client = createClient();
      await client.vote(1, false, true);

      verify(() => dio.post(
            '/posts/1/votes.json',
            queryParameters: {'score': -1, 'no_unvote': true},
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });

  group('PostClient.addFavorite', () {
    test('POSTs to /favorites.json with post_id', () async {
      when(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/favorites.json'),
                data: {},
              ));

      final client = createClient();
      await client.addFavorite(1);

      verify(() => dio.post(
            '/favorites.json',
            queryParameters: {'post_id': 1},
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });

  group('PostClient.removeFavorite', () {
    test('DELETEs /favorites/{id}.json', () async {
      when(() => dio.delete(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/favorites/1.json'),
                data: {},
              ));

      final client = createClient();
      await client.removeFavorite(1);

      verify(() => dio.delete(
            '/favorites/1.json',
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });

  group('PostClient.favorites', () {
    test('throws NoUserLoginException when identity has no username',
        () async {
      final noUserIdentity = const Identity(
        id: 1,
        host: 'e621.net',
        username: null,
        headers: {},
      );

      final client = PostClient(
        dio: dio,
        identity: noUserIdentity,
        poolsService: poolsService,
      );

      await expectLater(
        client.favorites(),
        throwsA(isA<NoUserLoginException>()),
      );
    });

    test('requests /favorites.json when orderByAdded and empty tags', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/favorites.json'),
                data: [postJson(id: 1), postJson(id: 2)],
              ));

      final client = createClient();
      final posts = await client.favorites(page: 1);

      verify(() => dio.get(
            '/favorites.json',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      expect(posts.length, 2);
    });
  });

  group('PostClient.byIds', () {
    test('chunks ids and uses id: filter', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts.json'),
                data: [postJson(id: 3), postJson(id: 1), postJson(id: 2)],
              ));

      final client = createClient();
      final posts = await client.byIds(ids: [1, 2, 3]);

      final captured = verify(() => dio.get(
            '/posts.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['tags'], 'id:1,2,3');

      expect(posts.length, 3);
      expect(posts[0].id, 1);
      expect(posts[1].id, 2);
      expect(posts[2].id, 3);
    });

    test('returns empty list for empty ids', () async {
      final client = createClient();
      final posts = await client.byIds(ids: []);

      expect(posts, isEmpty);
      verifyNever(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ));
    });

    test('preserves order of requested ids', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/posts.json'),
                data: [postJson(id: 2), postJson(id: 1), postJson(id: 3)],
              ));

      final client = createClient();
      final posts = await client.byIds(ids: [1, 2, 3]);

      expect(posts.map((e) => e.id).toList(), [1, 2, 3]);
    });
  });
}
