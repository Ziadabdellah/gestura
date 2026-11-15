import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gestura/features/practice/domain/self_camera.dart';

class FakeSelfCamera implements SelfCamera {
  SelfCameraProblem? problem;
  Completer<void>? hold;
  int starts = 0;
  int stops = 0;

  @override
  Future<SelfCameraSession> start() async {
    starts++;
    if (hold case final Completer<void> hold) await hold.future;
    if (problem case final SelfCameraProblem problem) throw problem;
    return _FakeSession(this);
  }
}

final class _FakeSession implements SelfCameraSession {
  const new(this._camera);

  static const Key previewKey = Key('fake-camera-preview');

  final FakeSelfCamera _camera;

  @override
  Widget preview() =>
      const ColoredBox(key: previewKey, color: Color(0xFF445566));

  @override
  Future<void> stop() async => _camera.stops++;
}

const Key fakeCameraPreview = _FakeSession.previewKey;
