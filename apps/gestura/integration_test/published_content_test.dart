import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/core/media/media_cache.dart';
import 'package:gestura/features/content/data/content_host.dart';
import 'package:gestura/features/content/data/remote_content_repository.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura_core/gestura_core.dart';
import 'package:integration_test/integration_test.dart';

class _Settings implements SettingsRepository {
  @override
  AppSettings load() => AppSettings.defaults;

  @override
  Future<Result<void>> save(AppSettings settings) async => const Ok(null);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads what is published, or says nothing is published yet', (
    tester,
  ) async {
    final repository = RemoteContentRepository(
      const HttpContentHost(),
      DiskContentFiles(),
      const AppConfig(flavor: Flavor.prod),
      _Settings(),
    );

    final signs = await repository.searchSigns('');
    if (signs case Err(:final failure)) {
      expect(failure, const NoContentFailure());
      return;
    }
    final sign = signs.valueOrNull!.first;
    final video = sign.media.video as RemoteMedia;
    final file = await DiskMediaCache().file(video.uri);

    expect(video.uri.host, 'gestura-prod-content.web.app');
    expect(file.lengthSync(), greaterThan(1000));
    expect(
      await DiskMediaCache().file((sign.media.thumbnail as RemoteMedia).uri),
      isA<File>(),
    );
    expect((await repository.courses()).valueOrNull, isNotEmpty);
  });
}
