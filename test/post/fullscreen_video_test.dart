// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_posts.dart';

class MockClient extends Mock implements Client {}

class MockHistoryClient extends Mock implements HistoryClient {}

class MockVideoPlayer extends Mock implements VideoPlayer {}

class MockCacheManager extends Mock implements BaseCacheManager {}

class TestVideoService extends VideoService {
  TestVideoService(this.player) : super(muteVideos: true);

  final VideoPlayer player;

  @override
  VideoPlayer getVideo(String key) => player;
}

PlayerStream emptyPlayerStream() => const PlayerStream(
  Stream<Playlist>.empty(),
  Stream<bool>.empty(),
  Stream<bool>.empty(),
  Stream<Duration>.empty(),
  Stream<Duration>.empty(),
  Stream<double>.empty(),
  Stream<double>.empty(),
  Stream<double>.empty(),
  Stream<bool>.empty(),
  Stream<double>.empty(),
  Stream<Duration>.empty(),
  Stream<PlaylistMode>.empty(),
  Stream<bool>.empty(),
  Stream<AudioParams>.empty(),
  Stream<VideoParams>.empty(),
  Stream<double?>.empty(),
  Stream<AudioDevice>.empty(),
  Stream<List<AudioDevice>>.empty(),
  Stream<Track>.empty(),
  Stream<Tracks>.empty(),
  Stream<int?>.empty(),
  Stream<int?>.empty(),
  Stream<List<String>>.empty(),
  Stream<PlayerLog>.empty(),
  Stream<String>.empty(),
);

void main() {
  late MockClient mockClient;
  late MockHistoryClient mockHistories;
  late MockVideoPlayer player;
  late MockCacheManager cacheManager;
  late TestVideoService videoService;
  late Settings settings;

  final post = makePost(
    ext: 'mp4',
    file: 'https://example.com/video.mp4',
    sample: 'https://example.com/sample.jpg',
  );

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    registerFallbackValue(
      HistoryRequest(
        visitedAt: DateTime(2024),
        link: '',
        category: HistoryCategory.items,
        type: HistoryType.posts,
      ),
    );
    registerFallbackValue(Duration.zero);
    registerFallbackValue(<String, String>{});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = Settings(prefs);

    mockHistories = MockHistoryClient();
    when(() => mockHistories.add(any())).thenAnswer((_) async {});

    mockClient = MockClient();
    when(() => mockClient.histories).thenReturn(mockHistories);
    when(() => mockClient.hasLogin).thenReturn(false);

    player = MockVideoPlayer();
    when(() => player.state).thenReturn(
      const PlayerState(
        position: Duration(seconds: 10),
        duration: Duration(seconds: 60),
        buffer: Duration(seconds: 30),
      ),
    );
    when(() => player.stream).thenReturn(emptyPlayerStream());
    when(() => player.initialized).thenAnswer((_) => Stream<bool>.value(false));
    when(() => player.isInitialized).thenReturn(false);
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.pause()).thenAnswer((_) async {});
    when(() => player.seek(any())).thenAnswer((_) async {});

    videoService = TestVideoService(player);

    cacheManager = MockCacheManager();
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => const Stream<FileResponse>.empty());
  });

  final navigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'fullscreen_video_test',
  );

  Widget buildApp() {
    return MultiProvider(
      providers: [
        Provider<Client>.value(value: mockClient),
        Provider<Settings>.value(value: settings),
        ChangeNotifierProvider<VideoService>.value(value: videoService),
        ChangeNotifierProvider<PostController?>.value(value: null),
        ChangeNotifierProvider<AdaptiveScaffoldController?>.value(value: null),
        Provider<BaseCacheManager>.value(value: cacheManager),
        Provider<ImageCacheSize?>.value(value: null),
        DefaultRouteObserver(),
      ],
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
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(),
          ),
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );
  }

  // pumpAndSettle never settles here because the unloaded image placeholder
  // shows an indeterminate progress indicator, so pump a fixed duration
  // instead. One second covers every transition and pending timer.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pushFullscreen(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => PostFullscreen(post: post)),
    );
    await settle(tester);
    expect(find.byType(PostFullscreen), findsOneWidget);
  }

  // Taps the video area so the auto-hiding controls are shown.
  Future<void> showControls(WidgetTester tester) async {
    await tester.tapAt(const Offset(100, 300));
    await settle(tester);
  }

  group('PostFullscreen video controls', () {
    testWidgets('tapping the video toggles the control bar', (tester) async {
      await pushFullscreen(tester);
      final barContext = tester.element(find.byType(VideoBar));
      final controller = ScaffoldFrame.maybeOf(barContext)!;

      expect(controller.visible, isFalse);
      await tester.tapAt(const Offset(100, 300));
      await settle(tester);
      expect(controller.visible, isTrue);

      await tester.tapAt(const Offset(100, 300));
      await settle(tester);
      expect(controller.visible, isFalse);
    });

    testWidgets('control bar buttons respond to taps', (tester) async {
      await pushFullscreen(tester);
      await showControls(tester);

      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      await tester.tap(find.byIcon(Icons.volume_off));
      await settle(tester);

      expect(videoService.muteVideos, isFalse);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('dragging the timeline slider seeks the player', (
      tester,
    ) async {
      await pushFullscreen(tester);
      await showControls(tester);

      clearInteractions(player);
      await tester.drag(find.byType(Slider), const Offset(80, 0));
      await settle(tester);

      verify(() => player.seek(any())).called(1);
    });

    testWidgets('exit fullscreen button pops the route', (tester) async {
      await pushFullscreen(tester);
      await showControls(tester);

      await tester.tap(find.byIcon(Icons.fullscreen_exit));
      await settle(tester);

      expect(find.byType(PostFullscreen), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('play button starts playback', (tester) async {
      await pushFullscreen(tester);
      clearInteractions(player);

      await tester.tap(find.byType(VideoButton));
      await settle(tester);

      verify(() => player.play()).called(1);
    });

    testWidgets('double tap on the right side seeks forward', (tester) async {
      await pushFullscreen(tester);
      clearInteractions(player);

      await tester.tapAt(const Offset(600, 300));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(const Offset(600, 300));
      await settle(tester);

      verify(() => player.seek(const Duration(seconds: 20))).called(1);
    });
  });
}
