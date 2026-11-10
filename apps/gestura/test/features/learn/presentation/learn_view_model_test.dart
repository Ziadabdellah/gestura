import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/learn/domain/course_outline.dart';
import 'package:gestura/features/learn/presentation/view_models/learn_state.dart';
import 'package:gestura/features/learn/presentation/view_models/learn_view_model.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/progress/domain/progress_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/fake_progress_repository.dart';

class _MockContentRepository extends Mock implements ContentRepository;

class _MockProgressRepository extends Mock implements ProgressRepository;

void main() {
  late _MockContentRepository content;
  late _MockProgressRepository progress;
  late StreamController<Result<ProgressByLesson>> updates;
  final pack = demoCatalog.pack;
  final course = demoCatalog.courses.single;
  final none = <LessonId, LessonProgress>{};
  final firstDone = {const LessonId('demo-a1-1'): completed('demo-a1-1')};

  LearnLoaded loaded(ProgressByLesson byLesson) => LearnLoaded(
    pack: pack,
    course: course,
    outline: CourseOutline.of(course, byLesson),
  );

  setUp(() {
    content = _MockContentRepository();
    progress = _MockProgressRepository();
    updates = StreamController.broadcast();
    when(() => content.pack()).thenAnswer((_) async => Ok(pack));
    when(() => content.courses()).thenAnswer((_) async => Ok([course]));
    when(() => progress.watchAll()).thenAnswer((_) => updates.stream);
  });

  tearDown(() => updates.close());

  LearnViewModel build() => LearnViewModel(content, progress);

  test('starts loading', () {
    expect(build().state, const LearnLoading());
  });

  blocTest<LearnViewModel, LearnState>(
    'shows the first course with the saved progress',
    build: build,
    act: (viewModel) async {
      await viewModel.load();
      updates.add(Ok(firstDone));
    },
    expect: () => [loaded(firstDone)],
  );

  blocTest<LearnViewModel, LearnState>(
    'follows progress as lessons are finished',
    build: build,
    act: (viewModel) async {
      await viewModel.load();
      updates
        ..add(Ok(none))
        ..add(Ok(firstDone));
    },
    expect: () => [loaded(none), loaded(firstDone)],
  );

  blocTest<LearnViewModel, LearnState>(
    'reports progress that cannot be read',
    build: build,
    act: (viewModel) async {
      await viewModel.load();
      updates.add(const Err(StorageFullFailure()));
    },
    expect: () => [const LearnFailed(StorageFullFailure())],
  );

  blocTest<LearnViewModel, LearnState>(
    'reports a pack without courses as not found',
    setUp: () =>
        when(() => content.courses())
            .thenAnswer((_) async => const Ok(<Course>[])),
    build: build,
    act: (viewModel) => viewModel.load(),
    expect: () => [const LearnFailed(NotFoundFailure())],
    verify: (_) => verifyNever(() => progress.watchAll()),
  );

  blocTest<LearnViewModel, LearnState>(
    'reports a pack that fails to load',
    setUp: () =>
        when(() => content.pack())
            .thenAnswer((_) async => const Err(StorageFullFailure())),
    build: build,
    act: (viewModel) => viewModel.load(),
    expect: () => [const LearnFailed(StorageFullFailure())],
  );

  blocTest<LearnViewModel, LearnState>(
    'reports courses that fail to load',
    setUp: () =>
        when(() => content.courses())
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: build,
    act: (viewModel) => viewModel.load(),
    expect: () => [const LearnFailed(NetworkFailure())],
  );

  blocTest<LearnViewModel, LearnState>(
    'shows loading again on retry and follows only the new progress',
    build: build,
    seed: () => const LearnFailed(NetworkFailure()),
    act: (viewModel) async {
      await viewModel.load();
      await viewModel.load();
      updates.add(Ok(firstDone));
    },
    expect: () => [const LearnLoading(), loaded(firstDone)],
    verify: (_) => verify(() => progress.watchAll()).called(2),
  );

  test('stops following progress when closed', () async {
    final viewModel = build();
    await viewModel.load();

    await viewModel.close();

    expect(updates.hasListener, isFalse);
  });

  test('stays quiet when closed before the content arrives', () async {
    final arrival = Completer<Result<List<Course>>>();
    when(() => content.courses()).thenAnswer((_) => arrival.future);
    final viewModel = build();

    final loading = viewModel.load();
    await viewModel.close();
    arrival.complete(Ok([course]));
    await loading;

    expect(viewModel.state, const LearnLoading());
    verifyNever(() => progress.watchAll());
  });
}
