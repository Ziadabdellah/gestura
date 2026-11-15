import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/learner/learner_cloud.dart';
import 'package:gestura/features/learner/learner_sync.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_activity_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_learner_cloud.dart';
import '../../helpers/fake_progress_repository.dart';
import '../../helpers/fake_review_repository.dart';

class _BrokenLocal extends FakeProgressRepository {
  @override
  Future<Result<ProgressByLesson>> readAll() async =>
      const Err(StorageFullFailure());
}

const List<String> _fullSync = [
  'progress.fetch:guest-uid',
  'progress.save:guest-uid:2',
  'cards.fetch:guest-uid',
  'cards.save:guest-uid:1',
  'activity.fetch:guest-uid',
  'activity.save:guest-uid:1',
];

void main() {
  late FakeAuthRepository auth;
  late FakeProgressRepository progress;
  late FakeReviewRepository reviews;
  late FakeActivityRepository activity;
  late FakeLearnerCloud cloud;
  late LearnerSync sync;

  LearnerSync build({FakeProgressRepository? local}) =>
      LearnerSync(auth, local ?? progress, reviews, activity, cloud.cloud);

  setUp(() {
    auth = FakeAuthRepository();
    progress = FakeProgressRepository([completed('demo-a1-1', score: 60)]);
    reviews = FakeReviewRepository([
      ReviewCard(
        signId: const SignId('hello'),
        state: CardState.initial(reviewNow),
        updatedAt: reviewNow,
      ),
    ]);
    activity = FakeActivityRepository();
    cloud = FakeLearnerCloud();
    cloud.progress.users['guest-uid'] = {
      'demo-a1-2': completed('demo-a1-2', score: 80),
      'demo-a1-1': completed('demo-a1-1', score: 95),
    };
    cloud.activity.users['guest-uid'] = {
      '2026-11-14': DailyActivity(day: DateTime(2026, 11, 14), lessons: 2),
    };
    sync = build();
  });

  tearDown(() => sync.stop());

  Future<void> settle() => pumpEventQueue();

  test('pulls every cloud set, keeps the best and pushes it back', () async {
    sync.start();
    await settle();

    expect(progress.stored[const LessonId('demo-a1-1')]?.bestScore, 95);
    expect(progress.stored[const LessonId('demo-a1-2')]?.bestScore, 80);
    expect(activity.days, hasLength(1));
    expect(cloud.cards.users['guest-uid']?.keys, ['hello']);
    expect(cloud.calls, _fullSync);
  });

  test('pushes only what changed while signed in', () async {
    sync.start();
    await settle();
    cloud.calls.clear();

    await progress.recordCompletion(const LessonId('demo-a1-3'), score: 70);
    await reviews.addSigns({const SignId('yes')});
    await activity.recordLesson(Duration.zero);
    await settle();

    expect(cloud.calls, [
      'progress.save:guest-uid:1',
      'cards.save:guest-uid:1',
    ]);
    expect(cloud.progress.users['guest-uid'], hasLength(3));
    expect(cloud.cards.users['guest-uid'], hasLength(2));
  });

  test('follows the signed-in user and stops when signed out', () async {
    sync.start();
    await settle();

    auth.user = const MemberUser(
      'member-uid',
      email: 'a@b.co',
      emailVerified: true,
    );
    await settle();

    expect(cloud.calls.last, 'activity.save:member-uid:1');

    auth.user = null;
    await settle();
    cloud.calls.clear();
    await progress.recordCompletion(const LessonId('demo-a1-3'), score: 70);
    await settle();

    expect(cloud.calls, isEmpty);
  });

  test('does nothing without a user and refreshes the current one', () async {
    auth.user = null;
    sync.start();
    await settle();

    expect(cloud.calls, isEmpty);
    expect(await sync.refresh(), const Ok<void>(null));

    auth.user = testGuest;
    await settle();
    cloud.calls.clear();

    expect(await sync.refresh(), const Ok<void>(null));
    expect(cloud.calls, _fullSync);
  });

  test('ignores the same user twice and starts only once', () async {
    sync
      ..start()
      ..start();
    await settle();
    auth.user = testGuest;
    await settle();

    expect(cloud.calls, _fullSync);
  });

  test('reports the first problem and still syncs the other sets', () async {
    cloud.progress.fetchFailure = const NetworkFailure();
    cloud.cards.saveFailure = const StorageFullFailure();

    expect(await sync.sync('guest-uid'), const Err<void>(NetworkFailure()));
    expect(progress.stored, hasLength(1));
    expect(cloud.calls, [
      'progress.fetch:guest-uid',
      'cards.fetch:guest-uid',
      'cards.save:guest-uid:1',
      'activity.fetch:guest-uid',
      'activity.save:guest-uid:1',
    ]);
  });

  test('reports a merge that fails', () async {
    progress.saveFailure = const StorageFullFailure();

    expect(await sync.sync('guest-uid'), const Err<void>(StorageFullFailure()));
  });

  test('reports local progress that cannot be read', () async {
    final broken = build(local: _BrokenLocal());

    expect(
      await broken.sync('guest-uid'),
      const Err<void>(StorageFullFailure()),
    );
  });

  test('drops a sync for a user who left while it ran', () async {
    final hold = Completer<void>();
    final calls = <String>[];
    final slowSync = LearnerSync(
      auth,
      progress,
      reviews,
      activity,
      LearnerCloud(
        progress: _SlowSet(hold, calls),
        cards: FakeCloudSet('cards', (card) => card.signId.value, calls),
        activity: FakeCloudSet('activity', (day) => dayKey(day.day), calls),
      ),
    )..start();
    await settle();

    auth.user = null;
    await settle();
    hold.complete();
    await settle();

    await progress.recordCompletion(const LessonId('demo-a1-3'), score: 70);
    await settle();
    expect(
      calls.where((call) => call.startsWith('progress.save')),
      hasLength(1),
    );
    slowSync.stop();
  });
}

class _SlowSet extends FakeCloudSet<LessonProgress> {
  new(this._hold, List<String> calls)
    : super('progress', (item) => item.lessonId.value, calls);

  final Completer<void> _hold;

  @override
  Future<Result<List<LessonProgress>>> fetchAll(String userId) async {
    await _hold.future;
    return await super.fetchAll(userId);
  }
}
