import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/learn/domain/course_outline.dart';
import 'package:gestura_core/gestura_core.dart';

sealed class TodayState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class TodayLoading extends TodayState {
  const new();
}

final class TodayFailed extends TodayState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class TodayReady extends TodayState {
  const new({
    required this.course,
    required this.outline,
    required this.dueReviews,
    required this.minutesToday,
    required this.streak,
    this.signOfTheDay,
  });

  final Course course;
  final CourseOutline outline;
  final int dueReviews;
  final int minutesToday;
  final int streak;
  final Sign? signOfTheDay;

  @override
  List<Object?> get props => [
    course,
    outline,
    dueReviews,
    minutesToday,
    streak,
    signOfTheDay,
  ];
}
