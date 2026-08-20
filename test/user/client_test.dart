import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/user/user.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late UserClient client;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    dio = MockDio();
    client = UserClient(dio: dio);
    when(() => dio.options).thenReturn(BaseOptions());
  });

  Map<String, dynamic> userJson({
    int id = 1,
    String name = 'testuser',
    int? avatarId = 123,
  }) =>
      {
        'id': id,
        'name': name,
        'avatar_id': avatarId,
        'profile_about': 'About me',
        'profile_artinfo': 'Art info',
        'created_at': '2024-01-15T00:00:00Z',
        'level_string': 'Member',
        'favorite_count': 100,
        'post_update_count': 50,
        'post_upload_count': 25,
        'forum_post_count': 10,
        'comment_count': 200,
      };

  group('UserClient.get', () {
    test('requests /users/{id}.json and parses response', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/users/testuser.json'),
                data: userJson(),
              ));

      final user = await client.get(id: 'testuser');

      verify(() => dio.get(
            '/users/testuser.json',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      expect(user.id, 1);
      expect(user.name, 'testuser');
      expect(user.avatarId, 123);
    });

    test('parses about section', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/users/1.json'),
                data: userJson(),
              ));

      final user = await client.get(id: '1');

      expect(user.about, isNotNull);
      expect(user.about!.bio, 'About me');
      expect(user.about!.comission, 'Art info');
    });

    test('parses stats section', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/users/1.json'),
                data: userJson(),
              ));

      final user = await client.get(id: '1');

      expect(user.stats, isNotNull);
      expect(user.stats!.levelString, 'Member');
      expect(user.stats!.favoriteCount, 100);
      expect(user.stats!.postUpdateCount, 50);
      expect(user.stats!.postUploadCount, 25);
      expect(user.stats!.forumPostCount, 10);
      expect(user.stats!.commentCount, 200);
      expect(user.stats!.createdAt, DateTime.parse('2024-01-15T00:00:00Z'));
    });

    test('handles null avatar_id', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/users/1.json'),
                data: userJson(avatarId: null),
              ));

      final user = await client.get(id: '1');

      expect(user.avatarId, isNull);
    });
  });
}
