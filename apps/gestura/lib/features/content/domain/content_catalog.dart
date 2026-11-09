import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/localized_text.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:meta/meta.dart';

enum FingerspellingStyle {
  oneHanded,
  twoHanded;

  factory fromName(String name) =>
      values.firstWhere((style) => style.name == name);
}

@immutable
final class SignLanguagePack {
  const new({
    required this.code,
    required this.name,
    required this.fingerspelling,
    required this.isPlaceholder,
  });

  final String code;
  final LocalizedText name;
  final FingerspellingStyle fingerspelling;
  final bool isPlaceholder;
}

final class ContentCatalog {
  new({
    required this.pack,
    required this.categories,
    required this.courses,
    required this.signs,
  }) : _signsById = {for (final sign in signs) sign.id: sign},
       _lessonsById = {
         for (final course in courses)
           for (final lesson in course.lessons) lesson.id: lesson,
       };

  final SignLanguagePack pack;
  final List<SignCategory> categories;
  final List<Course> courses;
  final List<Sign> signs;
  final Map<SignId, Sign> _signsById;
  final Map<LessonId, Lesson> _lessonsById;

  Sign? sign(SignId id) => _signsById[id];

  Lesson? lesson(LessonId id) => _lessonsById[id];
}
