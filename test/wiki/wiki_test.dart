import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/wiki/data/wiki.dart';

void main() {
  final createdAt = DateTime.parse('2024-01-15T10:30:00.000Z');
  final updatedAt = DateTime.parse('2024-02-20T14:00:00.000Z');

  final wiki = Wiki(
    id: 1,
    title: 'test wiki',
    body: 'wiki body content',
    createdAt: createdAt,
    updatedAt: updatedAt,
    otherNames: const ['alias1', 'alias2'],
    isLocked: true,
  );

  group('Wiki JSON', () {
    test('toJson serializes all fields', () {
      final json = wiki.toJson();
      expect(json['id'], 1);
      expect(json['title'], 'test wiki');
      expect(json['body'], 'wiki body content');
      expect(json['createdAt'], createdAt.toIso8601String());
      expect(json['updatedAt'], updatedAt.toIso8601String());
      expect(json['otherNames'], ['alias1', 'alias2']);
      expect(json['isLocked'], true);
    });

    test('fromJson parses all fields', () {
      final parsed = Wiki.fromJson(wiki.toJson());
      expect(parsed.id, 1);
      expect(parsed.title, 'test wiki');
      expect(parsed.body, 'wiki body content');
      expect(parsed.createdAt, createdAt);
      expect(parsed.updatedAt, updatedAt);
      expect(parsed.otherNames, ['alias1', 'alias2']);
      expect(parsed.isLocked, isTrue);
    });

    test('roundtrip preserves data', () {
      final restored = Wiki.fromJson(wiki.toJson());
      expect(restored.id, wiki.id);
      expect(restored.title, wiki.title);
      expect(restored.body, wiki.body);
      expect(restored.createdAt, wiki.createdAt);
      expect(restored.updatedAt, wiki.updatedAt);
      expect(restored.otherNames, wiki.otherNames);
      expect(restored.isLocked, wiki.isLocked);
    });

    test('handles nullable fields as null', () {
      final wikiNull = Wiki(
        id: 2,
        title: 'minimal',
        body: 'body',
        createdAt: createdAt,
        updatedAt: null,
        otherNames: null,
        isLocked: null,
      );
      final restored = Wiki.fromJson(wikiNull.toJson());
      expect(restored.updatedAt, isNull);
      expect(restored.otherNames, isNull);
      expect(restored.isLocked, isNull);
    });
  });

  group('Wiki.copyWith', () {
    test('changes title and body', () {
      final copied = wiki.copyWith(title: 'new title', body: 'new body');
      expect(copied.title, 'new title');
      expect(copied.body, 'new body');
      expect(copied.id, wiki.id);
      expect(copied.createdAt, wiki.createdAt);
    });

    test('changes otherNames and isLocked', () {
      final copied = wiki.copyWith(
        otherNames: const ['newalias'],
        isLocked: false,
      );
      expect(copied.otherNames, ['newalias']);
      expect(copied.isLocked, isFalse);
    });
  });
}
