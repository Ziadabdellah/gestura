import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura_core/gestura_core.dart';

abstract interface class ContentRepository {
  Future<Result<SignLanguagePack>> pack();

  Future<Result<List<Course>>> courses();

  Future<Result<Lesson>> lesson(LessonId id);

  Future<Result<Sign>> sign(SignId id);

  Future<Result<List<Sign>>> signs(Set<SignId> ids);

  Future<Result<List<SignCategory>>> categories();

  Future<Result<List<Sign>>> searchSigns(String query);

  Future<Result<List<Sign>>> alphabet();
}
