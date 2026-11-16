import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:gestura/config/app_config.dart';
import 'package:gestura/features/content/data/catalog_content_repository.dart';
import 'package:gestura/features/content/data/content_catalog_parser.dart';
import 'package:gestura/features/content/data/content_host.dart';
import 'package:gestura/features/content/data/published_catalog.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:injectable/injectable.dart';

final class NothingPublished implements Exception {
  const new();
}

typedef PublishedPack = ({String code, String catalog});

List<PublishedPack> packsOf(String index) => switch (jsonDecode(index)) {
  {'version': 1, 'packs': final List<Object?> packs} => [
    for (final pack in packs)
      switch (pack) {
        {'code': final String code, 'catalog': final String catalog} => (
          code: code,
          catalog: catalog,
        ),
        _ => throw FormatException('Invalid pack entry', pack),
      },
  ],
  final Object? other => throw FormatException('Invalid content index', other),
};

@LazySingleton(as: ContentRepository, env: ['prod'])
final class RemoteContentRepository extends CatalogContentRepository {
  new(this._host, this._files, this._config, this._settings, this._published);

  static const String indexName = 'index.json';
  static const String publishedName = 'published_catalog.json';

  final ContentHost _host;
  final ContentFiles _files;
  final AppConfig _config;
  final SettingsRepository _settings;
  final PublishedCatalog _published;

  @override
  Failure failureOf(Object error) => switch (error) {
    SocketException() ||
    HttpException() ||
    TimeoutException() => const NetworkFailure(),
    NothingPublished() => const NoContentFailure(),
    _ => super.failureOf(error),
  };

  Future<String> _text(Uri uri, String cacheName) async {
    try {
      final text = await _host.fetch(uri);
      await _files.write(cacheName, text);
      return text;
    } on Object {
      final cached = await _files.read(cacheName);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<String?> _publishedText(String? chosen) async {
    try {
      final catalog = await _published.load(chosen);
      if (catalog == null) return null;
      final text = jsonEncode(catalog);
      await _files.write(publishedName, text);
      return text;
    } on Object {
      return await _files.read(publishedName);
    }
  }

  @override
  Future<ContentCatalog> loadCatalog() async {
    final base = _config.contentBase;
    final chosen = _settings.load().signLanguage;
    final published = await _publishedText(chosen);
    if (published != null) {
      final code = switch (jsonDecode(published)) {
        {'pack': {'code': final String code}} => code,
        _ => '',
      };
      final packBase = base.resolve('$code/');
      return await Isolate.run(
        () => parseContentCatalog(
          published,
          media: (path) => RemoteMedia(packBase.resolve(path)),
        ),
      );
    }
    final packs = packsOf(
      await _text(base.resolve(indexName), '${base.host}_$indexName'),
    );
    if (packs.isEmpty) throw const NothingPublished();
    final pack = packs.firstWhere(
      (pack) => pack.code == chosen,
      orElse: () => packs.first,
    );
    final catalogUri = base.resolve(pack.catalog);
    final source = await _text(catalogUri, '${base.host}_${pack.code}.json');
    return await Isolate.run(
      () => parseContentCatalog(
        source,
        media: (path) => RemoteMedia(catalogUri.resolve(path)),
      ),
    );
  }
}
