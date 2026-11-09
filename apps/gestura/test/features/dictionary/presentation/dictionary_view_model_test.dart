import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_state.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_view_model.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_content_repository.dart';

class _MockContentRepository extends Mock implements ContentRepository;

void main() {
  late _MockContentRepository content;
  final signs = demoCatalog.signs;

  setUp(() {
    content = _MockContentRepository();
    when(() => content.searchSigns('')).thenAnswer((_) async => Ok(signs));
  });

  test('starts loading', () {
    expect(DictionaryViewModel(content).state, const DictionaryLoading());
  });

  blocTest<DictionaryViewModel, DictionaryState>(
    'lists every sign',
    build: () => DictionaryViewModel(content),
    act: (viewModel) => viewModel.load(),
    expect: () => [DictionaryLoaded(signs)],
    verify: (_) => verify(() => content.searchSigns('')).called(1),
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'reports signs that fail to load',
    setUp: () =>
        when(() => content.searchSigns(''))
            .thenAnswer((_) async => const Err(UnexpectedFailure('broken'))),
    build: () => DictionaryViewModel(content),
    act: (viewModel) => viewModel.load(),
    expect: () => [const DictionaryFailed(UnexpectedFailure('broken'))],
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'shows loading again on retry',
    build: () => DictionaryViewModel(content),
    seed: () => const DictionaryFailed(NetworkFailure()),
    act: (viewModel) => viewModel.load(),
    expect: () => [const DictionaryLoading(), DictionaryLoaded(signs)],
  );

  test('knows when the list holds placeholder signs', () {
    final real = [
      for (final sign in signs.take(2))
        Sign(
          id: sign.id,
          gloss: sign.gloss,
          meaning: sign.meaning,
          category: sign.category,
          media: sign.media,
          source: const ContentSource(name: 'Archive', license: 'CC BY 4.0'),
        ),
    ];

    expect(DictionaryLoaded(signs).hasPlaceholders, isTrue);
    expect(DictionaryLoaded(real).hasPlaceholders, isFalse);
    expect(const DictionaryLoaded([]).hasPlaceholders, isFalse);
  });

  test('stays quiet when closed before the signs arrive', () async {
    final arrival = Completer<Result<List<Sign>>>();
    when(() => content.searchSigns('')).thenAnswer((_) => arrival.future);
    final viewModel = DictionaryViewModel(content);

    final loading = viewModel.load();
    await viewModel.close();
    arrival.complete(Ok(signs));
    await loading;

    expect(viewModel.state, const DictionaryLoading());
  });
}
