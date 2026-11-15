import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/practice/domain/self_camera.dart';
import 'package:gestura_core/gestura_core.dart';

enum CameraStatus { starting, live, denied, missing }

sealed class PracticeState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class PracticeLoading extends PracticeState {
  const new();
}

final class PracticeFailed extends PracticeState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class PracticeReady extends PracticeState {
  const new({
    required this.sign,
    required this.playback,
    this.camera = CameraStatus.starting,
    this.session,
  });

  final Sign sign;
  final Playback playback;
  final CameraStatus camera;
  final SelfCameraSession? session;

  PracticeReady copyWith({
    Playback? playback,
    CameraStatus? camera,
    SelfCameraSession? session,
  }) => PracticeReady(
    sign: sign,
    playback: playback ?? this.playback,
    camera: camera ?? this.camera,
    session: session ?? this.session,
  );

  @override
  List<Object?> get props => [sign, playback, camera, session];
}
