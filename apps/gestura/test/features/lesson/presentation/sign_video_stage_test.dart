import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/media/media_cache.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/lesson/presentation/widgets/sign_video_stage.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/fake_media_cache.dart';
import '../../../helpers/fake_video_player_platform.dart';
import '../../../helpers/golden_scenario.dart';

final Sign _hello = demoCatalog.sign(const SignId('hello'))!;
final Sign _thanks = demoCatalog.sign(const SignId('thank-you'))!;

const AppSettings _settings = AppSettings(
  language: AppLanguage.english,
  theme: AppThemePreference.light,
);

void main() {
  late FakeVideoPlayerPlatform video;
  late List<String> changes;

  setUp(() {
    video = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = video;
    changes = [];
  });

  Future<void> pumpStage(
    WidgetTester tester, {
    Sign? sign,
    Playback playback = const Playback(),
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 780),
          disableAnimations: reduceMotion,
        ),
        child: viewUnderTest(
          settings: _settings,
          child: Scaffold(
            body: SingleChildScrollView(
              child: SignVideoStage(
                sign: sign,
                playback: playback,
                emptyMessage: 'Pick a video',
                onSpeedChanged: (speed) => changes.add('speed ${speed.rate}'),
                onLoopingChanged: (looping) => changes.add('looping $looping'),
                onMirroredChanged: (mirrored) =>
                    changes.add('mirrored $mirrored'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens the sign video and plays it on a loop', (tester) async {
    await pumpStage(tester, sign: _hello);

    expect(video.opened, [(_hello.media.video as AssetMedia).path]);
    expect(
      video.calls,
      containsAllInOrder(['looping true', 'play', 'speed 1.0']),
    );
    expect(find.byType(VideoPlayer), findsOneWidget);
  });

  testWidgets('waits for a tap under reduce motion', (tester) async {
    await pumpStage(tester, sign: _hello, reduceMotion: true);

    expect(video.calls, isNot(contains('play')));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byType(VideoPlayer));
    await tester.pumpAndSettle();

    expect(video.calls, contains('play'));
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

    await tester.tap(find.byType(VideoPlayer));
    await tester.pumpAndSettle();

    expect(video.calls.last, 'pause');
  });

  testWidgets('can be played and paused by screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpStage(tester, sign: _hello);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Sign video')),
      isSemantics(
        label: 'Sign video',
        isButton: true,
        hasTapAction: true,
        onTapHint: 'Pause',
      ),
    );
    handle.dispose();
  });

  testWidgets('replays from the start', (tester) async {
    await pumpStage(tester, sign: _hello);

    await tester.tap(find.byTooltip('Replay'));
    await tester.pumpAndSettle();

    expect(video.calls, containsAllInOrder(['seek 0', 'play']));
  });

  testWidgets('reports speed, loop and mirror choices', (tester) async {
    await pumpStage(tester, sign: _hello);

    await tester.tap(find.text('0.5×'));
    await tester.tap(find.byTooltip('Loop'));
    await tester.tap(find.byTooltip('Mirror'));

    expect(changes, ['speed 0.5', 'looping false', 'mirrored true']);
  });

  testWidgets('applies new playback settings to the video', (tester) async {
    await pumpStage(tester, sign: _hello);

    await pumpStage(
      tester,
      sign: _hello,
      playback: const Playback(
        speed: PlaybackSpeed.threeQuarters,
        looping: false,
        mirrored: true,
      ),
    );

    expect(video.calls, containsAll(['speed 0.75', 'looping false']));
    expect(
      tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byType(VideoPlayer),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage
          .first,
      -1,
    );
    expect(video.opened, hasLength(1));
  });

  testWidgets('swaps the video when the sign changes', (tester) async {
    await pumpStage(tester, sign: _hello);

    await pumpStage(tester, sign: _thanks);

    expect(video.opened, [
      (_hello.media.video as AssetMedia).path,
      (_thanks.media.video as AssetMedia).path,
    ]);
    expect(video.calls, contains('release'));
    expect(video.openPlayers, 1);
  });

  group('published signs', () {
    late FakeMediaCache cache;
    Sign remote(Sign sign) => Sign(
      id: sign.id,
      gloss: sign.gloss,
      meaning: sign.meaning,
      category: sign.category,
      media: SignMedia(
        video: RemoteMedia(
          Uri.parse(
            'https://c.web.app/content/demo/media/${sign.id.value}.mp4',
          ),
        ),
        thumbnail: RemoteMedia(
          Uri.parse(
            'https://c.web.app/content/demo/media/${sign.id.value}.webp',
          ),
        ),
        duration: sign.media.duration,
      ),
      source: sign.source,
    );

    setUp(() async {
      await getIt.reset();
      cache = FakeMediaCache('assets/content/demo/media');
      getIt.registerSingleton<MediaCache>(cache);
    });

    tearDown(getIt.reset);

    testWidgets('plays a downloaded video from the device', (tester) async {
      await pumpStage(tester, sign: remote(_hello));
      await tester.pumpAndSettle();

      expect(
        video.opened.single,
        endsWith('assets/content/demo/media/hello.mp4'),
      );
    });

    testWidgets('keeps the poster when a video cannot be downloaded', (
      tester,
    ) async {
      cache.missing.add('hello.mp4');

      await pumpStage(tester, sign: remote(_hello));
      await tester.pumpAndSettle();

      expect(video.opened, isEmpty);
      expect(find.byType(VideoPlayer), findsNothing);
    });

    testWidgets('drops a download for a sign that is no longer shown', (
      tester,
    ) async {
      final hold = cache.hold = Completer<void>();
      await pumpStage(tester, sign: remote(_hello));
      await pumpStage(tester, sign: remote(_thanks));
      hold.complete();
      await tester.pumpAndSettle();

      expect(video.opened.single, endsWith('thank-you.mp4'));
      expect(video.openPlayers, 1);
    });
  });

  testWidgets('keeps the poster when a video cannot be opened', (tester) async {
    video.broken.add((_hello.media.video as AssetMedia).path);

    await pumpStage(tester, sign: _hello);

    expect(tester.takeException(), isNull);
    expect(find.byType(VideoPlayer), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.replay_rounded),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();
    expect(video.calls, isNot(contains('play')));
  });

  testWidgets('shows a hint and opens nothing without a sign', (tester) async {
    await pumpStage(tester);

    expect(find.text('Pick a video'), findsOneWidget);
    expect(video.opened, isEmpty);
  });

  testWidgets('ignores playback changes before the video is ready', (
    tester,
  ) async {
    await pumpStage(tester);
    await pumpStage(tester, playback: const Playback(looping: false));

    expect(video.calls, isEmpty);
  });

  testWidgets('closes the video when it leaves the screen', (tester) async {
    await pumpStage(tester, sign: _hello);

    await tester.pumpWidget(const SizedBox());

    expect(video.calls.last, 'release');
    expect(video.openPlayers, 0);
  });
}
