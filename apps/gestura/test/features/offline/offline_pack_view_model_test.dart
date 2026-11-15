import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/offline/offline_pack_state.dart';
import 'package:gestura/features/offline/offline_pack_view_model.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../helpers/fake_content_repository.dart';
import '../../helpers/fake_media_cache.dart';

Sign _remote(Sign sign) => Sign(
  id: sign.id,
  gloss: sign.gloss,
  meaning: sign.meaning,
  category: sign.category,
  media: SignMedia(
    video: RemoteMedia(Uri.parse('https://c.web.app/m/${sign.id.value}.mp4')),
    thumbnail: RemoteMedia(
      Uri.parse('https://c.web.app/m/${sign.id.value}.webp'),
    ),
    duration: sign.media.duration,
  ),
  source: sign.source,
);

class _RemoteContent extends FakeContentRepository {
  @override
  Future<Result<List<Sign>>> searchSigns(String query) async =>
      switch (await super.searchSigns(query)) {
        Ok(:final value) => Ok([
          for (final sign in value.take(2)) _remote(sign),
        ]),
        Err(:final failure) => Err(failure),
      };
}

void main() {
  late _RemoteContent content;
  late FakeMediaCache cache;

  setUp(() {
    content = _RemoteContent();
    cache = FakeMediaCache('assets');
  });

  test('downloads every published file and reports progress', () async {
    final viewModel = OfflinePackViewModel(content, cache);
    expect(viewModel.state, const OfflinePackChecking());
    await viewModel.load();
    expect(viewModel.state, const OfflinePackIdle(files: 4, saved: 0));

    final states = <OfflinePackState>[];
    final subscription = viewModel.stream.listen(states.add);
    await viewModel.download();
    await pumpEventQueue();
    await subscription.cancel();

    expect(states.first, const OfflinePackDownloading(done: 0, total: 4));
    expect((states[2] as OfflinePackDownloading).fraction, 0.5);
    expect(states.last, const OfflinePackIdle(files: 4, saved: 4));
    expect((states.last as OfflinePackIdle).complete, isTrue);
    expect(cache.requested.toSet(), hasLength(4));

    await viewModel.download();
    expect(viewModel.state, const OfflinePackIdle(files: 4, saved: 4));
  });

  test('keeps what it saved and offers to try the rest', () async {
    final first = (await content.searchSigns('')).valueOrNull!.first;
    cache.missing.add('${first.id.value}.mp4');
    final viewModel = OfflinePackViewModel(content, cache);
    await viewModel.load();

    await viewModel.download();

    expect(viewModel.state, const OfflinePackFailed(saved: 3, files: 4));
  });

  test('hides itself for bundled content or when content fails', () async {
    final bundled = OfflinePackViewModel(FakeContentRepository(), cache);
    await bundled.load();
    expect(bundled.state, const OfflinePackUnavailable());

    content.failure = const NetworkFailure();
    final failing = OfflinePackViewModel(content, cache);
    await failing.load();
    expect(failing.state, const OfflinePackUnavailable());
    expect(const OfflinePackChecking().props, isEmpty);
    expect(const OfflinePackDownloading(done: 0, total: 0).fraction, 1);
  });

  test(
    'ignores a download before loading and stays quiet when closed',
    () async {
      final viewModel = OfflinePackViewModel(content, cache);
      await viewModel.download();
      expect(viewModel.state, const OfflinePackChecking());

      final hold = cache.hold = Completer<void>();
      await viewModel.load();
      final downloading = viewModel.download();
      await pumpEventQueue();
      await viewModel.close();
      hold.complete();
      await downloading;

      expect(viewModel.state, const OfflinePackDownloading(done: 0, total: 4));

      final closing = OfflinePackViewModel(content, cache);
      final loading = closing.load();
      await closing.close();
      await loading;
      expect(closing.state, const OfflinePackChecking());
    },
  );
}
