import 'package:gestura/core/cloud/cloud_set.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura_core/gestura_core.dart';

final class LearnerCloud {
  const new({
    required this.progress,
    required this.cards,
    required this.activity,
  });

  final CloudSet<LessonProgress> progress;
  final CloudSet<ReviewCard> cards;
  final CloudSet<DailyActivity> activity;

  Future<Result<void>> deleteAll(String userId) async {
    for (final delete in [
      progress.deleteAll,
      cards.deleteAll,
      activity.deleteAll,
    ]) {
      final result = await delete(userId);
      if (result case Err()) return result;
    }
    return const Ok(null);
  }
}
