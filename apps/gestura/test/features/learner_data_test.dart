import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/learner/learner_data.dart';
import 'package:gestura_core/gestura_core.dart';

import '../helpers/fake_activity_repository.dart';
import '../helpers/fake_progress_repository.dart';
import '../helpers/fake_review_repository.dart';
import '../helpers/fake_saved_signs_repository.dart';

void main() {
  test(
    'clears progress, reviews, activity and saved signs on the device',
    () async {
      final progress = FakeProgressRepository([completed('demo-a1-1')]);
      final reviews = FakeReviewRepository();
      await reviews.addSigns({const SignId('hello')});
      final saved = FakeSavedSignsRepository([const SignId('hello')]);
      final data = LearnerData(
        progress,
        reviews,
        FakeActivityRepository(),
        saved,
      );

      expect(await data.clear(), const Ok<void>(null));
      expect(progress.stored, isEmpty);
      expect(reviews.stored, isEmpty);
      expect(saved.saved, isEmpty);
    },
  );

  test('stops at the first part that cannot be cleared', () async {
    final progress = FakeProgressRepository()
      ..saveFailure = const StorageFullFailure();
    final reviews = FakeReviewRepository();
    await reviews.addSigns({const SignId('hello')});

    final data = LearnerData(
      progress,
      reviews,
      FakeActivityRepository(),
      FakeSavedSignsRepository(),
    );

    expect(await data.clear(), const Err<void>(StorageFullFailure()));
    expect(reviews.stored, hasLength(1));
  });
}
