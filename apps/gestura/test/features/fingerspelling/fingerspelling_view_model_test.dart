import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/fingerspelling/presentation/view_models/fingerspelling_state.dart';
import 'package:gestura/features/fingerspelling/presentation/view_models/fingerspelling_view_model.dart';
import 'package:gestura/features/lesson/domain/playback.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_content_repository.dart';

void main() {
  late FakeContentRepository content;

  setUp(() => content = FakeContentRepository());

  test('loads the alphabet and starts on the first letter', () async {
    final viewModel = FingerspellingViewModel(content);
    expect(viewModel.state, const FingerspellingLoading());
    expect(const FingerspellingLoading().props, isEmpty);

    await viewModel.load();

    final ready = viewModel.state as FingerspellingReady;
    expect(ready.letters, hasLength(26));
    expect(ready.selected.gloss, 'A');
    expect(ready.selected.category, alphabetCategory);
  });

  test('spells a word with the letters it knows', () async {
    final viewModel = FingerspellingViewModel(content)
      ..spell('ignored before loading')
      ..select(demoCatalog.alphabet.last);
    await viewModel.load();
    var ready = (viewModel..spell('Hi 2u!')).state as FingerspellingReady;
    expect(ready.word.map((letter) => letter.gloss), ['H', 'I', 'U']);
    expect(ready.selected.gloss, 'H');

    viewModel.select(ready.word.last);
    expect((viewModel.state as FingerspellingReady).selected.gloss, 'U');

    viewModel.spell('');
    ready = viewModel.state as FingerspellingReady;
    expect(ready.word, isEmpty);
    expect(ready.selected.gloss, 'U');
  });

  test('changes playback', () async {
    final viewModel = FingerspellingViewModel(
      content,
      playback: const Playback(mirrored: true),
    )..setSpeed(PlaybackSpeed.half);
    await viewModel.load();
    viewModel
      ..setLooping(looping: false)
      ..setMirrored(mirrored: false);

    expect(
      (viewModel.state as FingerspellingReady).playback,
      const Playback(speed: PlaybackSpeed.half, looping: false),
    );
  });

  test('says when a pack has no letters yet', () async {
    final empty = ContentCatalog(
      pack: demoCatalog.pack,
      categories: demoCatalog.categories,
      courses: demoCatalog.courses,
      signs: demoCatalog.signs,
    );
    final viewModel = FingerspellingViewModel(
      FakeContentRepository(catalog: empty),
    );
    await viewModel.load();

    expect(viewModel.state, const FingerspellingEmpty());
  });

  test('reports a failure, loads again and stays quiet when closed', () async {
    content.failure = const NetworkFailure();
    final viewModel = FingerspellingViewModel(content);
    await viewModel.load();
    expect(viewModel.state, const FingerspellingFailed(NetworkFailure()));

    content.failure = null;
    final hold = content.hold = Completer<void>();
    final loading = viewModel.load();
    expect(viewModel.state, const FingerspellingLoading());
    await viewModel.close();
    hold.complete();
    await loading;
    expect(viewModel.state, const FingerspellingLoading());
  });
}
