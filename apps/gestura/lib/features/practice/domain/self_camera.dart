import 'package:flutter/widgets.dart';

abstract interface class SelfCamera {
  Future<SelfCameraSession> start();
}

abstract interface class SelfCameraSession {
  Widget preview();

  Future<void> stop();
}

sealed class SelfCameraProblem implements Exception {
  const new();
}

final class CameraDenied extends SelfCameraProblem {
  const new();
}

final class CameraMissing extends SelfCameraProblem {
  const new();
}
