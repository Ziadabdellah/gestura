import 'package:equatable/equatable.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';

final class LessonResult extends Equatable {
  const new({
    required this.lessonId,
    required this.correctAnswers,
    required this.questions,
    required this.newSigns,
    required this.duration,
  });

  final LessonId lessonId;
  final int correctAnswers;
  final int questions;
  final int newSigns;
  final Duration duration;

  int get score => questions == 0
      ? LessonProgress.maxScore
      : (correctAnswers * LessonProgress.maxScore / questions).round();

  @override
  List<Object?> get props => [
    lessonId,
    correctAnswers,
    questions,
    newSigns,
    duration,
  ];
}
