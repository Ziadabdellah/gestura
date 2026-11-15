import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/data/sign_search.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/dictionary/domain/sign_sections.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_state.dart';
import 'package:gestura/features/dictionary/presentation/view_models/dictionary_view_model.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../../helpers/fake_content_repository.dart';

const Duration _afterDebounce = Duration(milliseconds: 300);
const CategoryId _family = CategoryId('family');

List<Sign> _sorted(Iterable<Sign> signs) =>
    [...signs]..sort((a, b) => a.gloss.compareTo(b.gloss));

Sign _sign(String id) => demoCatalog.sign(SignId(id))!;

DictionaryLoaded _loaded({
  String query = '',
  CategoryId? category,
  List<Sign>? results,
}) => DictionaryLoaded(
  categories: demoCatalog.categories,
  results:
      results ??
      _sorted(
        demoCatalog.signs.where(
          (sign) => category == null || sign.category == category,
        ),
      ),
  query: query,
  category: category,
);

void main() {
  late FakeContentRepository content;

  setUp(() => content = FakeContentRepository());

  test('starts loading and waits a quarter of a second between keys', () {
    expect(DictionaryViewModel(content).state, const DictionaryLoading());
    expect(
      DictionaryViewModel.searchDebounce,
      const Duration(milliseconds: 250),
    );
  });

  blocTest<DictionaryViewModel, DictionaryState>(
    'lists every sign with the categories',
    build: () => DictionaryViewModel(content),
    act: (viewModel) => viewModel.load(),
    expect: () => [_loaded()],
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'reports content that fails to load',
    setUp: () => content.failure = const UnexpectedFailure('broken'),
    build: () => DictionaryViewModel(content),
    act: (viewModel) => viewModel.load(),
    expect: () => [const DictionaryFailed(UnexpectedFailure('broken'))],
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'shows loading again on retry',
    build: () => DictionaryViewModel(content),
    seed: () => const DictionaryFailed(NetworkFailure()),
    act: (viewModel) => viewModel.load(),
    expect: () => [const DictionaryLoading(), _loaded()],
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'searches once the learner stops typing',
    build: () => DictionaryViewModel(content),
    act: (viewModel) async {
      await viewModel.load();
      viewModel
        ..search('m')
        ..search('mo')
        ..search('mot');
    },
    wait: _afterDebounce,
    expect: () => [
      _loaded(),
      _loaded(query: 'mot', results: [_sign('mother')]),
    ],
    verify: (_) => expect(content.requests, 3),
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'ignores a search that did not change',
    build: () => DictionaryViewModel(content),
    act: (viewModel) async {
      await viewModel.load();
      viewModel.search('');
    },
    wait: _afterDebounce,
    expect: () => [_loaded()],
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'loads everything again when a search follows a failure',
    build: () => DictionaryViewModel(content),
    seed: () => const DictionaryFailed(NetworkFailure()),
    act: (viewModel) => viewModel.search('sis'),
    wait: _afterDebounce,
    expect: () => [
      const DictionaryLoading(),
      _loaded(query: 'sis', results: [_sign('sister')]),
    ],
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'clears the search right away and drops the waiting one',
    build: () => DictionaryViewModel(content),
    act: (viewModel) async {
      await viewModel.load();
      viewModel.search('fam');
      await viewModel.clearSearch();
    },
    wait: _afterDebounce,
    expect: () => [_loaded()],
    verify: (_) => expect(content.requests, 3),
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'filters by category and shows everything again',
    build: () => DictionaryViewModel(content),
    act: (viewModel) async {
      await viewModel.load();
      await viewModel.selectCategory(_family);
      await viewModel.selectCategory(_family);
      await viewModel.selectCategory(null);
    },
    expect: () => [_loaded(), _loaded(category: _family), _loaded()],
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'combines the search with the category',
    build: () => DictionaryViewModel(content),
    act: (viewModel) async {
      await viewModel.load();
      await viewModel.selectCategory(_family);
      viewModel.search('s');
    },
    wait: _afterDebounce,
    expect: () => [
      _loaded(),
      _loaded(category: _family),
      _loaded(
        query: 's',
        category: _family,
        results: [
          for (final sign in searchSigns(demoCatalog.signs, 's'))
            if (sign.category == _family) sign,
        ],
      ),
    ],
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'keeps only the answer to the latest request',
    build: () => DictionaryViewModel(content),
    act: (viewModel) async {
      await viewModel.load();
      final hold = content.hold = Completer<void>();
      final first = viewModel.selectCategory(_family);
      final second = viewModel.selectCategory(const CategoryId('greetings'));
      hold.complete();
      await (first, second).wait;
    },
    expect: () => [_loaded(), _loaded(category: const CategoryId('greetings'))],
  );

  blocTest<DictionaryViewModel, DictionaryState>(
    'reports a search that fails',
    build: () => DictionaryViewModel(content),
    act: (viewModel) async {
      await viewModel.load();
      content.failure = const NetworkFailure();
      await viewModel.selectCategory(_family);
    },
    expect: () => [_loaded(), const DictionaryFailed(NetworkFailure())],
  );

  test('stays quiet when closed before the signs arrive', () async {
    final hold = content.hold = Completer<void>();
    final viewModel = DictionaryViewModel(content);

    final loading = viewModel.load();
    await viewModel.close();
    hold.complete();
    await loading;

    expect(viewModel.state, const DictionaryLoading());
  });

  test('stays quiet when closed before a search answers', () async {
    final viewModel = DictionaryViewModel(content);
    await viewModel.load();
    final hold = content.hold = Completer<void>();

    final filtering = viewModel.selectCategory(_family);
    await viewModel.close();
    hold.complete();
    await filtering;

    expect(viewModel.state, _loaded());
  });

  test('drops a waiting search when closed', () async {
    final viewModel = DictionaryViewModel(content);
    await viewModel.load();

    viewModel.search('mother');
    await viewModel.close();
    await Future<void>.delayed(_afterDebounce);

    expect(content.requests, 2);
  });

  group('DictionaryLoaded', () {
    test('groups signs A to Z unless the learner is searching', () {
      expect(_loaded().isSearching, isFalse);
      expect(_loaded().sections, sectionsByInitial(demoCatalog.signs));
      expect(_loaded(query: '  ').isSearching, isFalse);

      final searching = _loaded(
        query: 'mo',
        results: [_sign('mother'), _sign('brother')],
      );

      expect(searching.isSearching, isTrue);
      expect(searching.sections, [
        SignSection(initial: '', signs: [_sign('mother'), _sign('brother')]),
      ]);
    });

    test('knows when the results hold placeholder signs', () {
      final real = Sign(
        id: const SignId('real'),
        gloss: 'REAL',
        meaning: _sign('hello').meaning,
        category: _family,
        media: _sign('hello').media,
        source: const ContentSource(name: 'Archive', license: 'CC BY 4.0'),
      );

      expect(_loaded().hasPlaceholders, isTrue);
      expect(_loaded(results: [real]).hasPlaceholders, isFalse);
      expect(_loaded(results: const []).hasPlaceholders, isFalse);
    });
  });
}
