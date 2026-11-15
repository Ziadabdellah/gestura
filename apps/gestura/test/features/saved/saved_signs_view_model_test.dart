import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/saved/presentation/view_models/saved_signs_state.dart';
import 'package:gestura/features/saved/presentation/view_models/saved_signs_view_model.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_content_repository.dart';
import '../../helpers/fake_saved_signs_repository.dart';

void main() {
  late FakeContentRepository content;
  late FakeSavedSignsRepository saved;

  setUp(() {
    content = FakeContentRepository();
    saved = FakeSavedSignsRepository([
      const SignId('yes'),
      const SignId('gone'),
      const SignId('hello'),
    ]);
  });

  test('lists saved signs in order and follows changes', () async {
    final viewModel = SavedSignsViewModel(content, saved);
    expect(viewModel.state, const SavedSignsLoading());
    viewModel.start();
    await pumpEventQueue();

    expect(
      (viewModel.state as SavedSignsLoaded).signs.map((sign) => sign.gloss),
      ['YES', 'HELLO'],
    );

    await saved.setSaved(const SignId('yes'), saved: false);
    await pumpEventQueue();

    expect(
      (viewModel.state as SavedSignsLoaded).signs.map((sign) => sign.gloss),
      ['HELLO'],
    );
    await viewModel.close();
  });

  test('reports saved signs that cannot be read and starts again', () async {
    saved.failure = const StorageFullFailure();
    final viewModel = SavedSignsViewModel(content, saved)..start();
    await pumpEventQueue();

    expect(viewModel.state, const SavedSignsFailed(StorageFullFailure()));

    saved.failure = null;
    viewModel.start();
    expect(viewModel.state, const SavedSignsLoading());
    await pumpEventQueue();
    expect(viewModel.state, isA<SavedSignsLoaded>());
    await viewModel.close();
  });

  test('reports signs that cannot be loaded', () async {
    content.failure = const NetworkFailure();
    final viewModel = SavedSignsViewModel(content, saved)..start();
    await pumpEventQueue();

    expect(viewModel.state, const SavedSignsFailed(NetworkFailure()));
    await viewModel.close();
  });

  test('stays quiet when closed while loading', () async {
    final hold = content.hold = Completer<void>();
    final viewModel = SavedSignsViewModel(content, saved)..start();
    await pumpEventQueue();
    await viewModel.close();
    hold.complete();
    await pumpEventQueue();

    expect(viewModel.state, const SavedSignsLoading());
  });
}
