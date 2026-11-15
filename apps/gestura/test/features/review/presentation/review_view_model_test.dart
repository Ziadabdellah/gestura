import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura/features/review/presentation/view_models/review_state.dart';
import 'package:gestura/features/review/presentation/view_models/review_view_model.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../../helpers/fake_activity_repository.dart';
import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/fake_review_repository.dart';

ReviewCard _due(String id, {int daysAgo = 0}) => ReviewCard(
  updatedAt: reviewNow,
  signId: SignId(id),
  state: CardState.initial(reviewNow.subtract(Duration(days: daysAgo))),
);

ReviewCard _later(String id) => ReviewCard(
  updatedAt: reviewNow,
  signId: SignId(id),
  state: review(CardState.initial(reviewNow), ReviewGrade.good, reviewNow),
);

void main() {
  late FakeReviewRepository reviews;
  late FakeContentRepository content;
  late FakeActivityRepository activity;

  setUp(() {
    reviews = FakeReviewRepository([
      _due('hello', daysAgo: 1),
      _due('yes', daysAgo: 3),
      _later('no'),
    ]);
    content = FakeContentRepository();
    activity = FakeActivityRepository();
  });

  ReviewViewModel build() => ReviewViewModel(reviews, content, activity);

  Future<T> at<T>(Future<T> Function() body) =>
      withClock(Clock.fixed(reviewNow), body);

  test('starts loading', () => expect(build().state, const ReviewLoading()));

  test('reviews only due cards, the oldest first', () async {
    final viewModel = build();
    await at(viewModel.load);

    final state = viewModel.state as ReviewInProgress;
    expect(state.cards.map((card) => card.signId.value), ['yes', 'hello']);
    expect(state.sign.gloss, 'YES');
    expect(state.daysAfter(ReviewGrade.good), 1);
    expect(state.daysAfter(ReviewGrade.again), 1);
  });

  test('reveals, grades, saves and records the time', () async {
    final viewModel = build();
    await at(viewModel.load);

    await at(() => viewModel.grade(ReviewGrade.good));
    expect((viewModel.state as ReviewInProgress).index, 0);

    viewModel
      ..reveal()
      ..reveal();
    await at(() => viewModel.grade(ReviewGrade.good));
    expect((viewModel.state as ReviewInProgress).index, 1);
    expect(
      reviews.stored[const SignId('yes')]!.state.dueAt,
      DateTime.utc(2026, 11, 16, 9),
    );

    viewModel.reveal();
    await at(() => viewModel.grade(ReviewGrade.again));

    expect(viewModel.state, const ReviewFinished(reviewed: 2, remembered: 1));
    expect(activity.calls, ['review:0', 'review:0']);
  });

  test('says when nothing is due', () async {
    reviews = FakeReviewRepository([_later('no')]);
    final viewModel = build();
    await at(viewModel.load);

    expect(viewModel.state, const ReviewNothingDue());
  });

  test('skips cards whose sign is gone', () async {
    reviews = FakeReviewRepository([_due('gone')]);
    final viewModel = build();
    await at(viewModel.load);

    expect(viewModel.state, const ReviewNothingDue());
  });

  blocTest<ReviewViewModel, ReviewState>(
    'reports cards that cannot be read and loads again',
    setUp: () => reviews.failure = const StorageFullFailure(),
    build: build,
    act: (viewModel) async {
      await at(viewModel.load);
      reviews.failure = null;
      await at(viewModel.load);
    },
    skip: 1,
    expect: () => [const ReviewLoading(), isA<ReviewInProgress>()],
  );

  blocTest<ReviewViewModel, ReviewState>(
    'reports signs that cannot be loaded',
    setUp: () => content.failure = const NetworkFailure(),
    build: build,
    act: (viewModel) => at(viewModel.load),
    expect: () => [const ReviewFailed(NetworkFailure())],
  );

  test('changes playback during a session', () async {
    final viewModel = ReviewViewModel(
      reviews,
      content,
      activity,
      playback: const Playback(mirrored: true),
    )..setSpeed(PlaybackSpeed.half);
    await at(viewModel.load);
    viewModel
      ..setSpeed(PlaybackSpeed.half)
      ..setLooping(looping: false)
      ..setMirrored(mirrored: false);

    expect(
      (viewModel.state as ReviewInProgress).playback,
      const Playback(speed: PlaybackSpeed.half, looping: false),
    );
  });

  test('stays quiet when closed while loading', () async {
    final hold = content.hold = Completer<void>();
    final viewModel = build();
    final loading = at(viewModel.load);
    await viewModel.close();
    hold.complete();
    await loading;

    expect(viewModel.state, const ReviewLoading());
  });
}
