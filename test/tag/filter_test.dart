import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';

void main() {
  group('FilterConfigState', () {
    test('holds tags, onChanged, onSubmit, and submitIcon', () {
      void onChanged(QueryMap tags) {}
      void onSubmit(QueryMap tags) {}
      final state = FilterConfigState(
        tags: {},
        onChanged: onChanged,
        onSubmit: onSubmit,
      );
      expect(state.tags, isEmpty);
      expect(state.onChanged, onChanged);
      expect(state.onSubmit, onSubmit);
      expect(state.submitIcon, isNull);
    });
  });

  group('FilterTagState', () {
    test('value reads from the config tags', () {
      const config = FilterConfigState(
        tags: {'existing': 'value'},
        onChanged: _noop,
      );
      final state = config.apply(TextFilterTag(tag: 'existing'));
      expect(state.value, 'value');
    });

    test('value is null for missing tags', () {
      const config = FilterConfigState(
        tags: {'existing': 'value'},
        onChanged: _noop,
      );
      final state = config.apply(TextFilterTag(tag: 'missing'));
      expect(state.value, isNull);
    });

    test('onChanged sets a value and forwards new tags', () {
      QueryMap? captured;
      void onChanged(QueryMap tags) => captured = tags;
      final config = FilterConfigState(
        tags: {'existing': 'value'},
        onChanged: onChanged,
      );
      final state = config.apply(TextFilterTag(tag: 'new'));
      state.onChanged('hello');
      expect(captured, {'existing': 'value', 'new': 'hello'});
    });

    test('onChanged with null removes the tag', () {
      QueryMap? captured;
      void onChanged(QueryMap tags) => captured = tags;
      final config = FilterConfigState(
        tags: {'existing': 'value'},
        onChanged: onChanged,
      );
      final state = config.apply(TextFilterTag(tag: 'existing'));
      state.onChanged(null);
      expect(captured, isEmpty);
    });

    test('onSubmit forwards new tags when submit handler exists', () {
      QueryMap? captured;
      void onSubmit(QueryMap tags) => captured = tags;
      final config = FilterConfigState(
        tags: {'existing': 'value'},
        onChanged: _noop,
        onSubmit: onSubmit,
      );
      final state = config.apply(TextFilterTag(tag: 'new'));
      state.onSubmit?.call('hello');
      expect(captured, {'existing': 'value', 'new': 'hello'});
    });

    test('onSubmit is null when config has no submit handler', () {
      const config = FilterConfigState(tags: {}, onChanged: _noop);
      final state = config.apply(TextFilterTag(tag: 'new'));
      expect(state.onSubmit, isNull);
    });

    test('toString includes tag and value', () {
      const config = FilterConfigState(
        tags: {'existing': 'value'},
        onChanged: _noop,
      );
      final state = config.apply(TextFilterTag(tag: 'existing'));
      expect(state.toString(), contains('existing'));
      expect(state.toString(), contains('value'));
    });

    test('equality compares tag and value', () {
      const config = FilterConfigState(
        tags: {'existing': 'value'},
        onChanged: _noop,
      );
      final state1 = config.apply(TextFilterTag(tag: 'existing'));
      final state2 = config.apply(TextFilterTag(tag: 'existing'));
      expect(state1, state2);
    });

    test('not equal when values differ', () {
      const config1 = FilterConfigState(
        tags: {'existing': 'value'},
        onChanged: _noop,
      );
      const config2 = FilterConfigState(
        tags: {'existing': 'different'},
        onChanged: _noop,
      );
      final state1 = config1.apply(TextFilterTag(tag: 'existing'));
      final state2 = config2.apply(TextFilterTag(tag: 'existing'));
      expect(state1 == state2, isFalse);
    });

    test('hashCode matches for equal states', () {
      const config = FilterConfigState(
        tags: {'existing': 'value'},
        onChanged: _noop,
      );
      final filter = TextFilterTag(tag: 'existing');
      final state1 = config.apply(filter);
      final state2 = config.apply(filter);
      expect(state1.hashCode, state2.hashCode);
    });
  });

  group('ChoiceFilterTagValue', () {
    test('title falls back to value when name is null', () {
      const value = ChoiceFilterTagValue(value: 'opt1', name: null);
      expect(value.title, 'opt1');
    });

    test('title uses name when provided', () {
      const value = ChoiceFilterTagValue(value: 'opt1', name: 'Option 1');
      expect(value.title, 'Option 1');
    });
  });

  group('FilterTagThemeData', () {
    test('copyWith preserves unchanged fields', () {
      const theme = FilterTagThemeData();
      final copied = theme.copyWith(primary: true);
      expect(copied.primary, isTrue);
      expect(copied.decoration, theme.decoration);
    });

    test('copyWith applies new values', () {
      const theme = FilterTagThemeData(primary: false);
      final copied = theme.copyWith(primary: true);
      expect(copied.primary, isTrue);
    });
  });
}

void _noop(QueryMap tags) {}
