import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/data/future.dart';

void main() {
  group('StreamFuture.value', () {
    test('completes with the given value', () async {
      final sf = StreamFuture<int>.value(42);
      expect(await sf, 42);
    });

    test('completes with a string value', () async {
      final sf = StreamFuture<String>.value('hello');
      expect(await sf, 'hello');
    });
  });

  group('StreamFuture.from', () {
    test('wraps a Future', () async {
      final sf = StreamFuture<int>.from(Future.value(42));
      expect(await sf, 42);
    });

    test('wraps a plain value', () async {
      final sf = StreamFuture<int>.from(42);
      expect(await sf, 42);
    });

    test('returns the same instance for an existing StreamFuture', () {
      final original = StreamFuture<int>.value(42);
      final result = StreamFuture<int>.from(original);
      expect(identical(result, original), isTrue);
    });

    test('wraps a Future that completes asynchronously', () async {
      final completer = Completer<int>();
      final sf = StreamFuture<int>.from(completer.future);
      completer.complete(99);
      expect(await sf, 99);
    });
  });

  group('StreamFuture.map', () {
    test('maps the result to a different type', () async {
      final sf = StreamFuture<int>.value(42);
      final mapped = sf.map<String>((v) => 'value: $v');
      expect(await mapped, 'value: 42');
    });

    test('maps the result to the same type', () async {
      final sf = StreamFuture<int>.value(21);
      final mapped = sf.map<int>((v) => v * 2);
      expect(await mapped, 42);
    });

    test('can be chained', () async {
      final sf = StreamFuture<int>.value(1);
      final mapped = sf.map<int>((v) => v + 1).map<int>((v) => v * 10);
      expect(await mapped, 20);
    });
  });

  group('StreamFuture as Stream', () {
    test('stream emits values to listeners', () async {
      final controller = StreamController<int>.broadcast();
      final sf = StreamFuture<int>(controller.stream);
      final values = <int>[];
      sf.stream.listen(values.add);
      controller.add(42);
      await controller.close();
      expect(values, [42]);
      expect(await sf, 42);
    });

    test('stream is a broadcast stream', () {
      final sf = StreamFuture<int>.value(42);
      expect(sf.stream.isBroadcast, isTrue);
    });
  });

  group('StreamFutureExtension', () {
    test('stream getter wraps a Stream into StreamFuture', () async {
      final controller = StreamController<int>.broadcast();
      final sf = controller.stream.future;
      controller.add(7);
      await controller.close();
      expect(await sf, 7);
    });
  });

  group('FutureStreamExtension', () {
    test('stream getter converts a Future to StreamFuture', () async {
      final sf = Future<int>.value(42).stream;
      expect(await sf, 42);
    });

    test('streamed getter provides the underlying stream', () async {
      final stream = Future<int>.value(42).streamed;
      expect(stream, isA<Stream<int>>());
    });

    test('map maps the future value', () async {
      final result = Future<int>.value(21).map((v) => v * 2);
      expect(await result, 42);
    });
  });
}
