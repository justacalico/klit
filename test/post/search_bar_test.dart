// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/traits/traits.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockClient mockClient;
  late ValueNotifier<Traits> traits;
  late Settings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = Settings(prefs);

    mockClient = MockClient();
    traits = ValueNotifier(
      const Traits(
        id: 1,
        userId: null,
        denylist: [],
        homeTags: '',
        avatar: null,
        perPage: null,
      ),
    );
    when(() => mockClient.traits).thenReturn(traits);
  });

  final navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search_bar_test');

  Widget buildApp({required bool requestFocus}) {
    final controller = PostController(client: mockClient);
    addTearDown(controller.dispose);
    return MultiProvider(
      providers: [
        Provider<Settings>.value(value: settings),
        Provider<Client>.value(value: mockClient),
        DefaultRouteObserver(),
      ],
      child: PrivateTextFields(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: SearchPageAppBar(
              controller: controller,
              requestFocus: requestFocus,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
  group('SearchPageAppBar', () {
    testWidgets('requests focus when requestFocus is true', (tester) async {
      await tester.pumpWidget(buildApp(requestFocus: true));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode, isNotNull);
      expect(textField.focusNode!.hasFocus, isTrue);
    });

    testWidgets('drops focus when a route is pushed on top', (tester) async {
      await tester.pumpWidget(buildApp(requestFocus: true));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode!.hasFocus, isTrue);

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();

      expect(textField.focusNode!.hasFocus, isFalse);
    });

    testWidgets('does not request focus when requestFocus is false',
        (tester) async {
      await tester.pumpWidget(buildApp(requestFocus: false));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode!.hasFocus, isFalse);
    });
  });
}

class MockClient extends Mock implements Client {}
