import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/practice/domain/self_camera.dart';
import 'package:gestura/features/practice/presentation/view_models/practice_state.dart';
import 'package:gestura/features/practice/presentation/view_models/practice_view_model.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_content_repository.dart';
import '../../helpers/fake_self_camera.dart';

const SignId _hello = SignId('hello');

void main() {
  late FakeContentRepository content;
  late FakeSelfCamera camera;

  setUp(() {
    content = FakeContentRepository();
    camera = FakeSelfCamera();
  });

  test('shows the sign and turns the camera on, then off on close', () async {
    final viewModel = PracticeViewModel(content, camera);
    expect(viewModel.state, const PracticeLoading());
    expect(const PracticeLoading().props, isEmpty);

    await viewModel.load(_hello);

    final ready = viewModel.state as PracticeReady;
    expect(ready.sign.gloss, 'HELLO');
    expect(ready.camera, CameraStatus.live);
    expect(ready.session, isNotNull);

    await viewModel.startCamera();
    expect(camera.starts, 1);

    await viewModel.close();
    expect(camera.stops, 1);
  });

  test('explains a denied camera and tries again', () async {
    camera.problem = const CameraDenied();
    final viewModel = PracticeViewModel(content, camera);
    await viewModel.load(_hello);
    expect((viewModel.state as PracticeReady).camera, CameraStatus.denied);

    camera.problem = null;
    await viewModel.startCamera();
    expect((viewModel.state as PracticeReady).camera, CameraStatus.live);
    await viewModel.close();
  });

  test('says when there is no camera', () async {
    camera.problem = const CameraMissing();
    final viewModel = PracticeViewModel(content, camera);
    await viewModel.load(_hello);

    expect((viewModel.state as PracticeReady).camera, CameraStatus.missing);
    await viewModel.close();
    expect(camera.stops, 0);
  });

  test('stops a camera that opens after the page closed', () async {
    final hold = camera.hold = Completer<void>();
    final viewModel = PracticeViewModel(content, camera);
    final loading = viewModel.load(_hello);
    await pumpEventQueue();
    await viewModel.close();
    hold.complete();
    await loading;

    expect(camera.stops, 1);
  });

  test('reports a missing sign, loads again and changes playback', () async {
    final viewModel = PracticeViewModel(
      content,
      camera,
      playback: const Playback(mirrored: true),
    );
    await viewModel.load(const SignId('missing'));
    expect(viewModel.state, const PracticeFailed(NotFoundFailure()));
    await viewModel.startCamera();
    expect(camera.starts, 0);

    viewModel.setSpeed(PlaybackSpeed.half);
    await viewModel.load(_hello);
    viewModel
      ..setLooping(looping: false)
      ..setMirrored(mirrored: false);
    expect(
      (viewModel.state as PracticeReady).playback,
      const Playback(speed: PlaybackSpeed.half, looping: false),
    );
    await viewModel.close();
  });

  test('stays quiet when closed while the sign loads', () async {
    final hold = content.hold = Completer<void>();
    final viewModel = PracticeViewModel(content, camera);
    final loading = viewModel.load(_hello);
    await viewModel.close();
    hold.complete();
    await loading;

    expect(viewModel.state, const PracticeLoading());
  });
}
