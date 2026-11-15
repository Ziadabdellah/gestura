import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura_core/gestura_core.dart';

sealed class SignDetailState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class SignDetailLoading extends SignDetailState {
  const new();
}

final class SignDetailFailed extends SignDetailState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class SignDetailLoaded extends SignDetailState {
  const new({
    required this.sign,
    required this.related,
    required this.playback,
    this.category,
  });

  final Sign sign;
  final SignCategory? category;
  final List<Sign> related;
  final Playback playback;

  SignDetailLoaded withPlayback(Playback playback) => SignDetailLoaded(
    sign: sign,
    category: category,
    related: related,
    playback: playback,
  );

  @override
  List<Object?> get props => [sign, category, related, playback];
}
