import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/learn/domain/course_outline.dart';
import 'package:gestura_core/gestura_core.dart';

sealed class LearnState extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

final class LearnLoading extends LearnState {
  const new();
}

final class LearnLoaded extends LearnState {
  const new({required this.pack, required this.course, required this.outline});

  final SignLanguagePack pack;
  final Course course;
  final CourseOutline outline;

  @override
  List<Object?> get props => [pack, course, outline];
}

final class LearnFailed extends LearnState {
  const new(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
