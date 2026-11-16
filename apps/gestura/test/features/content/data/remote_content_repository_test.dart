import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/features/content/data/bundled_content_repository.dart';
import 'package:gestura/features/content/data/content_host.dart';
import 'package:gestura/features/content/data/published_catalog.dart';
import 'package:gestura/features/content/data/remote_content_repository.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura_core/gestura_core.dart';

import '../../../helpers/fake_settings_repository.dart';

final Uri _base = Uri.parse('https://gestura-prod-content.web.app/content/');
final String _pack = File(BundledContentRepository.catalogAsset)
    .readAsStringSync()
    .replaceAll('assets/content/demo/media/', 'media/');

const String _index =
    '{"version": 1, "packs": [{"code": "demo", "catalog": "demo/catalog.json"}]}';

class _FakeHost implements ContentHost {
  final Map<String, String> pages = {};
  final List<String> fetched = [];
  Exception? error;

  @override
  Future<String> fetch(Uri uri) async {
    fetched.add(uri.toString());
    if (error case final Exception error) throw error;
    return pages[uri.toString()] ?? (throw const HttpException('404'));
  }
}

class _FakeFiles implements ContentFiles {
  final Map<String, String> files = {};

  @override
  Future<String?> read(String name) async => files[name];

  @override
  Future<void> write(String name, String text) async => files[name] = text;
}

class _FakePublished implements PublishedCatalog {
  Doc? catalog;
  Exception? error;
  String? asked;

  @override
  Future<Doc?> load(String? preferredCode) async {
    asked = preferredCode;
    if (error case final Exception error) throw error;
    return catalog;
  }
}

void main() {
  late _FakeHost host;
  late _FakeFiles files;
  late FakeSettingsRepository settings;
  late _FakePublished published;

  RemoteContentRepository repository() => RemoteContentRepository(
    host,
    files,
    const AppConfig(flavor: Flavor.prod),
    settings,
    published,
  );

  setUp(() {
    host = _FakeHost()
      ..pages['${_base}index.json'] = _index
      ..pages['${_base}demo/catalog.json'] = _pack;
    files = _FakeFiles();
    settings = FakeSettingsRepository();
    published = _FakePublished();
  });

  test('every flavor knows where published content lives', () {
    expect(const AppConfig(flavor: Flavor.prod).contentBase, _base);
    expect(const AppConfig(flavor: Flavor.dev).contentBase, _base);
  });

  test('loads the published catalog with media on the content site', () async {
    final sign = (await repository().sign(const SignId('hello'))).valueOrNull!;

    expect(
      sign.media.video,
      RemoteMedia(Uri.parse('${_base}demo/media/hello.mp4')),
    );
    expect(
      files.files.keys,
      containsAll([
        'gestura-prod-content.web.app_index.json',
        'gestura-prod-content.web.app_demo.json',
      ]),
    );
  });

  test('picks the pack the learner chose', () async {
    host.pages['${_base}index.json'] =
        '{"version": 1, "packs": [{"code": "other", "catalog": "other/c.json"},'
        ' {"code": "demo", "catalog": "demo/catalog.json"}]}';
    settings.stored = const AppSettings(signLanguage: 'demo');

    expect((await repository().pack()).valueOrNull?.code, 'demo');
  });

  test('works offline from the last download', () async {
    await repository().pack();
    host.error = const SocketException('offline');

    expect((await repository().pack()).valueOrNull?.code, 'demo');
  });

  test('reports a first start without a connection', () async {
    host.error = const SocketException('offline');

    expect((await repository().pack()).failureOrNull, const NetworkFailure());
  });

  test('says when nothing is published yet', () async {
    host.pages['${_base}index.json'] = '{"version": 1, "packs": []}';

    expect(
      (await repository().courses()).failureOrNull,
      const NoContentFailure(),
    );
  });

  test('refuses an index it does not understand', () async {
    host.pages['${_base}index.json'] = '{"version": 2}';
    expect((await repository().pack()).failureOrNull, isA<UnexpectedFailure>());

    host.pages['${_base}index.json'] = '{"version": 1, "packs": [{"code": 1}]}';
    expect((await repository().pack()).failureOrNull, isA<UnexpectedFailure>());
  });

  group('content published from the admin dashboard', () {
    setUp(() {
      published.catalog = (jsonDecode(_pack) as Map<String, Object?>)
        ..['pack'] = {
          ...(jsonDecode(_pack) as Map<String, Object?>)['pack']!
              as Map<String, Object?>,
          'code': 'ase',
        };
    });

    test('wins over the content site and keeps media there', () async {
      settings.stored = const AppSettings(signLanguage: 'ase');
      final sign = (await repository().sign(const SignId('hello')))
          .valueOrNull!;

      expect(published.asked, 'ase');
      expect(
        sign.media.video,
        RemoteMedia(Uri.parse('${_base}ase/media/hello.mp4')),
      );
      expect(host.fetched, isEmpty);
      expect(files.files, contains(RemoteContentRepository.publishedName));
    });

    test('works offline from the last copy', () async {
      await repository().pack();
      published.error = Exception('offline');

      expect((await repository().pack()).valueOrNull?.code, 'ase');
    });

    test('falls back to the content site when nothing is cached', () async {
      published.error = Exception('offline');

      expect((await repository().pack()).valueOrNull?.code, 'demo');
    });

    test('still loads a copy without a pack code', () async {
      files.files[RemoteContentRepository.publishedName] = jsonEncode({
        ...published.catalog!,
        'pack': 'broken',
      });
      published.error = Exception('offline');

      expect(
        (await repository().pack()).failureOrNull,
        isA<UnexpectedFailure>(),
      );
    });
  });
}
