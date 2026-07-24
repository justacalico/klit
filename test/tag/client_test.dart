import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/tag/tag.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late TagClient client;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    dio = MockDio();
    client = TagClient(dio: dio);
    when(() => dio.options).thenReturn(BaseOptions());
  });

  Map<String, dynamic> tagJson({
    int id = 1,
    String name = 'fox',
    int postCount = 1000,
    int category = 0,
  }) =>
      {
        'id': id,
        'name': name,
        'post_count': postCount,
        'category': category,
      };

  Map<String, dynamic> tagPreviewJson({
    int? id = 1,
    String name = 'fox',
    int? category = 0,
    int? postCount = 1000,
    List<String>? implies = const ['canine'],
    String? alias,
    String? resolved,
  }) =>
      {
        'id': id,
        'name': name,
        'category': category,
        'postCount': postCount,
        'implies': implies,
        'alias': alias,
        'resolved': resolved,
      };

  group('TagClient.page', () {
    test('requests /tags.json with page and limit params', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/tags.json'),
                data: [tagJson(id: 1), tagJson(id: 2, name: 'dog')],
              ));

      final tags = await client.page(page: 1, limit: 50);

      final captured = verify(() => dio.get(
            '/tags.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['page'], 1);
      expect(params['limit'], 50);

      expect(tags.length, 2);
      expect(tags[0].id, 1);
      expect(tags[0].name, 'fox');
      expect(tags[0].count, 1000);
      expect(tags[1].name, 'dog');
    });

    test('unwraps rails array format', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/tags.json'),
                data: {
                  'tags': [tagJson()],
                },
              ));

      final tags = await client.page();

      expect(tags.length, 1);
    });
  });

  group('TagClient.preview', () {
    test('POSTs to /tags/preview.json with tags data', () async {
      when(() => dio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/tags/preview.json'),
                data: [tagPreviewJson()],
              ));

      final previews = await client.preview(tags: 'fox');

      verify(() => dio.post(
            '/tags/preview.json',
            data: {'tags': 'fox'},
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      expect(previews.length, 1);
      expect(previews[0].name, 'fox');
      expect(previews[0].category, 0);
      expect(previews[0].postCount, 1000);
      expect(previews[0].implies, ['canine']);
    });

    test('unwraps rails array format', () async {
      when(() => dio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/tags/preview.json'),
                data: {
                  'tags': [tagPreviewJson(name: 'canine')],
                },
              ));

      final previews = await client.preview(tags: 'canine');

      expect(previews.length, 1);
      expect(previews[0].name, 'canine');
    });
  });

  group('TagClient.autocomplete', () {
    test('returns empty list when search contains colon', () async {
      final tags = await client.autocomplete(search: 'fox:bar');

      expect(tags, isEmpty);
      verifyNever(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ));
    });

    test('returns empty list when search is shorter than 3 chars', () async {
      final tags = await client.autocomplete(search: 'fo');

      expect(tags, isEmpty);
      verifyNever(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ));
    });

    test('requests /tags/autocomplete.json for valid search', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/tags/autocomplete.json'),
                data: [
                  tagJson(id: 1, name: 'fox'),
                  tagJson(id: 2, name: 'foxes'),
                  tagJson(id: 3, name: 'foxy'),
                  tagJson(id: 4, name: 'extra'),
                ],
              ));

      final tags = await client.autocomplete(search: 'fox');

      final captured = verify(() => dio.get(
            '/tags/autocomplete.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['search[name_matches]'], 'fox');

      expect(tags.length, 3);
      expect(tags[0].name, 'fox');
      expect(tags[1].name, 'foxes');
      expect(tags[2].name, 'foxy');
    });

    test('delegates to page when category is specified', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/tags.json'),
                data: [tagJson(id: 1, name: 'fox')],
              ));

      await client.autocomplete(search: 'fox', category: 0, limit: 10);

      final captured = verify(() => dio.get(
            '/tags.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['search[name_matches]'], 'fox*');
      expect(params['search[category]'], '0');
      expect(params['search[order]'], 'count');
      expect(params['limit'], 10);
    });
  });

  group('TagClient.aliases', () {
    test('requests /tag_aliases.json and returns first non-deleted alias',
        () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/tag_aliases.json'),
                data: [
                  {
                    'status': 'active',
                    'consequent_name': 'fox',
                    'antecedent_name': 'vulpine',
                  },
                  {
                    'status': 'deleted',
                    'consequent_name': 'deleted_tag',
                    'antecedent_name': 'old',
                  },
                ],
              ));

      final result = await client.aliases();

      verify(() => dio.get(
            '/tag_aliases.json',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      expect(result, 'fox');
    });

    test('returns null when all aliases are deleted', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/tag_aliases.json'),
                data: [
                  {
                    'status': 'deleted',
                    'consequent_name': 'deleted_tag',
                  },
                ],
              ));

      final result = await client.aliases();

      expect(result, isNull);
    });

    test('returns null when response is empty', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/tag_aliases.json'),
                data: [],
              ));

      final result = await client.aliases();

      expect(result, isNull);
    });
  });
}
