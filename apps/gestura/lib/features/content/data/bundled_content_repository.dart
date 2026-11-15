import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:gestura/features/content/data/catalog_content_repository.dart';
import 'package:gestura/features/content/data/content_catalog_parser.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/content_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ContentRepository, env: ['dev', 'staging'])
final class BundledContentRepository extends CatalogContentRepository {
  new(this._bundle);

  static const String catalogAsset = 'assets/content/demo/pack.json';

  final AssetBundle _bundle;

  @override
  Future<ContentCatalog> loadCatalog() async {
    final source = await _bundle.loadString(catalogAsset);
    return await Isolate.run(() => parseContentCatalog(source));
  }
}
