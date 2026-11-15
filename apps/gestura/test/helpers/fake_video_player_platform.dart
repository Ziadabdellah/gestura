import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlayerPlatform extends VideoPlayerPlatform
    with MockPlatformInterfaceMixin {
  static const Size videoSize = Size(480, 600);
  static const Duration videoDuration = Duration(milliseconds: 2500);

  final List<String> opened = [];
  final List<String> calls = [];
  final Set<String> broken = {};
  final Map<int, StreamController<VideoEvent>> _events = {};
  int _nextId = 0;

  int get openPlayers =>
      _events.values.where((events) => events.hasListener).length;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final asset = options.dataSource.asset ?? options.dataSource.uri ?? '';
    final id = _nextId++;
    opened.add(asset);
    final events = StreamController<VideoEvent>(
      onCancel: () => calls.add('release'),
    );
    _events[id] = events;
    if (broken.contains(asset)) {
      events.addError(
        PlatformException(code: 'VideoError', message: 'cannot open $asset'),
      );
    } else {
      events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          size: videoSize,
          duration: videoDuration,
        ),
      );
    }
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose');
    await _events.remove(playerId)?.close();
  }

  @override
  Future<void> play(int playerId) async => calls.add('play');

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> setLooping(int playerId, bool looping) async =>
      calls.add('looping $looping');

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async =>
      calls.add('speed $speed');

  @override
  Future<void> seekTo(int playerId, Duration position) async =>
      calls.add('seek ${position.inMilliseconds}');

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand();
}
