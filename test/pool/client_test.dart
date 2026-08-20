import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/pool/pool.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late PoolClient client;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    dio = MockDio();
    client = PoolClient(dio: dio);
    when(() => dio.options).thenReturn(BaseOptions());
  });

  Map<String, dynamic> poolJson({
    int id = 1,
    String name = 'Test Pool',
    List<int> postIds = const [1, 2, 3],
    int postCount = 3,
    bool active = true,
  }) =>
      {
        'id': id,
        'name': name,
        'created_at': '2024-01-15T00:00:00Z',
        'updated_at': '2024-01-15T00:00:00Z',
        'description': 'A test pool',
        'post_ids': postIds,
        'post_count': postCount,
        'is_active': active,
      };

  group('PoolClient.get', () {
    test('requests /pools/{id}.json and parses response', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/pools/1.json'),
                data: poolJson(),
              ));

      final pool = await client.get(id: 1);

      verify(() => dio.get(
            '/pools/1.json',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      expect(pool.id, 1);
      expect(pool.name, 'Test Pool');
      expect(pool.postIds, [1, 2, 3]);
      expect(pool.postCount, 3);
      expect(pool.active, isTrue);
    });

    test('does not send queryParameters by default', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/pools/1.json'),
                data: poolJson(),
              ));

      await client.get(id: 42);

      final captured = verify(() => dio.get(
            '/pools/42.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      expect(captured.single, isNull);
    });
  });

  group('PoolClient.page', () {
    test('requests /pools.json with page and limit params', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/pools.json'),
                data: [poolJson(), poolJson(id: 2)],
              ));

      final pools = await client.page(page: 1, limit: 20);

      final captured = verify(() => dio.get(
            '/pools.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['page'], 1);
      expect(params['limit'], 20);

      expect(pools.length, 2);
      expect(pools[0].id, 1);
      expect(pools[1].id, 2);
    });

    test('unwraps rails array format', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/pools.json'),
                data: {
                  'pools': [poolJson()],
                },
              ));

      final pools = await client.page();

      expect(pools.length, 1);
      expect(pools[0].id, 1);
    });

    test('handles empty rails object', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/pools.json'),
                data: <String, dynamic>{},
              ));

      final pools = await client.page();

      expect(pools, isEmpty);
    });

    test('passes query params through', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/pools.json'),
                data: [],
              ));

      await client.page(query: {'search[name_matches]': 'test*'});

      final captured = verify(() => dio.get(
            '/pools.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['search[name_matches]'], 'test*');
    });
  });
}
