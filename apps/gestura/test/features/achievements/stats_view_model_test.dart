import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/achievements/presentation/view_models/stats_state.dart';
import 'package:gestura/features/achievements/presentation/view_models/stats_view_model.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_activity_repository.dart';
import '../../helpers/fake_progress_repository.dart';
import '../../helpers/fake_review_repository.dart';

void main() {
  test('follows progress, cards and activity together', () async {
    final progress = FakeProgressRepository([completed('demo-a1-1')]);
    final reviews = FakeReviewRepository();
    final viewModel = StatsViewModel(
      progress,
      reviews,
      FakeActivityRepository(),
    );
    expect(viewModel.state, const StatsLoading());
    expect(const StatsLoading().props, isEmpty);

    await withClock(Clock.fixed(reviewNow), () async {
      viewModel.start();
      await pumpEventQueue();
      expect((viewModel.state as StatsReady).stats.lessons, 1);

      await reviews.addSigns({const SignId('hello')});
      await pumpEventQueue();
    });

    expect((viewModel.state as StatsReady).stats.signs, 1);
    await viewModel.close();
  });

  test('reports a failure and starts again', () async {
    final reviews = FakeReviewRepository()
      ..failure = const StorageFullFailure();
    final viewModel = StatsViewModel(
      FakeProgressRepository(),
      reviews,
      FakeActivityRepository(),
    )..start();
    await pumpEventQueue();
    expect(viewModel.state, const StatsFailed(StorageFullFailure()));

    reviews.failure = null;
    viewModel.start();
    expect(viewModel.state, const StatsLoading());
    await pumpEventQueue();
    expect(viewModel.state, isA<StatsReady>());
    await viewModel.close();
  });
}
