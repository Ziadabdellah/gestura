import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:gestura/features/practice/domain/self_camera.dart';
import 'package:injectable/injectable.dart';

const Set<String> deniedCameraCodes = {
  'CameraAccessDenied',
  'CameraAccessDeniedWithoutPrompt',
  'CameraAccessRestricted',
  'cameraPermission',
};

@LazySingleton(as: SelfCamera)
final class DeviceSelfCamera implements SelfCamera {
  const new();

  @override
  Future<SelfCameraSession> start() async {
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (error) {
      throw deniedCameraCodes.contains(error.code)
          ? const CameraDenied()
          : const CameraMissing();
    }
    if (cameras.isEmpty) throw const CameraMissing();
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await controller.initialize();
    } on CameraException catch (error) {
      await controller.dispose();
      throw deniedCameraCodes.contains(error.code)
          ? const CameraDenied()
          : const CameraMissing();
    }
    return _DeviceSession(controller);
  }
}

final class _DeviceSession implements SelfCameraSession {
  const new(this._controller);

  final CameraController _controller;

  @override
  Widget preview() => CameraPreview(_controller);

  @override
  Future<void> stop() => _controller.dispose();
}
