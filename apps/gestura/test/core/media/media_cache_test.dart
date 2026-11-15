import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/media/media_cache.dart';

void main() {
  late HttpServer server;
  late Directory folder;
  var requests = 0;

  setUp(() async {
    requests = 0;
    HttpOverrides.global = null;
    folder = await Directory.systemTemp.createTemp('gestura_media');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((request) async {
        requests++;
        if (request.uri.path.endsWith('missing.mp4')) {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          request.response.add(List.filled(100, 7));
        }
        await request.response.close();
      });
  });

  tearDown(() async {
    await server.close(force: true);
    await folder.delete(recursive: true);
  });

  Uri uri(String name) => Uri.parse('http://127.0.0.1:${server.port}/m/$name');

  DiskMediaCache cache({int maxBytes = 1000}) =>
      DiskMediaCache(directory: () async => folder, maxBytes: maxBytes);

  test('downloads a file once and serves it from the device after', () async {
    final media = cache();

    final first = await media.file(uri('a.mp4'));
    final again = await media.file(uri('a.mp4'));

    expect(first.lengthSync(), 100);
    expect(again.path, first.path);
    expect(requests, 1);
    expect(await media.has(uri('a.mp4')), isTrue);
    expect(await media.has(uri('b.mp4')), isFalse);
  });

  test('shares one download between callers asking at once', () async {
    final media = cache();

    await Future.wait([media.file(uri('a.mp4')), media.file(uri('a.mp4'))]);

    expect(requests, 1);
  });

  test('drops the least recently used files over the limit', () async {
    final media = cache(maxBytes: 250);

    final a = await media.file(uri('a.mp4'));
    await a.setLastModified(DateTime(2020));
    await media.file(uri('b.mp4'));
    await media.file(uri('c.mp4'));

    expect(a.existsSync(), isFalse);
    expect(folder.listSync(), hasLength(2));
  });

  test('keeps nothing from a failed download', () async {
    await expectLater(
      cache().file(uri('missing.mp4')),
      throwsA(isA<HttpException>()),
    );
    expect(folder.listSync().whereType<File>(), isEmpty);
  });

  test('names files after their address', () {
    expect(
      DiskMediaCache.nameOf(Uri.parse('https://x.web.app/content/a b.mp4')),
      'x.web.app_content_a_20b.mp4',
    );
  });
}
