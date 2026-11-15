import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/practice/domain/self_camera.dart';
import 'package:gestura/features/practice/presentation/view_models/practice_state.dart';
import 'package:gestura_core/gestura_core.dart';

class PracticeViewModel extends Cubit<PracticeState> {
  new(this._content, this._camera, {this._playback = const Playback()})
    : super(const PracticeLoading());

  final ContentRepository _content;
  final SelfCamera _camera;
  Playback _playback;
  SelfCameraSession? _session;

  Future<void> load(SignId id) async {
    if (state is! PracticeLoading) emit(const PracticeLoading());
    final sign = await _content.sign(id);
    if (isClosed) return;
    switch (sign) {
      case Ok(:final value):
        emit(PracticeReady(sign: value, playback: _playback));
        await startCamera();
      case Err(:final failure):
        emit(PracticeFailed(failure));
    }
  }

  Future<void> startCamera() async {
    if (state case final PracticeReady ready when _session == null) {
      emit(ready.copyWith(camera: CameraStatus.starting));
      SelfCameraSession? session;
      CameraStatus status;
      try {
        session = await _camera.start();
        status = CameraStatus.live;
      } on CameraDenied {
        status = CameraStatus.denied;
      } on SelfCameraProblem {
        status = CameraStatus.missing;
      }
      if (isClosed) {
        await session?.stop();
        return;
      }
      _session = session;
      if (state case final PracticeReady current) {
        emit(current.copyWith(camera: status, session: session));
      }
    }
  }

  void setSpeed(PlaybackSpeed speed) =>
      _change(_playback.copyWith(speed: speed));

  void setLooping({required bool looping}) =>
      _change(_playback.copyWith(looping: looping));

  void setMirrored({required bool mirrored}) =>
      _change(_playback.copyWith(mirrored: mirrored));

  void _change(Playback playback) {
    _playback = playback;
    if (state case final PracticeReady ready) {
      emit(ready.copyWith(playback: playback));
    }
  }

  @override
  Future<void> close() async {
    final session = _session;
    _session = null;
    await session?.stop();
    return await super.close();
  }
}
