import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/firebase/firebase_options.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    group('firebaseOptionsFor on ${platform.name}', () {
      setUp(() => debugDefaultTargetPlatformOverride = platform);

      test('every flavor uses the production project', () {
        expect(
          {
            for (final flavor in Flavor.values)
              firebaseOptionsFor(flavor).projectId,
          },
          {'gestura-prod'},
        );
      });

      test('every flavor is its own Firebase app', () {
        final appIds = Flavor.values.map(
          (flavor) => firebaseOptionsFor(flavor).appId,
        );

        expect(appIds.toSet(), hasLength(Flavor.values.length));
      });
    });
  }

  test('iOS options point at the bundle ID of each flavor', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(
      {
        for (final flavor in Flavor.values)
          flavor: firebaseOptionsFor(flavor).iosBundleId,
      },
      {
        Flavor.dev: 'app.gestura.com.dev',
        Flavor.staging: 'app.gestura.com.stg',
        Flavor.prod: 'app.gestura.com',
      },
    );
  });
}
