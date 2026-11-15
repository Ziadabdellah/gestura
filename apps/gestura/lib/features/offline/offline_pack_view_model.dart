import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/core/media/media_cache.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/offline/offline_pack_state.dart';
import 'package:gestura_core/gestura_core.dart';

class OfflinePackViewModel extends Cubit<OfflinePackState> {
  new(this._content, this._cache) : super(const OfflinePackChecking());

  final ContentRepository _content;
  final MediaCache _cache;
  List<Uri> _files = const [];

  Future<void> load() async {
    final signs = await _content.searchSigns('');
    _files = switch (signs) {
      Ok(:final value) => [
        for (final sign in value)
          for (final media in [sign.media.thumbnail, sign.media.video])
            if (media case RemoteMedia(:final uri)) uri,
      ],
      Err() => const [],
    };
    if (isClosed) return;
    if (_files.isEmpty) return emit(const OfflinePackUnavailable());
    emit(OfflinePackIdle(files: _files.length, saved: await _saved()));
  }

  Future<int> _saved() async {
    var saved = 0;
    for (final file in _files) {
      if (await _cache.has(file)) saved++;
    }
    return saved;
  }

  Future<void> download() async {
    if (state is! OfflinePackIdle && state is! OfflinePackFailed) return;
    final total = _files.length;
    var done = 0;
    var failed = false;
    emit(OfflinePackDownloading(done: done, total: total));
    for (final file in _files) {
      if (!await _cache.has(file)) {
        try {
          await _cache.file(file);
        } on Object {
          failed = true;
        }
      }
      done++;
      if (isClosed) return;
      emit(OfflinePackDownloading(done: done, total: total));
    }
    final saved = await _saved();
    if (isClosed) return;
    emit(
      failed
          ? OfflinePackFailed(saved: saved, files: total)
          : OfflinePackIdle(files: total, saved: saved),
    );
  }
}
