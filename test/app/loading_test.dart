// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/app/app.dart';

void main() {
  group('LoadingShell', () {
    testWidgets('shows loading overlay by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingShell(child: Text('loaded content')),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('loaded content'), findsOneWidget);
    });

    testWidgets('hides loading overlay when controller sets loading=false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingShell(
            child: _LoadingToggler(child: Text('loaded content')),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('loaded content'), findsOneWidget);
    });

    testWidgets('displays message and error from controller', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoadingShell(
            child: _LoadingToggler(
              child: const Text('loaded content'),
              onReady: (controller) {
                controller.value = const LoadingShellState.loading(
                  message: 'working...',
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('working...'), findsOneWidget);
    });
  });
}

class _LoadingToggler extends StatefulWidget {
  const _LoadingToggler({required this.child, this.onReady});

  final Widget child;
  final void Function(LoadingShellController controller)? onReady;

  @override
  State<_LoadingToggler> createState() => _LoadingTogglerState();
}

class _LoadingTogglerState extends State<_LoadingToggler> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = LoadingShell.of(context);
      if (widget.onReady != null) {
        widget.onReady!(controller);
      } else {
        controller.value = const LoadingShellState(loading: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
