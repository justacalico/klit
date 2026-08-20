import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/comment/comment.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late CommentClient client;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    dio = MockDio();
    client = CommentClient(dio: dio);
    when(() => dio.options).thenReturn(BaseOptions());
  });

  Map<String, dynamic> commentJson({
    int id = 1,
    int postId = 100,
    String body = 'Test comment',
    bool hidden = false,
  }) =>
      {
        'id': id,
        'post_id': postId,
        'body': body,
        'created_at': '2024-01-15T00:00:00Z',
        'updated_at': '2024-01-15T00:00:00Z',
        'creator_id': 200,
        'creator_name': 'testuser',
        'score': 10,
        'warning_type': null,
        'is_hidden': hidden,
      };

  group('CommentClient.get', () {
    test('requests correct URL and parses response', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/comments.json/1.json'),
                data: commentJson(),
              ));

      final comment = await client.get(id: 1);

      verify(() => dio.get(
            '/comments.json/1.json',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      expect(comment.id, 1);
      expect(comment.postId, 100);
      expect(comment.body, 'Test comment');
      expect(comment.creatorName, 'testuser');
      expect(comment.hidden, isFalse);
    });
  });

  group('CommentClient.page', () {
    test('requests /comments.json with page and limit params', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/comments.json'),
                data: [commentJson(), commentJson(id: 2)],
              ));

      final comments = await client.page(page: 2, limit: 50);

      final captured = verify(() => dio.get(
            '/comments.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['page'], 2);
      expect(params['limit'], 50);

      expect(comments.length, 2);
      expect(comments[0].id, 1);
      expect(comments[1].id, 2);
    });

    test('unwraps rails array format', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/comments.json'),
                data: {
                  'comments': [commentJson()],
                },
              ));

      final comments = await client.page();

      expect(comments.length, 1);
      expect(comments[0].id, 1);
    });

    test('handles empty rails object', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/comments.json'),
                data: <String, dynamic>{},
              ));

      final comments = await client.page();

      expect(comments, isEmpty);
    });
  });

  group('CommentClient.byPost', () {
    test('requests comments for a specific post', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/comments.json'),
                data: [commentJson()],
              ));

      final comments = await client.byPost(id: 100);

      final captured = verify(() => dio.get(
            '/comments.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['group_by'], 'comment');
      expect(params['search[post_id]'], '100');
      expect(params['search[order]'], 'id_desc');

      expect(comments.length, 1);
      expect(comments[0].postId, 100);
    });

    test('uses id_asc when ascending is true', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/comments.json'),
                data: [],
              ));

      await client.byPost(id: 100, ascending: true);

      final captured = verify(() => dio.get(
            '/comments.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['search[order]'], 'id_asc');
    });
  });

  group('CommentClient.create', () {
    test('POSTs to /comments.json with body and post_id', () async {
      when(() => dio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/comments.json'),
                data: {},
              ));

      await client.create(postId: 100, content: 'Nice post!');

      verify(() => dio.post(
            '/comments.json',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });

  group('CommentClient.update', () {
    test('PATCHes /comments/{id}.json with body', () async {
      when(() => dio.patch(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/comments/5.json'),
                data: {},
              ));

      await client.update(id: 5, postId: 100, content: 'Edited comment');

      verify(() => dio.patch(
            '/comments/5.json',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });

  group('CommentClient.vote', () {
    test('POSTs to /comments/{id}/votes.json with score', () async {
      when(() => dio.post(
            any(),
            queryParameters: any(named: 'queryParameters'),
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/comments/1/votes.json'),
                data: {},
              ));

      await client.vote(id: 1, upvote: true, replace: false);

      verify(() => dio.post(
            '/comments/1/votes.json',
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
                requestOptions: RequestOptions(path: '/comments/1/votes.json'),
                data: {},
              ));

      await client.vote(id: 1, upvote: false, replace: true);

      verify(() => dio.post(
            '/comments/1/votes.json',
            queryParameters: {'score': -1, 'no_unvote': true},
            data: any(named: 'data'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });
}
