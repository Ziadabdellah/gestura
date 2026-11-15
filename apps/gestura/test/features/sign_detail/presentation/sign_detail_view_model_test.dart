import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura/features/sign_detail/presentation/view_models/sign_detail_state.dart';
import 'package:gestura/features/sign_detail/presentation/view_models/sign_detail_view_model.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_content_repository.dart';
import '../../../helpers/fake_saved_signs_repository.dart';

class _MockContentRepository extends Mock implements ContentRepository;

const SignId _hello = SignId('hello');

Sign _sign(String id) => demoCatalog.sign(SignId(id))!;

SignDetailLoaded _helloLoaded([Playback playback = const Playback()]) =>
    SignDetailLoaded(
      sign: _sign('hello'),
      category: demoCatalog.categories.first,
      related: [
        for (final id in ['no', 'please', 'sorry', 'thank-you', 'yes'])
          _sign(id),
      ],
      playback: playback,
    );

void main() {
  late FakeContentRepository content;
  late FakeSavedSignsRepository saved;

  setUp(() {
    content = FakeContentRepository();
    saved = FakeSavedSignsRepository();
  });

  test('starts loading', () {
    expect(
      SignDetailViewModel(content, saved).state,
      const SignDetailLoading(),
    );
  });

  blocTest<SignDetailViewModel, SignDetailState>(
    'shows the sign with its category and the other signs in it',
    build: () => SignDetailViewModel(content, saved),
    act: (viewModel) => viewModel.load(_hello),
    expect: () => [_helloLoaded()],
  );

  blocTest<SignDetailViewModel, SignDetailState>(
    'starts with the playback it was given',
    build: () => SignDetailViewModel(
      content,
      saved,
      playback: const Playback(mirrored: true),
    ),
    act: (viewModel) => viewModel.load(_hello),
    expect: () => [_helloLoaded(const Playback(mirrored: true))],
  );

  blocTest<SignDetailViewModel, SignDetailState>(
    'reports a sign that does not exist',
    build: () => SignDetailViewModel(content, saved),
    act: (viewModel) => viewModel.load(const SignId('missing')),
    expect: () => [const SignDetailFailed(NotFoundFailure())],
  );

  blocTest<SignDetailViewModel, SignDetailState>(
    'shows loading again on retry',
    build: () => SignDetailViewModel(content, saved),
    seed: () => const SignDetailFailed(NetworkFailure()),
    act: (viewModel) => viewModel.load(_hello),
    expect: () => [const SignDetailLoading(), _helloLoaded()],
  );

  group('with a repository that fails in one place', () {
    late _MockContentRepository mock;

    setUp(() {
      mock = _MockContentRepository();
      when(() => mock.sign(_hello)).thenAnswer((_) async => Ok(_sign('hello')));
      when(mock.categories).thenAnswer((_) async => Ok(demoCatalog.categories));
      when(() => mock.searchSigns(''))
          .thenAnswer((_) async => Ok(demoCatalog.signs));
    });

    blocTest<SignDetailViewModel, SignDetailState>(
      'reports categories that fail to load',
      setUp: () =>
          when(mock.categories)
              .thenAnswer((_) async => const Err(NetworkFailure())),
      build: () => SignDetailViewModel(mock, saved),
      act: (viewModel) => viewModel.load(_hello),
      expect: () => [const SignDetailFailed(NetworkFailure())],
    );

    blocTest<SignDetailViewModel, SignDetailState>(
      'reports related signs that fail to load',
      setUp: () =>
          when(() => mock.searchSigns(''))
              .thenAnswer((_) async => const Err(StorageFullFailure())),
      build: () => SignDetailViewModel(mock, saved),
      act: (viewModel) => viewModel.load(_hello),
      expect: () => [const SignDetailFailed(StorageFullFailure())],
    );

    blocTest<SignDetailViewModel, SignDetailState>(
      'still shows a sign whose category is unknown',
      setUp: () => when(mock.categories).thenAnswer((_) async => const Ok([])),
      build: () => SignDetailViewModel(mock, saved),
      act: (viewModel) => viewModel.load(_hello),
      verify: (viewModel) {
        final state = viewModel.state as SignDetailLoaded;
        expect(state.category, isNull);
        expect(state.related, isNotEmpty);
      },
    );
  });

  blocTest<SignDetailViewModel, SignDetailState>(
    'changes speed, loop and mirror',
    build: () => SignDetailViewModel(content, saved),
    act: (viewModel) async {
      await viewModel.load(_hello);
      viewModel
        ..setSpeed(PlaybackSpeed.half)
        ..setLooping(looping: false)
        ..setMirrored(mirrored: true);
    },
    expect: () => [
      _helloLoaded(),
      _helloLoaded(const Playback(speed: PlaybackSpeed.half)),
      _helloLoaded(const Playback(speed: PlaybackSpeed.half, looping: false)),
      _helloLoaded(
        const Playback(
          speed: PlaybackSpeed.half,
          looping: false,
          mirrored: true,
        ),
      ),
    ],
  );

  blocTest<SignDetailViewModel, SignDetailState>(
    'remembers playback changed before the sign arrives',
    build: () => SignDetailViewModel(content, saved),
    act: (viewModel) async {
      viewModel.setMirrored(mirrored: true);
      await viewModel.load(_hello);
    },
    expect: () => [_helloLoaded(const Playback(mirrored: true))],
  );

  test('stays quiet when closed before the sign arrives', () async {
    final hold = content.hold = Completer<void>();
    final viewModel = SignDetailViewModel(content, saved);

    final loading = viewModel.load(_hello);
    await viewModel.close();
    hold.complete();
    await loading;

    expect(viewModel.state, const SignDetailLoading());
  });

  test('saves and unsaves the sign it shows', () async {
    final viewModel = SignDetailViewModel(content, saved);
    expect(await viewModel.toggleSaved(), const Ok<void>(null));
    await viewModel.load(_hello);

    expect(await viewModel.toggleSaved(), const Ok<void>(null));
    expect((viewModel.state as SignDetailLoaded).saved, isTrue);
    expect(saved.saved, [_hello]);

    expect(await viewModel.toggleSaved(), const Ok<void>(null));
    expect((viewModel.state as SignDetailLoaded).saved, isFalse);
    expect(saved.saved, isEmpty);
    await viewModel.close();
  });

  test('starts saved and keeps the heart when saving fails', () async {
    saved = FakeSavedSignsRepository([_hello]);
    final viewModel = SignDetailViewModel(content, saved);
    await viewModel.load(_hello);
    expect((viewModel.state as SignDetailLoaded).saved, isTrue);

    saved.failure = const StorageFullFailure();
    expect(
      await viewModel.toggleSaved(),
      const Err<void>(StorageFullFailure()),
    );
    expect((viewModel.state as SignDetailLoaded).saved, isTrue);
    await viewModel.close();
  });

  test('shows the sign when saved signs cannot be read', () async {
    saved.failure = const StorageFullFailure();
    final viewModel = SignDetailViewModel(content, saved);
    await viewModel.load(_hello);

    expect((viewModel.state as SignDetailLoaded).saved, isFalse);
    await viewModel.close();
  });
}
