import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/data/content_host.dart';
import 'package:gestura/features/content/domain/sign.dart';

void main() {
  late HttpServer server;
  late Directory folder;

  setUp(() async {
    HttpOverrides.global = null;
    folder = await Directory.systemTemp.createTemp('gestura_content');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((request) async {
        if (request.uri.path == '/index.json') {
          request.response.write('{"version": 1}');
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });
  });

  tearDown(() async {
    await server.close(force: true);
    await folder.delete(recursive: true);
  });

  Uri uri(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');

  test('reads text from the content site', () async {
    expect(
      await const HttpContentHost().fetch(uri('/index.json')),
      '{"version": 1}',
    );
  });

  test('treats a missing page as an error', () async {
    await expectLater(
      const HttpContentHost().fetch(uri('/nothing.json')),
      throwsA(isA<HttpException>()),
    );
  });

  test('keeps downloaded text on the device', () async {
    final files = DiskContentFiles(directory: () async => folder);

    expect(await files.read('index.json'), isNull);
    await files.write('index.json', 'saved');
    expect(await files.read('index.json'), 'saved');
  });

  test('uses the app support folder by default', () {
    expect(DiskContentFiles().directory, contentDirectory);
  });

  test('media references compare by value', () {
    const asset = AssetMedia('a.mp4');
    final remote = RemoteMedia(Uri.parse('https://x/a.mp4'));

    expect(asset, AssetMedia('a.mp4'.substring(0)));
    expect(asset.hashCode, const AssetMedia('a.mp4').hashCode);
    expect(asset, isNot(const AssetMedia('b.mp4')));
    expect(asset.toString(), 'AssetMedia(a.mp4)');
    expect(remote, RemoteMedia(Uri.parse('https://x/a.mp4')));
    expect(remote.hashCode, RemoteMedia(Uri.parse('https://x/a.mp4')).hashCode);
    expect(remote, isNot(asset));
    expect(remote.toString(), 'RemoteMedia(https://x/a.mp4)');
  });
}
