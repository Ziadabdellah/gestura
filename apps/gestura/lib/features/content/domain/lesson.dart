import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/localized_text.dart';
import 'package:meta/meta.dart';

@immutable
sealed class LessonStep {
  const new(this.sign);

  final SignId sign;
}

final class LearnSignStep extends LessonStep {
  const new(super.sign);
}

final class ChooseWordStep extends LessonStep {
  const new(super.sign, this.options);

  final List<SignId> options;
}

final class ChooseVideoStep extends LessonStep {
  const new(super.sign, this.options);

  final List<SignId> options;
}

@immutable
final class Lesson {
  const new({
    required this.id,
    required this.courseId,
    required this.unitIndex,
    required this.order,
    required this.title,
    required this.steps,
  });

  final LessonId id;
  final CourseId courseId;
  final int unitIndex;
  final int order;
  final LocalizedText title;
  final List<LessonStep> steps;

  Set<SignId> get signs => {
    for (final step in steps)
      ...switch (step) {
        LearnSignStep(:final sign) => [sign],
        ChooseWordStep(:final sign, :final options) ||
        ChooseVideoStep(:final sign, :final options) => [sign, ...options],
      },
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Lesson && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
