import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/learn/presentation/view_models/learn_state.dart';
import 'package:gestura/features/learn/presentation/view_models/learn_view_model.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_content_repository.dart';

class _MockContentRepository extends Mock implements ContentRepository;

void main() {
  late _MockContentRepository content;
  final pack = demoCatalog.pack;
  final course = demoCatalog.courses.single;

  setUp(() {
    content = _MockContentRepository();
    when(() => content.pack()).thenAnswer((_) async => Ok(pack));
    when(() => content.courses()).thenAnswer((_) async => Ok([course]));
  });

  test('starts loading', () {
    expect(LearnViewModel(content).state, const LearnLoading());
  });

  blocTest<LearnViewModel, LearnState>(
    'shows the first course of the pack',
    build: () => LearnViewModel(content),
    act: (viewModel) => viewModel.load(),
    expect: () => [LearnLoaded(pack: pack, course: course)],
  );

  blocTest<LearnViewModel, LearnState>(
    'reports a pack without courses as not found',
    setUp: () =>
        when(() => content.courses())
            .thenAnswer((_) async => const Ok(<Course>[])),
    build: () => LearnViewModel(content),
    act: (viewModel) => viewModel.load(),
    expect: () => [const LearnFailed(NotFoundFailure())],
  );

  blocTest<LearnViewModel, LearnState>(
    'reports a pack that fails to load',
    setUp: () =>
        when(() => content.pack())
            .thenAnswer((_) async => const Err(StorageFullFailure())),
    build: () => LearnViewModel(content),
    act: (viewModel) => viewModel.load(),
    expect: () => [const LearnFailed(StorageFullFailure())],
  );

  blocTest<LearnViewModel, LearnState>(
    'reports courses that fail to load',
    setUp: () =>
        when(() => content.courses())
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: () => LearnViewModel(content),
    act: (viewModel) => viewModel.load(),
    expect: () => [const LearnFailed(NetworkFailure())],
  );

  blocTest<LearnViewModel, LearnState>(
    'shows loading again on retry',
    build: () => LearnViewModel(content),
    seed: () => const LearnFailed(NetworkFailure()),
    act: (viewModel) => viewModel.load(),
    expect: () => [
      const LearnLoading(),
      LearnLoaded(pack: pack, course: course),
    ],
  );

  test('stays quiet when closed before the content arrives', () async {
    final arrival = Completer<Result<List<Course>>>();
    when(() => content.courses()).thenAnswer((_) => arrival.future);
    final viewModel = LearnViewModel(content);

    final loading = viewModel.load();
    await viewModel.close();
    arrival.complete(Ok([course]));
    await loading;

    expect(viewModel.state, const LearnLoading());
  });
}
