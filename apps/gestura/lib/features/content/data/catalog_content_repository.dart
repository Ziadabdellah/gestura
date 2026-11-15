import 'package:gestura/features/content/data/sign_search.dart' as sign_search;
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura_core/gestura_core.dart';

abstract base class CatalogContentRepository implements ContentRepository {
  Future<ContentCatalog>? _catalog;

  Future<ContentCatalog> loadCatalog();

  Failure failureOf(Object error) => switch (error) {
    final Failure failure => failure,
    _ => UnexpectedFailure(error),
  };

  @override
  Future<Result<SignLanguagePack>> pack() => _query((catalog) => catalog.pack);

  @override
  Future<Result<List<Course>>> courses() =>
      _query((catalog) => catalog.courses);

  @override
  Future<Result<Lesson>> lesson(LessonId id) =>
      _find((catalog) => catalog.lesson(id));

  @override
  Future<Result<Sign>> sign(SignId id) => _find((catalog) => catalog.sign(id));

  @override
  Future<Result<List<Sign>>> signs(Set<SignId> ids) => _query(
    (catalog) => [
      for (final sign in catalog.signs)
        if (ids.contains(sign.id)) sign,
    ],
  );

  @override
  Future<Result<List<SignCategory>>> categories() =>
      _query((catalog) => catalog.categories);

  @override
  Future<Result<List<Sign>>> searchSigns(String query) =>
      _query((catalog) => sign_search.searchSigns(catalog.signs, query));

  @override
  Future<Result<List<Sign>>> alphabet() =>
      _query((catalog) => catalog.alphabet);

  Future<Result<T>> _query<T>(T Function(ContentCatalog catalog) select) =>
      Result.guard(
        () async => select(await _cachedCatalog()),
        onError: (error, stackTrace) => failureOf(error),
      );

  Future<Result<T>> _find<T extends Object>(
    T? Function(ContentCatalog catalog) select,
  ) => _query(select).then(
    (result) => switch (result) {
      Ok(:final T value) => Ok(value),
      Ok() => Err<T>(const NotFoundFailure()),
      Err(:final failure) => Err<T>(failure),
    },
  );

  Future<ContentCatalog> _cachedCatalog() async {
    try {
      return await (_catalog ??= loadCatalog());
    } on Object {
      _catalog = null;
      rethrow;
    }
  }
}
