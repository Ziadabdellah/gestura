import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class MediaCache {
  Future<File> file(Uri uri);

  Future<bool> has(Uri uri);
}

Future<Directory> mediaDirectory() async =>
    Directory('${(await getApplicationSupportDirectory()).path}/media');

@LazySingleton(as: MediaCache)
final class DiskMediaCache implements MediaCache {
  new({
    @ignoreParam this.directory = mediaDirectory,
    @ignoreParam this.maxBytes = defaultMaxBytes,
  });

  static const int defaultMaxBytes = 300 * 1024 * 1024;

  final Future<Directory> Function() directory;
  final int maxBytes;
  final Map<Uri, Future<File>> _pending = {};

  static String nameOf(Uri uri) =>
      '${uri.host}${uri.path}'.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');

  @override
  Future<bool> has(Uri uri) async =>
      File('${(await directory()).path}/${nameOf(uri)}').existsSync();

  @override
  Future<File> file(Uri uri) async {
    if (_pending[uri] case final Future<File> pending) return await pending;
    final download = _fetch(uri);
    _pending[uri] = download;
    try {
      return await download;
    } finally {
      unawaited(_pending.remove(uri));
    }
  }

  Future<File> _fetch(Uri uri) async {
    final folder = await directory();
    await folder.create(recursive: true);
    final target = File('${folder.path}/${nameOf(uri)}');
    if (target.existsSync()) {
      await target.setLastModified(DateTime.now());
      return target;
    }
    final partial = File('${target.path}.part');
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(uri)).close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      await response.pipe(partial.openWrite());
      await partial.rename(target.path);
    } finally {
      client.close();
    }
    await _evict(folder, keep: target);
    return target;
  }

  Future<void> _evict(Directory folder, {required File keep}) async {
    final files = [
      for (final entry in folder.listSync())
        if (entry is File && !entry.path.endsWith('.part')) entry,
    ]..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    var total = files.fold<int>(0, (sum, file) => sum + file.lengthSync());
    for (final file in files) {
      if (total <= maxBytes) break;
      if (file.path == keep.path) continue;
      total -= file.lengthSync();
      await file.delete();
    }
  }
}
