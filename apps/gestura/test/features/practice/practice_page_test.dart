import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/practice/domain/self_camera.dart';
import 'package:gestura/features/practice/presentation/pages/practice_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_content_repository.dart';
import '../../helpers/fake_self_camera.dart';
import '../../helpers/pump_app.dart';

const String _practice = '/dictionary/sign/hello/practice';

void main() {
  testWidgets('opens from a sign with the video and the camera', (
    tester,
  ) async {
    await tester.pumpApp(initialLocation: '/dictionary/sign/hello');

    await tester.tap(find.byTooltip('Practise with the camera'));
    await tester.pumpAndSettle();

    expect(find.byType(PracticePage), findsOneWidget);
    expect(find.byKey(fakeCameraPreview), findsOneWidget);
    expect(fakeVideo.opened.last, endsWith('hello.mp4'));
  });

  testWidgets('asks for camera access and tries again', (tester) async {
    final camera = FakeSelfCamera()..problem = const CameraDenied();
    await tester.pumpApp(initialLocation: _practice, camera: camera);

    expect(find.textContaining("can't use the camera"), findsOneWidget);
    camera.problem = null;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(camera.starts, 2);
    expect(find.byKey(fakeCameraPreview), findsOneWidget);
  });

  testWidgets('says when there is no camera', (tester) async {
    await tester.pumpApp(
      initialLocation: _practice,
      camera: FakeSelfCamera()..problem = const CameraMissing(),
    );

    expect(find.text('No camera is available on this device.'), findsOneWidget);
  });

  testWidgets('retries a sign that failed and changes playback', (
    tester,
  ) async {
    final content = FakeContentRepository()..failure = const NetworkFailure();
    await tester.pumpApp(initialLocation: _practice, content: content);

    content.failure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0.5×'));
    await tester.tap(find.byTooltip('Loop'));
    await tester.tap(find.byTooltip('Mirror'));
    await tester.pumpAndSettle();

    expect(fakeVideo.calls, contains('speed 0.5'));
  });

  for (final settings in [
    englishLight,
    const AppSettings(
      language: AppLanguage.arabic,
      theme: AppThemePreference.dark,
      onboardingComplete: true,
    ),
  ]) {
    testWidgets('meets the accessibility guidelines in '
        '${settings.language.name}', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(initialLocation: _practice, settings: settings);

      expect(find.bySemanticsLabel(RegExp('camera|الكاميرا')), findsWidgets);
      await tester.expectAccessible();
      handle.dispose();
    });
  }

  testWidgets('fits at 200% text on a small phone', (tester) async {
    await tester.pumpApp(
      initialLocation: _practice,
      surfaceSize: const Size(320, 640),
      textScale: 2,
      camera: FakeSelfCamera()..problem = const CameraDenied(),
    );

    expect(tester.takeException(), isNull);
  });
}
