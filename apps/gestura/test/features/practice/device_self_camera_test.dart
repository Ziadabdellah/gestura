import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/practice/data/device_self_camera.dart';
import 'package:gestura/features/practice/domain/self_camera.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

const CameraDescription _back = CameraDescription(
  name: 'back',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

const CameraDescription _front = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

class _FakeCameraPlatform extends CameraPlatform
    with MockPlatformInterfaceMixin {
  List<CameraDescription> cameras = const [_back, _front];
  CameraException? listError;
  PlatformException? initializeError;
  final List<String> calls = [];

  @override
  Future<List<CameraDescription>> availableCameras() async {
    if (listError case final CameraException error) throw error;
    return cameras;
  }

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings mediaSettings,
  ) async {
    calls.add(
      'create ${cameraDescription.name} audio ${mediaSettings.enableAudio}',
    );
    return 7;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(
        CameraInitializedEvent(
          cameraId,
          480,
          640,
          ExposureMode.auto,
          false,
          FocusMode.auto,
          false,
        ),
      );

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      StreamController<CameraErrorEvent>().stream;

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    if (initializeError case final PlatformException error) throw error;
  }

  @override
  Widget buildPreview(int cameraId) => const SizedBox(key: Key('preview'));

  @override
  Future<void> dispose(int cameraId) async => calls.add('dispose $cameraId');
}

void main() {
  late _FakeCameraPlatform platform;

  setUp(() => CameraPlatform.instance = platform = _FakeCameraPlatform());

  testWidgets('opens the front camera without sound and closes it', (
    tester,
  ) async {
    final session = await tester.runAsync(const DeviceSelfCamera().start);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: session!.preview(),
      ),
    );

    expect(find.byKey(const Key('preview')), findsOneWidget);
    await tester.runAsync(session.stop);
    expect(platform.calls, ['create front audio false', 'dispose 7']);
  });

  test('falls back to the only camera there is', () async {
    platform.cameras = const [_back];

    await (await const DeviceSelfCamera().start()).stop();

    expect(platform.calls.first, 'create back audio false');
  });

  test('tells a denied camera from a missing one', () async {
    platform.initializeError = PlatformException(code: 'CameraAccessDenied');
    await expectLater(
      const DeviceSelfCamera().start(),
      throwsA(isA<CameraDenied>()),
    );
    expect(platform.calls.last, 'dispose 7');

    platform.initializeError = PlatformException(code: 'unknown');
    await expectLater(
      const DeviceSelfCamera().start(),
      throwsA(isA<CameraMissing>()),
    );

    platform
      ..cameras = const []
      ..initializeError = null;
    await expectLater(
      const DeviceSelfCamera().start(),
      throwsA(isA<CameraMissing>()),
    );

    for (final (code, expected) in [
      ('cameraPermission', isA<CameraDenied>()),
      ('noCamera', isA<CameraMissing>()),
    ]) {
      platform.listError = CameraException(code, null);
      await expectLater(const DeviceSelfCamera().start(), throwsA(expected));
    }
  });
}
