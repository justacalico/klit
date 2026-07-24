import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/data/action.dart';

class _TestActionController extends ActionController {
  int onSuccessCalls = 0;
  int onForgiveCalls = 0;

  Future<void> testExecute(ActionControllerCallback submit) => execute(submit);
  void testReset() => reset();

  @override
  void onSuccess() => onSuccessCalls++;

  @override
  void onForgive() => onForgiveCalls++;
}

void main() {
  group('ActionController.execute', () {
    test('sets isLoading during execution', () async {
      final controller = _TestActionController();
      addTearDown(controller.dispose);

      final completer = Completer<void>();
      final future = controller.testExecute(() => completer.future);
      expect(controller.isLoading, isTrue);
      expect(controller.isError, isFalse);

      completer.complete();
      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.isError, isFalse);
    });

    test('calls onSuccess on successful execution', () async {
      final controller = _TestActionController();
      addTearDown(controller.dispose);

      await controller.testExecute(() async {});

      expect(controller.onSuccessCalls, 1);
      expect(controller.isError, isFalse);
    });

    test('sets error on ActionControllerException', () async {
      final controller = _TestActionController();
      controller.errorTimeout = const Duration(seconds: 30);
      addTearDown(controller.dispose);

      await controller.testExecute(() async {
        throw const ActionControllerException(message: 'something went wrong');
      });

      expect(controller.isError, isTrue);
      expect(controller.error, isNotNull);
      expect(controller.error?.message, 'something went wrong');
      expect(controller.isLoading, isFalse);
      expect(controller.onSuccessCalls, 0);
    });

    test('does not catch non-ActionController exceptions', () async {
      final controller = _TestActionController();
      addTearDown(controller.dispose);

      await expectLater(
        controller.testExecute(() async {
          throw StateError('unexpected');
        }),
        throwsStateError,
      );

      // isLoading stays true because the exception propagates
      // before the isLoading = false line is reached
      expect(controller.isLoading, isTrue);
      expect(controller.isError, isFalse);
    });

    test('clears previous error on new execution', () async {
      final controller = _TestActionController();
      controller.errorTimeout = const Duration(seconds: 30);
      addTearDown(controller.dispose);

      await controller.testExecute(() async {
        throw const ActionControllerException(message: 'fail');
      });
      expect(controller.isError, isTrue);

      await controller.testExecute(() async {});
      expect(controller.isError, isFalse);
      expect(controller.error, isNull);
    });
  });

  group('ActionController forgive', () {
    test('isForgiven is false immediately after error', () async {
      final controller = _TestActionController();
      controller.errorTimeout = const Duration(seconds: 30);
      addTearDown(controller.dispose);

      await controller.testExecute(() async {
        throw const ActionControllerException(message: 'fail');
      });

      expect(controller.isForgiven, isFalse);
    });

    test('isForgiven becomes true after error timeout', () async {
      final controller = _TestActionController();
      controller.errorTimeout = const Duration(milliseconds: 10);
      addTearDown(controller.dispose);

      await controller.testExecute(() async {
        throw const ActionControllerException(message: 'fail');
      });
      expect(controller.isForgiven, isFalse);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.isForgiven, isTrue);
    });
  });

  group('ActionController.reset', () {
    test('clears all state', () async {
      final controller = _TestActionController();
      controller.errorTimeout = const Duration(seconds: 30);
      addTearDown(controller.dispose);

      await controller.testExecute(() async {
        throw const ActionControllerException(message: 'fail');
      });
      expect(controller.isError, isTrue);

      controller.testReset();

      expect(controller.isError, isFalse);
      expect(controller.error, isNull);
      expect(controller.isLoading, isFalse);
      expect(controller.isForgiven, isFalse);
      expect(controller.action, isNull);
    });

    test('does not cancel forgive timer (only dispose does)', () async {
      final controller = _TestActionController();
      controller.errorTimeout = const Duration(milliseconds: 10);
      addTearDown(controller.dispose);

      await controller.testExecute(() async {
        throw const ActionControllerException(message: 'fail');
      });

      controller.testReset();
      expect(controller.isForgiven, isFalse);

      // reset does not cancel the error timer, so isForgiven
      // still becomes true after the timeout
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.isForgiven, isTrue);
    });

    test('dispose cancels forgive timer', () async {
      final controller = _TestActionController();
      controller.errorTimeout = const Duration(milliseconds: 10);

      await controller.testExecute(() async {
        throw const ActionControllerException(message: 'fail');
      });

      controller.dispose();

      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.isForgiven, isFalse);
    });
  });

  group('ActionController.setAction', () {
    test('sets action without executing', () {
      final controller = _TestActionController();
      addTearDown(controller.dispose);

      controller.setAction(() async {});
      expect(controller.action, isNotNull);
      expect(controller.isLoading, isFalse);
      expect(controller.isError, isFalse);
    });

    test('action can be invoked to execute', () async {
      final controller = _TestActionController();
      addTearDown(controller.dispose);

      var called = false;
      controller.setAction(() async {
        called = true;
      });

      await controller.action!();
      expect(called, isTrue);
      expect(controller.onSuccessCalls, 1);
    });

    test('setAction clears previous error', () async {
      final controller = _TestActionController();
      controller.errorTimeout = const Duration(seconds: 30);
      addTearDown(controller.dispose);

      await controller.testExecute(() async {
        throw const ActionControllerException(message: 'fail');
      });
      expect(controller.isError, isTrue);

      controller.setAction(() async {});
      expect(controller.isError, isFalse);
      expect(controller.error, isNull);
    });
  });
}
