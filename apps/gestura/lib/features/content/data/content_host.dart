import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class ContentHost {
  Future<String> fetch(Uri uri);
}

abstract interface class ContentFiles {
  Future<String?> read(String name);

  Future<void> write(String name, String text);
}

@LazySingleton(as: ContentHost)
final class HttpContentHost implements ContentHost {
  const new();

  static const Duration timeout = Duration(seconds: 20);

  @override
  Future<String> fetch(Uri uri) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final response = await (await client.getUrl(uri))
          .close()
          .timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }
}

Future<Directory> contentDirectory() async =>
    Directory('${(await getApplicationSupportDirectory()).path}/content');

@LazySingleton(as: ContentFiles)
final class DiskContentFiles implements ContentFiles {
  new({@ignoreParam this.directory = contentDirectory});

  final Future<Directory> Function() directory;

  @override
  Future<String?> read(String name) async {
    final file = File('${(await directory()).path}/$name');
    return file.existsSync() ? await file.readAsString() : null;
  }

  @override
  Future<void> write(String name, String text) async {
    final folder = await directory();
    await folder.create(recursive: true);
    final partial = File('${folder.path}/$name.part');
    await partial.writeAsString(text, flush: true);
    await partial.rename('${folder.path}/$name');
  }
}
