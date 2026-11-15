import 'dart:async';
import 'dart:io';

import 'package:gestura/core/media/media_cache.dart';

class FakeMediaCache implements MediaCache {
  new(this.root);

  final String root;
  final List<Uri> requested = [];
  final Set<Uri> stored = {};
  final Set<String> missing = {};
  Completer<void>? hold;

  @override
  Future<bool> has(Uri uri) async => stored.contains(uri);

  @override
  Future<File> file(Uri uri) async {
    requested.add(uri);
    if (hold case final Completer<void> hold) await hold.future;
    final name = uri.pathSegments.last;
    if (missing.contains(name)) throw const HttpException('offline');
    stored.add(uri);
    return File('$root/$name');
  }
}
