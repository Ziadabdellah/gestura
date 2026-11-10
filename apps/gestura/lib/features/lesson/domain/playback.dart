import 'package:equatable/equatable.dart';

enum PlaybackSpeed {
  half(0.5),
  threeQuarters(0.75),
  normal(1);

  new(this.rate);

  final double rate;
}

final class Playback extends Equatable {
  const new({
    this.speed = PlaybackSpeed.normal,
    this.looping = true,
    this.mirrored = false,
  });

  final PlaybackSpeed speed;
  final bool looping;
  final bool mirrored;

  Playback copyWith({PlaybackSpeed? speed, bool? looping, bool? mirrored}) =>
      Playback(
        speed: speed ?? this.speed,
        looping: looping ?? this.looping,
        mirrored: mirrored ?? this.mirrored,
      );

  @override
  List<Object?> get props => [speed, looping, mirrored];
}
