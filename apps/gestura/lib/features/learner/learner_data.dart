import 'package:gestura/features/activity/domain/activity_repository.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura/features/review/domain/review_repository.dart';
import 'package:gestura/features/saved/domain/saved_signs_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
final class LearnerData {
  const new(this._progress, this._reviews, this._activity, this._saved);

  final ProgressRepository _progress;
  final ReviewRepository _reviews;
  final ActivityRepository _activity;
  final SavedSignsRepository _saved;

  Future<Result<void>> clear() async {
    for (final clear in [
      _progress.clear,
      _reviews.clear,
      _activity.clear,
      _saved.clear,
    ]) {
      final result = await clear();
      if (result case Err()) return result;
    }
    return const Ok(null);
  }
}
