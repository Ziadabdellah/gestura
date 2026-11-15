import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestura/core/cloud/cloud_set.dart';
import 'package:gestura/core/cloud/user_documents.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura_core/gestura_core.dart';

DateTime _utc(Timestamp value) => value.toDate().toUtc();

final class ProgressCodec implements DocumentCodec<LessonProgress> {
  const new();

  @override
  String idOf(LessonProgress item) => item.lessonId.value;

  @override
  StoredDocument encode(LessonProgress item) => (
    id: idOf(item),
    data: {
      'bestScore': item.bestScore,
      'completedAt': Timestamp.fromDate(item.completedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  );

  @override
  LessonProgress? decode(StoredDocument document) => switch (document.data) {
    {
      'bestScore': final int score,
      'completedAt': final Timestamp completed,
      'updatedAt': final Timestamp updated,
    }
        when score >= LessonProgress.minScore &&
            score <= LessonProgress.maxScore =>
      LessonProgress(
        lessonId: LessonId(document.id),
        bestScore: score,
        completedAt: _utc(completed),
        updatedAt: _utc(updated),
      ),
    _ => null,
  };
}

final class ReviewCardCodec implements DocumentCodec<ReviewCard> {
  const new();

  @override
  String idOf(ReviewCard item) => item.signId.value;

  @override
  StoredDocument encode(ReviewCard item) => (
    id: idOf(item),
    data: {
      'repetitions': item.state.repetitions,
      'intervalDays': item.state.intervalDays,
      'ease': item.state.ease,
      'dueAt': Timestamp.fromDate(item.state.dueAt),
      'lapses': item.state.lapses,
      'updatedAt': Timestamp.fromDate(item.updatedAt),
    },
  );

  @override
  ReviewCard? decode(StoredDocument document) => switch (document.data) {
    {
      'repetitions': final int repetitions,
      'intervalDays': final int intervalDays,
      'ease': final num ease,
      'dueAt': final Timestamp dueAt,
      'lapses': final int lapses,
      'updatedAt': final Timestamp updatedAt,
    }
        when repetitions >= 0 &&
            intervalDays >= 0 &&
            lapses >= 0 &&
            ease >= CardState.minEase =>
      ReviewCard(
        signId: SignId(document.id),
        state: CardState(
          repetitions: repetitions,
          intervalDays: intervalDays,
          ease: ease.toDouble(),
          dueAt: _utc(dueAt),
          lapses: lapses,
        ),
        updatedAt: _utc(updatedAt),
      ),
    _ => null,
  };
}

final class ActivityCodec implements DocumentCodec<DailyActivity> {
  const new();

  static final RegExp _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  @override
  String idOf(DailyActivity item) => dayKey(item.day);

  @override
  StoredDocument encode(DailyActivity item) => (
    id: idOf(item),
    data: {
      'lessons': item.lessons,
      'reviews': item.reviews,
      'seconds': item.seconds,
    },
  );

  @override
  DailyActivity? decode(StoredDocument document) => switch (document.data) {
    {
      'lessons': final int lessons,
      'reviews': final int reviews,
      'seconds': final int seconds,
    }
        when _day.hasMatch(document.id) &&
            lessons >= 0 &&
            reviews >= 0 &&
            seconds >= 0 =>
      DailyActivity(
        day: dayOf(document.id),
        lessons: lessons,
        reviews: reviews,
        seconds: seconds,
      ),
    _ => null,
  };
}
