import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/post/post.dart';

import '../helpers/test_posts.dart';

void main() {
  group('PostEdit.fromPost', () {
    test('copies all fields from the post', () {
      final post = makePost(
        id: 7,
        rating: Rating.q,
        description: 'hello world',
        sources: ['https://example.com/a', 'https://example.com/b'],
        tags: const {
          'general': ['fox', 'canine'],
          'species': ['dog'],
        },
        relationships: const Relationships(
          parentId: 3,
          hasChildren: true,
          hasActiveChildren: true,
          children: [10, 20],
        ),
      );

      final edit = PostEdit.fromPost(post);

      expect(edit.post, same(post));
      expect(edit.rating, Rating.q);
      expect(edit.description, 'hello world');
      expect(edit.parentId, 3);
      expect(edit.sources, ['https://example.com/a', 'https://example.com/b']);
      expect(edit.tags, containsAll(['fox', 'canine', 'dog']));
      expect(edit.tags.length, 3);
      expect(edit.editReason, isNull);
    });
  });

  group('PostEdit.toForm', () {
    test('returns null when nothing changed', () {
      final post = makePost();
      final edit = PostEdit.fromPost(post);
      expect(edit.toForm(), isNull);
    });

    test('includes tag_string_diff when tags are added', () {
      final post = makePost();
      final edit = PostEdit.fromPost(post).copyWith(
        tags: [...PostEdit.fromPost(post).tags, 'cat'],
      );

      final form = edit.toForm()!;
      expect(form['post[tag_string_diff]'], 'cat');
    });

    test('includes tag_string_diff when tags are removed', () {
      final post = makePost();
      final originalTags = PostEdit.fromPost(post).tags;
      final edit = PostEdit.fromPost(post).copyWith(
        tags: originalTags.where((t) => t != 'fox').toList(),
      );

      final form = edit.toForm()!;
      expect(form['post[tag_string_diff]'], '-fox');
    });

    test('includes source_diff when sources are added', () {
      final post = makePost();
      final edit = PostEdit.fromPost(post).copyWith(
        sources: [...post.sources, 'https://example.com/new'],
      );

      final form = edit.toForm()!;
      expect(form['post[source_diff]'], 'https://example.com/new');
    });

    test('includes source_diff when sources are removed', () {
      final post = makePost(sources: ['https://a.com', 'https://b.com']);
      final edit = PostEdit.fromPost(post).copyWith(
        sources: ['https://a.com'],
      );

      final form = edit.toForm()!;
      expect(form['post[source_diff]'], '-https://b.com');
    });

    test('includes rating when the rating changes', () {
      final post = makePost(rating: Rating.s);
      final edit = PostEdit.fromPost(post).copyWith(rating: Rating.e);

      final form = edit.toForm()!;
      expect(form['post[rating]'], 'e');
    });

    test('includes description when the description changes', () {
      final post = makePost(description: 'old');
      final edit = PostEdit.fromPost(post).copyWith(description: 'new');

      final form = edit.toForm()!;
      expect(form['post[description]'], 'new');
    });

    test('includes parent_id when the parent changes', () {
      final post = makePost(
        relationships: const Relationships(
          parentId: null,
          hasChildren: false,
          hasActiveChildren: false,
          children: [],
        ),
      );
      final edit = PostEdit.fromPost(post).copyWith(parentId: 5);

      final form = edit.toForm()!;
      expect(form['post[parent_id]'], '5');
    });

    test('includes parent_id as null when clearing the parent', () {
      final post = makePost(
        relationships: const Relationships(
          parentId: 5,
          hasChildren: false,
          hasActiveChildren: false,
          children: [],
        ),
      );
      final edit = PostEdit.fromPost(post).copyWith(parentId: null);

      final form = edit.toForm()!;
      expect(form['post[parent_id]'], isNull);
    });

    test('includes edit_reason when there are other changes', () {
      final post = makePost(rating: Rating.s);
      final edit = PostEdit.fromPost(post).copyWith(
        rating: Rating.q,
        editReason: 'fixing rating',
      );

      final form = edit.toForm()!;
      expect(form['post[edit_reason]'], 'fixing rating');
      expect(form['post[rating]'], 'q');
    });

    test('trims the edit reason', () {
      final post = makePost(rating: Rating.s);
      final edit = PostEdit.fromPost(post).copyWith(
        rating: Rating.q,
        editReason: '  fixing rating  ',
      );

      final form = edit.toForm()!;
      expect(form['post[edit_reason]'], 'fixing rating');
    });

    test('does not include edit_reason when it is blank', () {
      final post = makePost(rating: Rating.s);
      final edit = PostEdit.fromPost(post).copyWith(
        rating: Rating.q,
        editReason: '   ',
      );

      final form = edit.toForm()!;
      expect(form.containsKey('post[edit_reason]'), isFalse);
    });

    test('returns null when only edit_reason is set with no other changes', () {
      final post = makePost();
      final edit = PostEdit.fromPost(post).copyWith(editReason: 'reason');

      expect(edit.toForm(), isNull);
    });

    test('includes all changed fields for multiple changes', () {
      final post = makePost(
        rating: Rating.s,
        description: 'old desc',
        sources: ['https://old.com'],
      );
      final edit = PostEdit.fromPost(post).copyWith(
        rating: Rating.e,
        description: 'new desc',
        sources: ['https://old.com', 'https://new.com'],
        tags: [...PostEdit.fromPost(post).tags, 'wolf'],
        parentId: 10,
        editReason: 'bulk update',
      );

      final form = edit.toForm()!;
      expect(form['post[tag_string_diff]'], 'wolf');
      expect(form['post[source_diff]'], 'https://new.com');
      expect(form['post[rating]'], 'e');
      expect(form['post[description]'], 'new desc');
      expect(form['post[parent_id]'], '10');
      expect(form['post[edit_reason]'], 'bulk update');
    });
  });
}
