import 'dart:async';
import 'dart:io';

import 'package:gestura/features/content/data/bundled_content_repository.dart';
import 'package:gestura/features/content/data/content_catalog_parser.dart';
import 'package:gestura/features/content/data/sign_search.dart' as sign_search;
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura_core/gestura_core.dart';

final ContentCatalog demoCatalog = parseContentCatalog(
  File(BundledContentRepository.catalogAsset).readAsStringSync(),
);

class FakeContentRepository implements ContentRepository {
  new({ContentCatalog? catalog}) : catalog = catalog ?? demoCatalog;

  final ContentCatalog catalog;
  Failure? failure;
  Completer<void>? hold;
  int requests = 0;

  Future<Result<T>> _answer<T extends Object>(T? Function() select) async {
    requests++;
    if (hold case final Completer<void> hold) await hold.future;
    if (failure case final Failure failure) return Err(failure);
    return switch (select()) {
      final T value => Ok(value),
      null => Err<T>(const NotFoundFailure()),
    };
  }

  @override
  Future<Result<SignLanguagePack>> pack() => _answer(() => catalog.pack);

  @override
  Future<Result<List<Course>>> courses() => _answer(() => catalog.courses);

  @override
  Future<Result<Lesson>> lesson(LessonId id) =>
      _answer(() => catalog.lesson(id));

  @override
  Future<Result<Sign>> sign(SignId id) => _answer(() => catalog.sign(id));

  @override
  Future<Result<List<Sign>>> signs(Set<SignId> ids) => _answer(
    () => [
      for (final sign in catalog.signs)
        if (ids.contains(sign.id)) sign,
    ],
  );

  @override
  Future<Result<List<SignCategory>>> categories() =>
      _answer(() => catalog.categories);

  @override
  Future<Result<List<Sign>>> searchSigns(String query) =>
      _answer(() => sign_search.searchSigns(catalog.signs, query));
}
