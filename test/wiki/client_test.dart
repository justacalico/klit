import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/wiki/wiki.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late WikiClient client;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    dio = MockDio();
    client = WikiClient(dio: dio);
    when(() => dio.options).thenReturn(BaseOptions());
  });

  Map<String, dynamic> wikiJson({
    int id = 1,
    String title = 'fox',
    String body = 'A wiki page about foxes',
    bool? isLocked = false,
    List<String>? otherNames = const ['vulpes'],
  }) =>
      {
        'id': id,
        'title': title,
        'body': body,
        'created_at': '2024-01-15T00:00:00Z',
        'updated_at': null,
        'other_names': otherNames,
        'is_locked': isLocked,
      };

  group('WikiClient.get', () {
    test('requests /wiki_pages/{id}.json and parses response', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/wiki_pages/fox.json'),
                data: wikiJson(id: 1, title: 'fox'),
              ));

      final wiki = await client.get(id: 'fox');

      verify(() => dio.get(
            '/wiki_pages/fox.json',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      expect(wiki.id, 1);
      expect(wiki.title, 'fox');
      expect(wiki.body, 'A wiki page about foxes');
      expect(wiki.otherNames, ['vulpes']);
      expect(wiki.isLocked, isFalse);
    });

    test('accepts numeric id as string', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/wiki_pages/42.json'),
                data: wikiJson(id: 42),
              ));

      final wiki = await client.get(id: '42');

      verify(() => dio.get(
            '/wiki_pages/42.json',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);

      expect(wiki.id, 42);
    });
  });

  group('WikiClient.page', () {
    test('requests /wiki_pages.json with page and limit params', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/wiki_pages.json'),
                data: [wikiJson(id: 1), wikiJson(id: 2, title: 'dog')],
              ));

      final wikis = await client.page(page: 1, limit: 20);

      final captured = verify(() => dio.get(
            '/wiki_pages.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['page'], 1);
      expect(params['limit'], 20);

      expect(wikis.length, 2);
      expect(wikis[0].title, 'fox');
      expect(wikis[1].title, 'dog');
    });

    test('unwraps rails array format', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/wiki_pages.json'),
                data: {
                  'wiki_pages': [wikiJson()],
                },
              ));

      final wikis = await client.page();

      expect(wikis.length, 1);
      expect(wikis[0].title, 'fox');
    });

    test('handles empty rails object', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/wiki_pages.json'),
                data: <String, dynamic>{},
              ));

      final wikis = await client.page();

      expect(wikis, isEmpty);
    });

    test('passes query params through', () async {
      when(() => dio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/wiki_pages.json'),
                data: [],
              ));

      await client.page(query: {'search[title]': 'fox*'});

      final captured = verify(() => dio.get(
            '/wiki_pages.json',
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;

      final params = captured.single as Map<String, dynamic>;
      expect(params['search[title]'], 'fox*');
    });
  });
}
