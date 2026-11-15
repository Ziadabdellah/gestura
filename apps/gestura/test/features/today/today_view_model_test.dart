import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura/features/today/presentation/view_models/today_state.dart';
import 'package:gestura/features/today/presentation/view_models/today_view_model.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_activity_repository.dart';
import '../../helpers/fake_content_repository.dart';
import '../../helpers/fake_progress_repository.dart';
import '../../helpers/fake_review_repository.dart';

final DateTime _now = DateTime(2026, 11, 15, 18);

void main() {
  late FakeContentRepository content;
  late FakeProgressRepository progress;
  late FakeReviewRepository reviews;
  late FakeActivityRepository activity;

  setUp(() {
    content = FakeContentRepository();
    progress = FakeProgressRepository([completed('demo-a1-1')]);
    reviews = FakeReviewRepository([
      ReviewCard(
        updatedAt: reviewNow,
        signId: const SignId('hello'),
        state: CardState.initial(DateTime(2026, 11, 14)),
      ),
      ReviewCard(
        updatedAt: reviewNow,
        signId: const SignId('yes'),
        state: CardState.initial(DateTime(2026, 11, 20)),
      ),
    ]);
    activity = FakeActivityRepository([
      DailyActivity(day: DateTime(2026, 11, 14), lessons: 1, seconds: 300),
      DailyActivity(day: DateTime(2026, 11, 15), reviews: 2, seconds: 420),
    ]);
  });

  Future<TodayViewModel> loaded() => withClock(Clock.fixed(_now), () async {
    final viewModel = TodayViewModel(content, progress, reviews, activity);
    await viewModel.load();
    await pumpEventQueue();
    return viewModel;
  });

  test('gathers the goal, streak, next lesson, reviews and a sign', () async {
    final state = (await loaded()).state as TodayReady;

    expect(state.minutesToday, 7);
    expect(state.streak, 2);
    expect(state.dueReviews, 1);
    expect(state.outline.nextLesson?.lesson.id, const LessonId('demo-a1-2'));
    expect(state.signOfTheDay, isNotNull);
  });

  test('picks the same sign all day and another one tomorrow', () {
    final signs = demoCatalog.signs;
    expect(
      signOfTheDay(signs, DateTime(2026, 11, 15, 8)),
      signOfTheDay(signs, DateTime(2026, 11, 15, 23)),
    );
    expect(
      signOfTheDay(signs, DateTime(2026, 11, 15)),
      isNot(signOfTheDay(signs, DateTime(2026, 11, 16))),
    );
    expect(signOfTheDay(const [], DateTime(2026)), isNull);
  });

  test('reports content that is missing or broken', () async {
    content.failure = const NetworkFailure();
    expect((await loaded()).state, const TodayFailed(NetworkFailure()));

    content = FakeContentRepository(
      catalog: ContentCatalog(
        pack: demoCatalog.pack,
        categories: demoCatalog.categories,
        courses: const [],
        signs: demoCatalog.signs,
      ),
    );
    expect((await loaded()).state, const TodayFailed(NoContentFailure()));
  });

  test('reports progress that cannot be read', () async {
    reviews.failure = const StorageFullFailure();

    expect((await loaded()).state, const TodayFailed(StorageFullFailure()));
  });

  test('updates live and stops listening when closed', () async {
    final viewModel = await loaded();
    await reviews.addSigns({const SignId('please')});
    await pumpEventQueue();

    expect((viewModel.state as TodayReady).dueReviews, 2);

    await withClock(Clock.fixed(_now), viewModel.load);
    await viewModel.close();
  });

  test('stays quiet when closed while loading', () async {
    final hold = content.hold = Completer<void>();
    final viewModel = TodayViewModel(content, progress, reviews, activity);
    final loading = viewModel.load();
    await viewModel.close();
    hold.complete();
    await loading;

    expect(viewModel.state, const TodayLoading());
    expect(const TodayLoading().props, isEmpty);
  });
}
