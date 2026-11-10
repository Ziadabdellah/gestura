import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/learn/domain/course_outline.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/fake_progress_repository.dart';

final Course _course = demoCatalog.courses.single;

CourseOutline _outline(Map<String, int> scores) => CourseOutline.of(_course, {
  for (final MapEntry(:key, :value) in scores.entries)
    LessonId(key): completed(key, score: value),
});

List<Type> _statuses(CourseOutline outline) => [
  for (final unit in outline.units)
    for (final lesson in unit.lessons) lesson.status.runtimeType,
];

const Type _done = LessonCompleted;
const Type _next = LessonAvailable;
const Type _locked = LessonLocked;

void main() {
  test('opens only the first lesson at the start', () {
    final outline = _outline({});

    expect(_statuses(outline), [_next, _locked, _locked, _locked]);
    expect(outline.completed, 0);
    expect(outline.total, 4);
  });

  test('opens the lesson after each finished one, across units', () {
    expect(_statuses(_outline({'demo-a1-1': 80})), [
      _done,
      _next,
      _locked,
      _locked,
    ]);
    expect(_statuses(_outline({'demo-a1-1': 80, 'demo-a1-2': 70})), [
      _done,
      _done,
      _next,
      _locked,
    ]);
  });

  test('keeps a lesson finished on another device finished', () {
    expect(_statuses(_outline({'demo-a1-3': 90})), [
      _next,
      _locked,
      _done,
      _next,
    ]);
  });

  test('marks every lesson finished at the end', () {
    final outline = _outline({
      'demo-a1-1': 100,
      'demo-a1-2': 100,
      'demo-a1-3': 100,
      'demo-a1-4': 100,
    });

    expect(_statuses(outline), everyElement(_done));
    expect(outline.units.every((unit) => unit.isComplete), isTrue);
    expect(outline.units.any((unit) => unit.hasNextLesson), isFalse);
  });

  test('numbers lessons inside each unit and keeps the best score', () {
    final outline = _outline({'demo-a1-1': 85});
    final [greetings, family] = outline.units;

    expect(greetings.lessons.map((lesson) => lesson.number), [1, 2]);
    expect(family.lessons.map((lesson) => lesson.number), [1, 2]);
    expect(greetings.lessons.first.status, const LessonCompleted(85));
    expect(greetings.lessons.last.status, const LessonAvailable());
  });

  test('summarises each unit', () {
    final [greetings, family] = _outline({'demo-a1-1': 85}).units;

    expect(greetings.completed, 1);
    expect(greetings.isComplete, isFalse);
    expect(greetings.hasNextLesson, isTrue);
    expect(family.completed, 0);
    expect(family.hasNextLesson, isFalse);
    expect(
      UnitOutline(unit: family.unit, lessons: const []).isComplete,
      isFalse,
    );
  });

  test('compares outlines by value', () {
    expect(_outline({'demo-a1-1': 85}), _outline({'demo-a1-1': 85}));
    expect(_outline({'demo-a1-1': 85}), isNot(_outline({'demo-a1-1': 90})));
  });
}
