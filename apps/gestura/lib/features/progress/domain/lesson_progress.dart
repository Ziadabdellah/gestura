import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:meta/meta.dart';

@immutable
final class LessonProgress {
  const new({
    required this.lessonId,
    required this.bestScore,
    required this.completedAt,
    required this.updatedAt,
  });

  static const int minScore = 0;
  static const int maxScore = 100;

  final LessonId lessonId;
  final int bestScore;
  final DateTime completedAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonProgress &&
          other.lessonId == lessonId &&
          other.bestScore == bestScore &&
          other.completedAt == completedAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(lessonId, bestScore, completedAt, updatedAt);
}
