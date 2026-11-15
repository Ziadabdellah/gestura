import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura_core/gestura_core.dart';

abstract interface class ReviewRepository {
  Stream<Result<List<ReviewCard>>> watchAll();

  Future<Result<List<ReviewCard>>> readAll();

  Future<Result<void>> addSigns(Set<SignId> signs);

  Future<Result<void>> save(ReviewCard card);

  Future<Result<void>> merge(Iterable<ReviewCard> incoming);

  Future<Result<void>> clear();
}
