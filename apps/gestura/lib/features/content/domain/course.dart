import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/lesson.dart';
import 'package:gestura/features/content/domain/localized_text.dart';
import 'package:meta/meta.dart';

enum CefrLevel {
  a1,
  a2;

  factory fromName(String name) =>
      values.firstWhere((level) => level.name == name);
}

@immutable
final class CourseUnit {
  const new({required this.index, required this.title});

  final int index;
  final LocalizedText title;
}

@immutable
final class Course {
  const new({
    required this.id,
    required this.level,
    required this.title,
    required this.units,
    required this.lessons,
  });

  final CourseId id;
  final CefrLevel level;
  final LocalizedText title;
  final List<CourseUnit> units;
  final List<Lesson> lessons;

  List<Lesson> lessonsIn(int unitIndex) =>
      lessons.where((lesson) => lesson.unitIndex == unitIndex).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Course && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
